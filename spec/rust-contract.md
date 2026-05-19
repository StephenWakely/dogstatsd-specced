# Rust Implementation Contract: DogStatsD Go Client Port

## 1. Source of Truth

This document is the implementation handoff contract for porting the datadog-go DogStatsD client library to Rust. All design decisions are grounded in:

- **Allium Behavioral Spec:** `/spec/allium.md` — domain-level intent and semantic requirements (not implementation).
- **TLA+ Models:** `/spec/tla/*.tla` — checked formal state-machine models (S1–S5 subsystems).
- **TLC Results:** `/spec/check-results.md` — model-checking outcomes and bounds.
- **Allium Quality Gate:** All Allium specs passed domain-level review before TLA+ translation.

**Key principle:** If an ambiguity arises during implementation, consult the Allium spec first (intent layer), then the TLA+ model (formal semantics), then this contract (Rust mapping).

---

## 2. Behavioral Summary

The DogStatsD client is a high-throughput metrics aggregation and transport library. It is used to send metrics (gauges, counts, histograms, distributions, timing data, sets) to a Datadog agent with minimal latency and blocking.

### Core Responsibilities

1. **Client Lifecycle:** Open on creation, close on explicit Close(). Reject metric submissions after close.
2. **Aggregation:** Accumulate metrics by context (name+tags), with type-specific semantics:
   - Counts: sum values
   - Gauges: store last value (overwrite)
   - Sets: maintain unique values
   - Buffered (histogram/distribution/timing): reservoir sample
3. **Batching:** Serialize metrics into buffers (UDP-sized, ~1432 bytes). Transactional writes: either fully serialize or fully rollback.
4. **Async Sending:** Queue buffers to a sender goroutine that writes to UDP, UDS, or Windows Named Pipe. No retries; fire-and-forget.
5. **Init Singletons:** Detect container ID and external environment exactly once at startup; immutable thereafter.

### Non-Goals

- Persistence or durability: metrics lost on process exit
- Retry logic: dropped metrics are accepted
- Timing precision: flush intervals are best-effort
- Backwards compatibility hacks: clean redesign for Rust

---

## 3. State Model: TLA+ Variables → Rust Representation

| TLA+ Variable | Type/Domain | Rust Representation | Ownership/Sync | Notes |
|---|---|---|---|---|
| **S1: Client** | | | | |
| `clientState` | "Open" \| "Closed" | `AtomicBool closed` or `enum ClientState` | `Arc<AtomicBool>` or `Arc<Mutex<>>` | Immutable after close; read-frequent |
| `metricsSubmitted` | Set<Metric> | Queue/channel to aggregator | Channel or MPSC | Buffered user submissions |
| `metricsInFlight` | Set<Metric> | Internal: metrics in aggregation/send pipeline | Implicit in worker queues | Derived from aggregator + sender state |
| **S2: Aggregator** | | | | |
| `aggregatorState` | "Running" \| "Stopped" | `bool running` or `enum AggState` | `Arc<AtomicBool>` or `Arc<Mutex<>>` | Stopped on client close |
| `countShards[shard][ctx]` | Int64 | `Arc<Vec<RwMutex<HashMap<MetricContext, i64>>>>` | Per-shard RwMutex over HashMap | One lock per shard; hash by FNV-1a(context) % shardCount |
| `gaugeShards[shard][ctx]` | Float64 | `Arc<Vec<RwMutex<HashMap<MetricContext, AtomicU64>>>>` | Per-shard RwMutex; gauge values as atomic u64 bits | Store as u64 (IEEE 754 bit pattern) for atomicity |
| `setShards[shard][ctx]` | Set<String> | `Arc<Vec<RwMutex<HashMap<MetricContext, HashSet<String>>>>>` | Per-shard RwMutex | Sets deduplicated by HashSet |
| `bufferedCount[ctx]` | Int64 | `Arc<RwMutex<HashMap<MetricContext, ReservoirState>>>` | Shared RwMutex over contexts | Tracks samples and sample count for rate |
| `flushOccurred` | bool | Implicit in periodic tick event | Tokio timer or OS signal | Flush triggered by interval or explicit call |
| **S3: Worker/Buffer** | | | | |
| `bufferLen` | 0..MaxBufferSize | `usize len` in `struct Buffer` | Stack or heap-allocated buffer | Part of per-worker or thread-local state |
| `elementCount` | 0..MaxElements | `usize element_count` in `struct Buffer` | In struct Buffer | Track metrics per buffer |
| `poolSize` | 0..PoolCapacity | Channel capacity or `Arc<Semaphore>` | Implicit in buffer pool channel | MPSC channel of borrowed buffers |
| `transactionFailed` | bool | Implicit: Write failure → error returned | Result enum | Rollback on failed write |
| **S4: Sender** | | | | |
| `senderState` | "Running" \| "Stopped" | `bool running` or `enum SenderState` | `Arc<AtomicBool>` | Stopped on client close |
| `queueLen` | 0..SenderQueueSize | Implicit in channel len | MPSC channel size | Channel length ≤ SenderQueueSize |
| `transportOpen` | bool | `Arc<Mutex<dyn Transport>>` with state | Arc<Mutex> for Write/Close | Can't reopen once closed |
| `payloadsSent` | Int64 | `Arc<AtomicU64>` | Atomic for lock-free reads | Telemetry counter |
| `payloadsDropped` | Int64 | `Arc<AtomicU64>` | Atomic | Telemetry: queue full + write failures |
| `bytesSent` | Int64 | `Arc<AtomicU64>` | Atomic | Telemetry |
| `bytesDropped` | Int64 | `Arc<AtomicU64>` | Atomic | Telemetry |
| **S5: Init Singletons** | | | | |
| `containerIDState` | "Unset" \| "Set" | `once_cell::sync::Lazy<String>` or `sync.Once` | `OnceLock<String>` or `Arc<Once>` | Read-only after Set |
| `containerIDValue` | String | Stored in OnceLock | `OnceLock<String>` | Immutable; only read after Set |
| `externalEnvState` | "Unset" \| "Set" | `atomic::Value<String>` or `OnceLock` | `Arc<OnceLock<String>>` | Immutable; atomic read after Set |
| `externalEnvValue` | String | Stored in OnceLock | `OnceLock<String>` | Immutable after Set |

