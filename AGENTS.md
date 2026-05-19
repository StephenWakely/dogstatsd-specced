# AGENTS.md — DogStatsD Dafny Client

## Source of Truth (Mandatory Reading)

Before writing any Dafny code, read these specs in order:

1. `spec/allium.md` — behavioral intent, rules, and invariants per subsystem (S1–S6)
2. `spec/model.tla` — TLA+ formal state machine (variables, actions, invariants)
3. `spec/model.cfg` — TLA+ model constants (MaxBufferSize=100, SenderQueueSize=3, etc.)
4. `spec/check-results.md` — TLC model checking outcomes and known bounds
5. `spec/rust-contract.md` — state/transition mapping table (repurpose for Dafny)

**Rule:** Every Dafny module, method, and lemma must be traceable back to a specific rule (R_x.y), invariant (I_x.y), or TLA+ action in the specs above. If it cannot be traced, it should not exist.

---

## Architecture

```
src/
  Types.dfy         → MetricType, TransportMode, TagCardinality, MetricContext, config constants
  Errors.dfy        → DogStatsDError datatype (ErrNoClient, MessageTooLong, etc.)
  WireFormat.dfy    → Serialization functions + MetricOrdering proofs (S6)
  Buffer.dfy        → Buffer datatype, transactional WriteMetric, invariant lemmas (S3)
  BufferPool.dfy    → BufferPool, Borrow/Return, pool capacity invariants (S3)
  Aggregator.dfy    → Count/Gauge/Set/Buffered shards, SampleX methods, Flush (S2)
  Singletons.dfy    → ContainerID + ExternalEnv once-init, read-only after set (S5)
  Sender.dfy        → Sender queue, EnqueueBuffer, SendFromQueue, telemetry (S4)
  Client.dfy        → Client lifecycle, New/Submit/Flush/Close, cross-system invariants (S1)
test/
  TestS1.dfy        → Client lifecycle tests
  TestS2.dfy        → Aggregator tests
  TestS3.dfy        → Buffer and pool tests
  TestS4.dfy        → Sender tests
  TestS5.dfy        → Singleton tests
  TestS6.dfy        → Wire format tests
```

---

## Dafny Conventions

### Spec Traceability

Every method and lemma MUST carry a comment citing its spec origin:

```dafny
// S3-R3.2: Buffer rollback on overflow
method WriteMetric(metric: seq<byte>) returns (result: Result<(), DogStatsDError>)
```

```dafny
// S3-I3.1: buffer.len <= buffer.maxSize always
lemma BufferNoOverflow(b: Buffer)
  ensures b.len <= b.maxSize
```

### Invariant Enforcement

- Safety invariants from TLA+ model (`Inv` in model.tla) MUST be expressed as Dafny `invariant` clauses or lemmas.
- All TLA+ state-space invariants map to Dafny predicate functions named `Valid()` on each datatype.
- Every mutating method must preserve `Valid()` — i.e., `requires Valid()` and `ensures Valid()`.

### Proof Obligations

Map each TLA+ invariant to Dafny:

| TLA+ Invariant | Dafny Form |
|---|---|
| `BufferNotOverflow` (`bufferLen <= MaxBufferSize`) | `invariant b.len <= b.maxSize` in Buffer.Valid() |
| `QueueNotOverflow` (`queueLen <= SenderQueueSize`) | `invariant s.queueLen <= s.maxQueueSize` in Sender.Valid() |
| `ClosedClientNoPendingMetrics` | `invariant closed ==> pendingMetrics == {}` in Client.Valid() |
| `ClosedClientStoppedAggregator` | `invariant closed ==> aggregator.state == Stopped` |
| `ClosedClientStoppedSender` | `invariant closed ==> sender.state == Stopped` |
| `InitStateConsistent` | `invariant containerIDState in {Unset, Set}` |
| `NoContainerIDChange` (I5.1) | Prove immutability via ghost state or OnceLock lemma |
| `TransactionalWrites` (I3.3) | `ensures result.IsFailure() ==> buf == old(buf)` |
| `MetricOrdering` (S6) | Proved in WireFormat serialization lemmas |

