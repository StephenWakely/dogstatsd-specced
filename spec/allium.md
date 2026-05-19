# Allium Behavioral Spec: DogStatsD Go Client (Complete Port)

This is the complete Allium specification for the DogStatsD Go client library, combined from six subsystems: client lifecycle, aggregation, worker/buffer, sender/transport, init singletons, and wire format/config.

---

## Part 1: Client Lifecycle (S1)

### Intent
A DogStatsD client must enforce a clear lifecycle: creation, metric submission, and graceful closure. Clients provide a safety contract: operations on a closed client fail explicitly rather than panic or silently lose data.

### Entities
- **Client**: The primary user-facing object. Identity is its creation handle.
- **Metric**: gauge, count, set, histogram, distribution, timing, event, service check.
- **TransportMode**: UDP, UDS, Windows Named Pipe.
- **State**: open or closed.

### States
- `Open`: Client has been created and not yet closed. Metric submission is allowed.
- `Closed`: Client has been explicitly closed. Metric submission is forbidden.

### Rules (S1)
- **R1.1**: Create Client: User calls `New(address, ...options)` → Client.created with state = Open
- **R1.2**: Submit Metric: Client.state = Open → Metric.submitted (queued for processing)
- **R1.3**: Flush: Client.state = Open → All buffered metrics immediately sent
- **R1.4**: Close Client: Client.state = Open → state = Closed, all pending metrics flushed, goroutines stopped
- **R1.5**: Operations on Closed Client: Client.state = Closed → returns error (ErrNoClient)
- **R1.6**: IsClosed Query: returns true iff Client.state = Closed (observational, no side effects)

---

## Part 2: Client-Side Aggregator (S2)

### Intent
The aggregator reduces the number of metrics sent to the agent by accumulating values over time. Each metric type has different semantics: counts accumulate; gauges are last-write-wins; sets are deduplicated; buffered metrics use reservoir sampling.

### Entities
- **Aggregator**: Owns sharded count/gauge/set maps and buffered metric contexts.
- **Metric Context**: Name + tags (key). Each context stores one accumulated metric.
- **Shard**: One of N RWMutex-protected hash maps, distributing by FNV-1a hash of name+tags.

### States
- `Running`: Aggregator has been started, ticker is active.
- `Stopped`: Aggregator has been stopped, no more flushing.

### Rules (S2)
- **R2.1**: Sample Count: Aggregator.state = Running, rate sampling applied → atomically add value to count[context]
- **R2.2**: Sample Gauge: Aggregator.state = Running → atomically store value (last-write-wins) to gauge[context]
- **R2.3**: Sample Set: Aggregator.state = Running → add value to set[context]
- **R2.4**: Sample Buffered: Aggregator.state = Running, rate sampling applied → apply reservoir sampling to buffered[context]
- **R2.5**: Periodic Flush: Ticker fires → for each context, emit one metric per shard, reset metric state
- **R2.6**: Stop Aggregator: Client calls Close() → Aggregator.state = Stopped, no further flushes

### Invariants (S2)
- I2.1: After Stop, no new samples are added
- I2.2: Exactly one metric is emitted per context per flush interval
- I2.3: Counts are non-negative (increment only)
- I2.4: Gauges use last-write-wins (no accumulation)
- I2.5: Sets are deduplicated by definition
- I2.6: Buffered metrics track totalSamples atomically for sampling rate calculation

---

## Part 3: Worker and Buffer (S3)

### Intent
Workers maximize throughput by batching metrics into buffers before sending. If a metric would exceed buffer capacity, the buffer is flushed and a new one is started. The pool avoids allocation overhead by reusing buffers.

### Entities
- **Worker**: Serializes metrics into buffers. Can run in mutex mode or channel mode.
- **Buffer**: Byte array with size and element count limits. Transactional writes with rollback.
- **BufferPool**: Channel-based pool of reusable buffers.

### States
- **Buffer.HasRoom**: Additional bytes can be safely appended.
- **Buffer.Full**: No additional bytes without exceeding maxSize.