### Notes on Rust Representation

- **Arc<Mutex<>>** for shared mutable state that is occasionally written.
- **Arc<RwMutex<>>** for shared state with many readers, few writers (aggregator shards).
- **Arc<AtomicXxx>** for high-frequency counters and boolean flags (telemetry, closed state).
- **OnceLock<T>** for exactly-once initialization (container ID, external env).
- **MPSC channel** for bounded queues (worker input, sender output).
- **Per-shard locks** in aggregator to reduce contention on write-heavy metrics.

---

## 4. Transition Table: TLA+ Actions → Rust Functions

| TLA+ Action | Rust Function/Method | Preconditions (guard) | State Update | Postcondition |
|---|---|---|---|---|
| **S1: Client Lifecycle** | | | | |
| `Init` | `Client::new(addr, options)` | addr valid, transport supported | Initialize all state; clientState = Open, aggregatorState = Running, senderState = Running | Client ready for metrics; all goroutines spawned |
| `SubmitMetric(m)` | `client.gauge/count/histogram/etc(name, value, tags, rate)` | clientState = Open, serializable | Queue metric to aggregator or direct send | Metric queued; no blocking on caller |
| `ClientFlush` | `client.flush()` | clientState = Open | Flush all buffers; wait for sender to drain | All pending metrics sent before return |
| `ClientClose` | `client.close()` | clientState = Open | Set clientState = Closed; signal stop to aggregator + sender; drain queues | All goroutines exit cleanly; no further operations allowed |
| `QueryIsClosed` | `client.is_closed()` | any | None (observational) | Return true iff clientState = Closed; no side effects |
| `SubmitMetricOnClosed` | (implicit in metric methods) | clientState = Closed | Return ErrNoClient or error; no state change | Caller receives error; client state unchanged |
| **S2: Aggregator** | | | | |
| `SampleCount(ctx, val)` | `aggregator.sample_count(ctx, val, rate)` | aggregatorState = Running, rate ∈ (0, 1] | Atomically add val to countShards[shard(ctx)][ctx] | Count incremented; atomic per shard |
| `SampleGauge(ctx, val)` | `aggregator.sample_gauge(ctx, val)` | aggregatorState = Running | Store val to gaugeShards[shard(ctx)][ctx] (overwrite) | Gauge stores last value |
| `SampleSet(ctx, val)` | `aggregator.sample_set(ctx, val)` | aggregatorState = Running | Add val to setShards[shard(ctx)][ctx] | Set now contains val |
| `SampleBuffered(ctx, val)` | `aggregator.sample_buffered(ctx, val, rate)` | aggregatorState = Running, rate ∈ (0, 1] | Apply reservoir sampling to bufferedCount[ctx]; increment totalSamples | Sample kept or dropped; stats updated |
| `FlushAggregator` | (triggered by timer or explicit flush) | aggregatorState = Running, interval elapsed | For each context: emit serialized metric, reset accumulators | All accumulated metrics queued to worker |
| `StopAggregator` | (called by client.close()) | aggregatorState = Running | Set aggregatorState = Stopped; reset all accumulators | No further samples accepted; pending metrics discarded |
| **S3: Worker/Buffer** | | | | |
| `WriteMetric(buffer, metric)` | `buffer.write_metric(metric)` or `serializer.write(metric, buf)` | buffer has room: bufferLen + metric_len ≤ MaxBufferSize, elementCount < MaxElements | Serialize metric to wire format; append to buffer | Metric in buffer; length updated |
| `WriteMetricOverflow` | (implicit in WriteMetric) | buffer full (bufferLen + metric_len > MaxBufferSize) | Rollback; restore bufferLen to pre-write state | Buffer unchanged; error returned |
| `FlushBuffer` | `buffer_pool.flush_buffer(buf)` or worker loop | bufferLen > 0 | Send buffer to sender queue; reset buffer to empty | Buffer transmitted; ready for reuse |
| `BorrowBuffer` | `buffer_pool.borrow()` or `channel.recv()` | pool not empty or allocate new | Decrement poolSize (or allocate) | New buffer available; never blocks |
| `ReturnBuffer` | `buffer_pool.return_buffer(buf)` | buffer empty, pool has room | Increment poolSize; buffer back in pool | Buffer available for reuse |
| **S4: Sender** | | | | |
| `EnqueueBuffer` | `sender.send_buffer(buf)` | senderState = Running | Non-blocking send to queue; drop if full (increment telemetry) | Buffer queued or dropped |
| `SendFromQueue` | (sendLoop goroutine) | senderState = Running, queue not empty | Dequeue buffer; call transport.write(buf.bytes); update telemetry | Buffer sent or write-error recorded |
| `HandleWriteError` | (implicit in SendFromQueue) | transport.write() fails | Increment payloadsDropped + bytesDropped; log error | Error recorded; sendLoop continues |
| `FlushSignal` | (triggered by client.flush()) | (internal) | Wake sendLoop; ensure all queued buffers sent | All pending buffers sent before client.flush() returns |
| `StopSender` | (called by client.close()) | senderState = Running | Close stop channel; sendLoop drains queue, calls transport.close() | senderState = Stopped; all resources released |
| **S5: Init Singletons** | | | | |
| `InitContainerID` | `get_container_id()` or explicit init | containerIDState = Unset | Run detection; store in containerIDValue; set containerIDState = Set | containerID immutable thereafter |
| `InitExternalEnv` | (called at client creation) | externalEnvState = Unset | Read DD_EXTERNAL_ENV; sanitize; store in externalEnvValue; set state = Set | externalEnv immutable thereafter |
| `ReadContainerID` | `get_container_id()` | any | If Unset, trigger InitContainerID first | Return containerIDValue (same value on every read) |
| `ReadExternalEnv` | (called during metric serialization) | any | If Unset, return ""; if Set, return value | Return consistent value; lock-free after Set |