### Data Modeling

- Model TLA+ state variables as Dafny `class` fields or `datatype` record fields.
- Use `ghost` variables to track TLA+ auxiliary state (e.g., `ghost metricsSubmitted: set<MetricContext>`).
- For once-init singletons (S5), use a ghost boolean `initialized` and prove it can only transition `false → true`.

### Concurrency

Dafny is sequential. Model Go's concurrency via:
- Ghost history variables tracking the trace of operations
- Abstract `Worker`, `Aggregator`, `Sender` as sequential objects
- Prove that invariants hold under any interleaving using nondeterministic method pre/post conditions

---

## Spec Compliance Checklist

Before marking any task complete, verify:

**S1 (Client Lifecycle)**
- [ ] `New()` creates client with `state == Open`
- [ ] Metric submission requires `state == Open` (precondition)
- [ ] `Flush()` requires `state == Open`
- [ ] `Close()` transitions `Open → Closed`, flushes pending, stops aggregator + sender
- [ ] Operations on `Closed` client return `ErrNoClient` (not panic)
- [ ] `IsClosed()` has no side effects (pure function)

**S2 (Aggregator)**
- [ ] `SampleCount` only runs when `aggregatorState == Running`
- [ ] Counts are increment-only (never decremented)
- [ ] Gauges use last-write-wins (overwrite, not accumulate)
- [ ] Sets deduplicate by construction
- [ ] `FlushAggregator` emits exactly one metric per context, then resets
- [ ] `StopAggregator` prevents all further samples

**S3 (Worker/Buffer)**
- [ ] WriteMetric is transactional: either appends fully or rolls back fully
- [ ] `buf.len <= buf.maxSize` always
- [ ] `buf.elementCount <= buf.maxElements` always
- [ ] BufferPool never exceeds capacity; excess returns are discarded
- [ ] Wire format order: `name:value|type[|@rate][|#tags][|c:cid][|e:env][|card:x]\n`

**S4 (Sender)**
- [ ] `queueLen <= senderQueueSize` always
- [ ] Enqueue is non-blocking; drops + increments telemetry when full
- [ ] Each buffer sent at most once (no retries)
- [ ] Telemetry counters increment monotonically
- [ ] `transport.Close()` called exactly once (during Stop)

**S5 (Init Singletons)**
- [ ] ContainerID initialized at most once; value immutable after Set
- [ ] ExternalEnv initialized at most once; value immutable after Set
- [ ] Sanitization removes non-printable chars and `|` from external env
- [ ] Reads return consistent value; empty string if Unset

**S6 (Wire Format)**
- [ ] Field order exactly: `name:value|type` → `|@rate` → `|#tags` → `|c:cid` → `|e:env` → `|card:x` → `\n`
- [ ] Cardinality strings: none/low/orchestrator/high
- [ ] Type symbols: g/c/h/d/s/ms

---

## Forbidden Patterns

- **No method** that can mutate client state while `state == Closed`
- **No method** that can sample into aggregator while `aggregatorState == Stopped`
- **No write** to a buffer that would cause `len > maxSize` without full rollback
- **No enqueue** that would cause `queueLen > senderQueueSize`
- **No second initialization** of ContainerID or ExternalEnv
- **No `panic` equivalent**: all error conditions return `Result<T, DogStatsDError>`, never `assume false`
- **No partial wire format**: a metric is fully serialized or not at all

---

## Testing Requirements

Every test method must be annotated `{:test}` for `dafny test`. Tests must:

1. Cover each TLA+ action from `spec/model.tla`
2. Verify each invariant by checking the forbidden (negative) case
3. Match the test obligations from `spec/rust-contract.md` §9 (adapted for Dafny)

---

## Running the Verifier

```bash
# Verify a single file
dafny verify src/Buffer.dfy

# Verify all source files
dafny verify src/*.dfy

# Run tests
dafny test test/TestS3.dfy

# Check everything
dafny verify src/*.dfy test/*.dfy
```

Verification must pass with zero errors before any task is marked complete.