### Rules (S3)
- **R3.1**: Write Metric to Buffer: Worker.WriteMetric(metric) → serialize to wire format, append to buffer
- **R3.2**: Buffer Rollback on Overflow: Write would exceed maxSize → restore original state (transaction rollback), return errBufferFull
- **R3.3**: Flush Buffer: Buffer is full or flush interval expires → send buffer to sender, borrow fresh buffer from pool
- **R3.4**: Borrow Buffer from Pool: Worker needs new buffer → non-blocking receive from pool, OR allocate new if pool empty
- **R3.5**: Return Buffer to Pool: Buffer is flushed → reset to empty, non-blocking send to pool, OR discard if pool full

### Wire Format Ordering (S3)
Every serialized metric must follow exact order:
1. `name:value|typeSymbol`
2. `|@rate` (if rate < 1)
3. `|#tag1,tag2,...` (if tags present)
4. `|c:containerID` (if set)
5. `|e:externalEnv` (if set)
6. `|card:cardinality` (if set)
7. `\n`

### Invariants (S3)
- I3.1: buffer.len <= buffer.maxSize always (no overflow)
- I3.2: buffer.elementCount <= buffer.maxElements always
- I3.3: Each metric is either fully written or fully rolled back (no partial writes)
- I3.4: Pool size never exceeds poolCapacity (excess returns are discarded)

---

## Part 4: Sender and Transport (S4)

### Intent
The sender decouples workers from network I/O. Metrics are queued and sent asynchronously. If the queue is full, metrics are dropped with telemetry recorded. The sender handles graceful shutdown.

### Entities
- **Sender**: Owns a queue channel and a sendLoop goroutine.
- **Transport**: Abstraction for UDP, UDS, pipe. Implements Write([]byte) and Close().
- **Queue**: Channel of *statsdBuffer.

### States
- `Running`: Sender goroutine is active, queue is live.
- `Stopped`: Sender has been stopped, queue is closed.

### Rules (S4)
- **R4.1**: Create Sender: Client creates sender during New() → queue channel created, sendLoop goroutine spawned, state = Running
- **R4.2**: Enqueue Buffer: Worker calls sender.send(buffer) → non-blocking send to queue, OR drop if queue full (increment telemetry)
- **R4.3**: Send Loop: sendLoop goroutine continuously → receive buffer from queue (blocking), call transport.Write(buffer.bytes)
- **R4.4**: Handle Transport Errors: transport.Write() fails → increment telemetry, continue to next buffer (fire-and-forget, no retries)
- **R4.5**: Flush Signal: User calls client.Flush() → signal to sendLoop to cause transport flush, block until complete
- **R4.6**: Stop Sender: Client calls Close() → close stop channel, sendLoop exits and drains queue, transport.Close() called

### Transport Implementations
- **UDP**: Fire-and-forget over UDP socket
- **UDS**: Unix Domain Socket, auto-detects datagram vs stream
- **Pipe**: Windows Named Pipe

### Telemetry Counters (S4)
- totalPayloadsSent: incremented on successful Write()
- totalPayloadsDroppedQueueFull: incremented when queue send fails
- totalPayloadsDroppedWriter: incremented when Write() fails
- totalBytesSent: accumulated from successful Write()
- totalBytesDroppedQueueFull: accumulated from dropped buffers
- totalBytesDroppedWriter: accumulated from failed Write() calls

### Invariants (S4)
- I4.1: Queue size never exceeds senderQueueSize
- I4.2: Each buffer is written at most once (no retries)
- I4.3: sendLoop never panics or stalls
- I4.4: transport.Close() is called exactly once, during Stop

---

## Part 5: Init-Once Singletons (S5)

### Intent
Container ID detection and external environment detection are computed exactly once at startup and cached for read-only access on every metric send.

### Entities
- **ContainerID**: Detected value, initially unset, then set exactly once.
- **ExternalEnv**: Environment variable value, initially unset, then set exactly once.

### States
- `Unset`: Value has not been determined yet.
- `Set(value)`: Value has been determined and stored.

### Rules (S5)
- **R5.1**: Init Container ID: First metric sent (or on explicit init), state = Unset → detect from cgroup/mountinfo/user option, state = Set(value)
- **R5.2**: Init External Env: Client created, state = Unset → read DD_EXTERNAL_ENV, sanitize (remove non-printable and |), state = Set(value)
- **R5.3**: Read Container ID: Any metric send → if state = Set, return stored value (lock-free); if state = Unset, trigger R5.1 first
- **R5.4**: Read External Env: Any metric send → if state = Set, return stored value (lock-free atomic read); if state = Unset, return empty string