### Special Cases

- **Metric submission variants:** Each metric type (gauge, count, histogram, etc.) is a separate public method but all map to the same underlying SampleCount/SampleGauge/SampleBuffered actions with type-specific parameters.
- **Rate sampling:** Applied client-side before serialization; rates < 1.0 are encoded in wire format as `|@<rate>`.
- **Cardinality:** Tag cardinality level (none, low, orchestrator, high) is appended to each metric if set globally.

---

## 5. Invariants (Must Hold After Every Public Operation)

| Invariant | Formal Statement | Rust Check | Purpose |
|---|---|---|---|
| **S1: Client Lifecycle** | | | |
| NoMetricAfterClose | `clientState = Closed => metricsSubmitted = {}` | Metric methods return ErrNoClient if `is_closed()` | Prevent silent loss of metrics on closed client |
| ClosedIsStable | `clientState = Closed => []clientState = Closed` | close() is idempotent; state transitions are one-way | Once closed, client is permanently closed |
| NoPanicOnClosed | Operations on closed client return error, never panic | All metric methods check `is_closed()` before proceeding | Safety: no panics on user error |
| **S2: Aggregator** | | | |
| NoNewSamplesAfterStop | `aggregatorState = Stopped => no new counts/gauges/sets/buffered` | aggregator.sample_*() checks `running` flag before proceeding | Prevents stale metrics after close |
| CountsNonNegative | `countShards[s][ctx] >= 0` (always by += operator) | Counts only incremented, never decremented | Counts represent accumulated values |
| GaugeLWW | Gauge stores last value, never accumulates | Gauge writes use assign (=), not increment | Last submitted value is authoritative |
| SetsDeduplicated | Sets automatically deduplicate | Use HashSet, never append duplicates | Set cardinality is accurate |
| **S3: Worker/Buffer** | | | |
| NoBufferOverflow | `bufferLen <= MaxBufferSize` always | WriteMetric checks `bufferLen + metric_len <= MaxBufferSize` before appending | Prevent buffer overflow |
| NoElementOverflow | `elementCount <= MaxBufferElements` always | WriteMetric checks `elementCount < MaxElements` before incrementing | Prevent exceeding metric count limit |
| NoPoolOverflow | `poolSize <= BufferPoolCapacity` always | ReturnBuffer drops if pool full; channel capacity enforced | Pool size bounded |
| TransactionalWrites | Each metric fully written or fully rolled back (no partial) | WriteMetric validates before modifying buffer; on error, restore original state | Avoid corrupted metrics in transport |
| **S4: Sender** | | | |
| NoQueueOverflow | `queueLen <= SenderQueueSize` always | EnqueueBuffer non-blocking; drop if queue full (check channel len) | Sender not a bottleneck |
| NoRetries | Each buffer written at most once (fire-and-forget) | SendFromQueue dequeues, writes, does not retry on error | Expected behavior: transient losses acceptable |
| TelemetryConsistent | Counters increment monotonically; never decrease | Use AtomicU64 increments; telemetry is append-only | Telemetry reflects actual behavior |
| TransportClosedOnStop | `senderState = Stopped => transportOpen = False` | close() waits for sendLoop to exit and call transport.close() | All resources cleanly released |
| **S5: Init Singletons** | | | |
| NoContainerIDChange | `containerIDState = Set => containerIDValue never changes` | OnceLock<String> prevents re-write; read-only after Set | Container ID stable for lifetime of process |
| NoExternalEnvChange | `externalEnvState = Set => externalEnvValue never changes` | OnceLock<String> prevents re-write | External env stable for lifetime of process |
| ReadConsistency | Reads always return same value once Set | OnceLock<T> guarantees consistency | All metrics see same container/env |
| **Cross-Subsystem** | | | |
| ClientOpenInvariant | While clientState = Open, metrics flow through pipeline or are dropped | Aggregator running, sender running; metrics enqueued | Metrics are not silently lost |
| AggregatorStopsOnClose | If clientState = Closed, aggregatorState = Stopped | close() sets aggregatorState = Stopped before returning | No further aggregation after close |
| SenderStopsOnClose | If clientState = Closed, senderState = Stopped | close() drains queues and calls StopSender | Clean shutdown |

---

## 6. Error Semantics

### Error Types

Errors are represented as an enum or Result<T, Error>:

```rust
#[derive(Debug, Clone)]
pub enum Error {
    NoClient,                    // client is nil or closed
    InputChannelFull,           // (if channel mode) worker queue overflow
    SenderChannelFull,          // sender queue overflow
    MessageTooLong,             // single metric > MaxBytesPerPayload
    TransportError(String),     // transport I/O error (logged, not panicked)
    ContainerIDError(String),   // container detection failed (logged, optional)
    ExternalEnvError(String),   // env var read failed (logged, optional)
}
```

### Error Handling Contract

1. **Operations on closed client** → return `Error::NoClient`; do not modify state.
2. **Queue full** → increment telemetry; return error if error handler is configured; otherwise silent drop.
3. **Transport write failure** → increment telemetry; continue (no retries); do not close transport unless explicitly signaled.
4. **Metric too large** → return error; do not serialize; caller must split or reduce cardinality.
5. **Container ID detection failure** → log warning; use empty string or user-provided ID; do not panic.
6. **External env read failure** → log warning; use empty string; do not panic.

### No-Panic Policy

Public functions and methods must **never panic** on user input or transient errors. Panic only if:

- Internal invariant is violated (e.g., shard index out of bounds; use debug_assert for checks)
- Memory allocation fails (accept OOM as unrecoverable)
- Mutex is poisoned (log and exit gracefully, not panic)