### Container ID Detection Priority (Linux)
1. User-provided ID via WithContainerID() option
2. Parse /proc/self/cgroup for container ID patterns
3. Parse /proc/self/mountinfo for container ID in paths
4. Fall back to inode-based ID: in-<inode_decimal>

### Invariants (S5)
- I5.1: containerID value never changes after first Set
- I5.2: externalEnv value never changes after first Set
- I5.3: Read operations are lock-free after initialization
- I5.4: Initialization is idempotent

---

## Part 6: Wire Format, Configuration, and Error Handling (S6)

### Intent
DogStatsD specifies a text-based wire format compatible with statsd but extended with Datadog features (tags, container ID, cardinality, external env). Configuration controls which subsystems are enabled and their bounds.

### Wire Format Summary
All metrics are newline-delimited. Metric types: gauge (g), count (c), histogram (h), distribution (d), set (s), timing (ms).

### Key Configuration Options
| Option | Default | Purpose |
|--------|---------|---------|
| MaxBytesPerPayload | Auto (1432 UDP / 8192 UDS) | Hard limit per buffer |
| BufferFlushInterval | 100ms | How often to flush incomplete buffer |
| AggregationFlushInterval | 2s | How often to flush aggregated metrics |
| Aggregation | true | Enable client-side aggregation |
| ExtendedAggregation | false | Enable histogram/distribution/timing aggregation |
| MaxSamplesPerContext | -1 (unlimited) | Reservoir size for buffered aggregation |
| OriginDetection | true | Attempt to detect container ID and external env |
| Cardinality | CardinalityNotSet | Tag cardinality level appended to metrics |

### Tag Cardinality Levels
- CardinalityNotSet (0): No cardinality field
- CardinalityNone (1): |card:none
- CardinalityLow (2): |card:low
- CardinalityOrchestrator (3): |card:orchestrator
- CardinalityHigh (4): |card:high

### Error Types
- `ErrNoClient`: Operation on nil or closed client
- `ErrorInputChannelFull`: Worker input channel full (channel mode, if enabled)
- `ErrorSenderChannelFull`: Sender queue full
- `MessageTooLongError`: Single metric exceeds maxBytesPerPayload

### Error Handler Contract
User provides optional `ErrorHandler func(error)`. Must:
- Not block or panic
- Not modify client state
- Default handler is a no-op (silent drops)

---

## Cross-Subsystem Invariants

These invariants span multiple subsystems:

- **ClientOpenInvariant**: While Client.state = Open, all queued metrics eventually reach the transport or are explicitly dropped (no silent loss)
- **MetricOrdering**: Wire format field ordering (name:value|type|rate|tags|container|env|cardinality) is preserved on every metric
- **AggregationSemantics**: Counts accumulate, gauges are last-write-wins, sets are deduplicated, buffered metrics use reservoir sampling
- **BufferTransactionality**: Every metric in a buffer is either fully serialized or fully rolled back (no partial writes ever sent)
- **ShardingDeterminism**: FNV-1a hash of metric context always produces the same shard index (deterministic sharding for testability)
- **OnceInitialization**: ContainerID and ExternalEnv are computed exactly once and never re-initialized (sync.Once semantics)
- **ClosureFinality**: After Close(), client state is permanently Closed; no metrics submitted or sent; all goroutines and channels are cleanly drained

---

## Assumptions

- **Finite for model checking**: Metrics, contexts, and sample counts are bounded for TLA+ analysis
- **Nondeterministic environment**: Order of user calls and timing are not modeled as specific patterns
- **No clock unless modeled explicitly**: Ticker intervals (100ms, 2s, 10s) are abstract events, not time-based
- **Single-threaded user calls**: Go's concurrency model handles goroutines internally; user-facing API is sequential per client instance
- **No persistence or crash model**: Client state is lost on process exit; no durability guarantees
- **Network is lossy**: UDP drops are expected; no retry logic needed

---

## Open Questions

- Should Close() block if there are pending telemetry sends, or timeout?
- What is the exact behavior if a user calls Close() during a Flush()?
- Should a context with zero total samples be omitted from the flush?
- Should containerID detection fail gracefully if /proc is unavailable, or panic?
- Is there a maximum recommended tag cardinality level, or is it user-defined?