Example:

```rust
pub fn gauge(&self, name: &str, value: f64, tags: &[&str], rate: f64) -> Result<(), Error> {
    if self.is_closed() {
        return Err(Error::NoClient);
    }
    // ...
}

#[test]
fn test_gauge_on_closed_client_returns_error() {
    let client = Client::new("localhost:8125", Default::default()).unwrap();
    client.close().unwrap();
    assert!(client.gauge("test.gauge", 1.0, &[], 1.0).is_err());
}
```

---

## 7. Concurrency Model

### Threading Model

- **Single user thread** per client: the public API is thread-safe but assumes single-threaded user calls per client instance.
- **Multiple worker goroutines** (configurable, default 32): serialize metrics into buffers concurrently. Workers use mutex mode (lock-based) or channel mode (message-passing); modeled as sequential interleaving in TLA+.
- **One aggregator goroutine**: runs periodic flush ticker; accumulates metrics with per-shard locks.
- **One sender goroutine**: dequeues buffers and writes to transport.
- **Main thread** (implicit): user calls, close() waits for all goroutines to exit.

### Synchronization Primitives

| Component | Primitive | Reason |
|-----------|-----------|--------|
| `closed` flag | `AtomicBool` | High-frequency read in every metric method |
| Aggregator shards | `Arc<Vec<RwMutex<HashMap>>>` | Many readers (metrics), few writers (flush) |
| Sender queue | MPSC channel | Unbounded into buffer; receiver is single sendLoop goroutine |
| Telemetry counters | `Arc<AtomicU64>` | Lock-free increments during high throughput |
| Container ID, External Env | `OnceLock<String>` | Exactly-once initialization; read-only thereafter |
| Buffer pool | MPSC channel of buffers | Non-blocking borrow/return; excess discarded |

### Data Race Prevention

- All shared state is guarded by appropriate synchronization (locks, atomics, channels).
- No raw pointers or unsafe code except in transport I/O (which must be carefully audited).
- Worker threads must not hold locks across I/O operations.
- Flush() is blocking; it waits for all pending buffers to be sent before returning. Implementation: use a sync primitive (Barrier or channel) to coordinate.

### Deadlock Prevention

- Locks are always acquired in a consistent order (shard index → context lock if multiple shards).
- No circular wait: worker threads never call back into aggregator or sender.
- Sender thread never blocks on user input (non-blocking queue).
- Aggregator timer-based flush is independent of user calls (different code paths).

---

## 8. Persistence Model

### No Persistence

The Rust implementation is **in-memory only**. There is no durability guarantee:

- Metrics are lost on process exit.
- No write-ahead log or journal.
- No crash recovery.
- No idempotent retry logic (fire-and-forget).

### Implications for Rust Design

- No database connections or file handles.
- No state serialization for restart.
- No replay log for "what metrics were sent?"
- Telemetry counters (payloadsSent, etc.) are ephemeral and reset on restart.

---

## 9. Test Obligations

### Mandatory Unit Tests (By Subsystem)

#### S1: Client Lifecycle

```rust
#[test]
fn test_new_client_is_open() { ... }

#[test]
fn test_gauge_on_open_client_succeeds() { ... }

#[test]
fn test_gauge_on_closed_client_returns_error() { ... }

#[test]
fn test_close_idempotent() { ... }

#[test]
fn test_is_closed_reflects_state() { ... }

#[test]
fn test_flush_on_open_sends_pending() { ... }

#[test]
fn test_flush_on_closed_client_returns_error() { ... }

#[test]
fn test_no_panic_on_invalid_input() { ... }
```

#### S2: Aggregator

```rust
#[test]
fn test_count_accumulates() { ... }

#[test]
fn test_gauge_overwrites() { ... }

#[test]
fn test_set_deduplicates() { ... }

#[test]
fn test_flush_emits_one_metric_per_context() { ... }

#[test]
fn test_stop_prevents_further_samples() { ... }

#[test]
fn test_sharding_is_deterministic() { ... }
```

#### S3: Worker/Buffer

```rust
#[test]
fn test_write_within_buffer_capacity() { ... }

#[test]
fn test_write_overflow_rolls_back() { ... }

#[test]
fn test_flush_buffer_sends_to_sender() { ... }

#[test]
fn test_pool_borrow_never_blocks() { ... }

#[test]
fn test_pool_return_respects_capacity() { ... }

#[test]
fn test_transactional_writes_all_or_nothing() { ... }
```

#### S4: Sender

```rust
#[test]
fn test_enqueue_succeeds_if_queue_open() { ... }

#[test]
fn test_enqueue_drops_if_queue_full() { ... }

#[test]
fn test_telemetry_increments_on_drop() { ... }

#[test]
fn test_write_error_does_not_retry() { ... }

#[test]
fn test_stop_drains_queue() { ... }

#[test]
fn test_transport_close_called_on_stop() { ... }
```

#### S5: Init Singletons

```rust
#[test]
fn test_container_id_initialized_once() { ... }

#[test]
fn test_container_id_immutable_after_set() { ... }

#[test]
fn test_external_env_initialized_once() { ... }

#[test]
fn test_read_consistency_after_init() { ... }

#[test]
fn test_double_init_idempotent() { ... }
```

### Negative Tests (Forbidden Behaviors)

```rust
#[test]
fn test_cannot_submit_metric_after_close() { ... }

#[test]
fn test_cannot_sample_after_aggregator_stop() { ... }

#[test]
fn test_buffer_never_overflows() { ... }

#[test]
fn test_queue_never_overflows() { ... }

#[test]
fn test_container_id_never_changes() { ... }
```

### Property Tests

Use `proptest` or quickcheck:

```rust
proptest! {
    #[test]
    fn prop_random_metrics_do_not_panic(metrics in metric_sequence()) {
        let client = Client::new("localhost:8125", Default::default()).unwrap();
        for m in metrics {
            let _ = client.gauge(&m.name, m.value, &m.tags, 1.0);
        }
        let _ = client.close();
    }

    #[test]
    fn prop_invariants_hold_after_operations(ops in action_sequence()) {
        let mut state = ClientState::new_for_test();
        for op in ops {
            state.apply(op).ok();
            assert!(state.check_invariants());
        }
    }
}
```

### Regression Tests from TLA+ Counterexamples

For each counterexample found by TLC (after running), add a regression test:

```rust
#[test]
fn regression_client_close_stops_aggregator() {
    let client = Client::new("localhost:8125", Default::default()).unwrap();
    client.gauge("test.gauge", 1.0, &[], 1.0).unwrap();
    client.close().unwrap();
    // Verify aggregator is stopped: no further flushes
}
```

### Optional Kani Harnesses

For bounded state checking of critical functions:

```rust
#[cfg(kani)]
#[kani::proof]
fn verify_buffer_never_overflows() {
    let mut buf = Buffer::new(100, 10);
    for i in 0..kani::any() {
        let size = kani::any::<u8>() as usize;
        let _ = buf.write_metric(size);
    }
    assert!(buf.len() <= 100);
}
```

### Test Coverage Goals

- **Unit test per action:** Every TLA+ action has a corresponding unit test.
- **Negative test per forbidden behavior:** Every invariant has a test that verifies its violation is caught.
- **Property test for long-running sequences:** Random action sequences do not violate invariants.
- **Regression test per counterexample:** Every TLC counterexample is a test case.
- **Integration test:** Full client lifecycle (new, multiple metrics, close) succeeds.

---

## 10. Known Model Limits

### Unchecked Assumptions

1. **Time-based triggers:** Buffer and aggregator flush intervals (100ms, 2s, 10s) are modeled as nondeterministic events, not timed delays. TLC cannot check "buffer is flushed within 100ms." Real-world behavior depends on OS scheduling; tests should use mock timers.

2. **Concurrency details:** Worker and aggregator goroutines are modeled as sequential state transitions. TLC checks safety under any interleaving, but does not verify:
   - Specific race conditions in concurrent data structure operations
   - Ordering of events across goroutines
   - Lock contention or fairness

3. **Metric content:** Wire format serialization is abstracted. The model verifies structural invariants (capacity, transactionality) but does not check:
   - Correct encoding of metric values (e.g., float64 → decimal string)
   - Newline escaping in tags
   - Tag ordering

4. **Transport behavior:** UDP, UDS, and Pipe transports are abstracted as a single Write() call. The model does not simulate:
   - Packet fragmentation or reassembly
   - Latency or jitter
   - Connection drop or timeout
   - OS socket buffer limits

5. **Error propagation:** Error handlers and logging are not modeled. Telemetry counters are the observable record of what happened; user-supplied error handlers are assumed to not modify client state.

6. **Platform-specific details:**
   - Container ID detection (Linux cgroup/mountinfo parsing) is abstracted to a function that returns a value from a finite set.
   - External env (DD_EXTERNAL_ENV) is assumed to be a finite string.
   - Platform-specific transports (UDS on Unix, Pipe on Windows) are unified in the model.

### Finite Model Bounds

| Constant | Model Bound | Real-World Bound | Rationale |
|----------|---|---|---|
| MetricContexts | 2–3 contexts | Unbounded | Model-checking feasibility; real deployments have 100s–1000s |
| AggregatorShards | 1–2 shards | Configured, default 1 | Test both single and multi-shard scenarios |
| MaxCountValue | 10 | Unbounded (i64) | Bounded for state space; tests accumulation logic |
| MaxBufferSize | 100 bytes | 1432 (UDP) or 8192 (UDS) | Smaller for model checking; real implementations use actual UDP MTU |
| SenderQueueSize | 3–5 buffers | Configured, default 512 | Bounded for model; test overflow behavior with small queue |
| ContainerIDValues | 2 | Unbounded | Finite values suffice for testing initialization |
| ExternalEnvValues | 2–3 values | Unbounded | Finite for testing; real env var is a single string |

### Implementation Guidance

When porting to Rust:

1. **Use actual constants** from the Go implementation (e.g., MaxBufferSize = 1432 for UDP) rather than the model bounds.
2. **Test with model-sized constants** in unit tests to verify invariants hold even with small buffers/queues.
3. **Use mock timers** in tests instead of real time.sleep() calls.
4. **Verify concurrency** with thread-safety tools (Clippy unsafe warnings, Miri, Loom for concurrent tests).
5. **Fuzz-test metrics serialization** to check that all valid metric values encode and decode correctly.
6. **Monitor telemetry** in integration tests to verify that counters match expected behavior.

### Debugging Guide

If the Rust implementation diverges from the TLA+ model:

1. **Check preconditions:** Does the Rust guard condition match the TLA+ guard? (e.g., `clientState = "Open"` → `!is_closed()`)
2. **Check state updates:** Are all variables updated that appear in the TLA+ action? (Look for missing UNCHANGED.)
3. **Check thread safety:** Are mutable shared variables protected by appropriate locks?
4. **Check initialization:** Does Rust Init match TLA+ Init?
5. **Check termination:** Does Rust handle client close the same way TLA+ does (stop all subsystems)?
6. **Re-run TLC with wider bounds** if the Rust behavior seems correct but TLC was checking a too-small model.

---

## Summary

This contract specifies a high-fidelity Rust port of the datadog-go DogStatsD client with behavioral guarantees derived from Allium intent and TLA+ formal verification. The Rust implementation must:

1. Enforce client lifecycle (open/closed) with no silent failures.
2. Aggregate metrics with type-specific semantics (counts, gauges, sets).
3. Batch metrics into transactional buffers with capacity invariants.
4. Asynchronously send buffers to transport with fire-and-forget semantics.
5. Initialize container ID and external environment exactly once, immutably.
6. Return errors (not panic) on user input violations.
7. Use thread-safe synchronization (Arc, Mutex, RwMutex, Atomic, OnceLock).
8. Provide comprehensive tests covering all actions, invariants, and counterexamples.

See `spec/allium.md` and `spec/tla/*.tla` for the source specifications.

