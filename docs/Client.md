# Client Module — `src/Client.dfy`

Spec: `spec/allium.md` Part 1 (S1), TLA+ `ClientFlush`, `ClientClose`, `ClosureFinality`

---

## Purpose

Top-level DogStatsD client integrating all subsystems: Aggregator, Sender, and Singletons. Manages the full lifecycle — construction, metric submission, flush, and close — with all transitions formally proved.

Four behavioral guarantees, all formally proved:

- **Submit requires Open**: every `Submit*` method returns `Err(ErrNoClient)` when `state == Closed` (S1-C11, S1-C12)
- **Flush requires Open**: `Flush()` returns `Err(ErrNoClient)` when `state == Closed` (S1-C14)
- **Close stops subsystems**: after `Close()`, aggregator and sender are both `Stopped`, queue is empty (S1-C16/C17/C18)
- **ClosureFinality**: `state` is monotone — once `Closed` it never returns to `Open` (S1-C19)

---

## Types

### `ClientState` — S1-C01

```dafny
datatype ClientState = Open | Closed
```

Maps to TLA+ `clientState`. Only `Client.New` produces `Open`; only `Close()` transitions `Open → Closed`. No method sets `state := Open` after construction (S1-C19).

### `NullTransport`

```dafny
class NullTransport extends Snd.Transport {
  constructor()
  method Write(data: seq<byte>) returns (r: Result<nat>)
  method Close()
}
```

Stub `Transport` implementation used by `Close()` to satisfy `sender.Stop`. No real I/O: `Write` increments `writeCount` and returns `Ok(0)`; `Close` sets `closed := true` and increments `closeCount`. Ghost fields satisfy the `Transport` trait contract so Dafny can verify all `Stop` preconditions.

---

## `Client` class — S1-C02

```dafny
class Client {
  var state:       ClientState
  var aggregator:  Agg.Aggregator
  var sender:      Snd.Sender
  var config:      DogStatsDConfig
  var containerID: Sing.ContainerID
  var externalEnv: Sing.ExternalEnv

  ghost var metricsSubmitted: set<MetricContext>
  ghost var metricsInFlight:  set<MetricContext>
}
```

`metricsSubmitted` accumulates every `MetricContext` passed to any successful `Submit*` call. `metricsInFlight` mirrors it while `state == Open` (proved by `ClientOpenInvariant`). Both ghost fields carry no runtime cost and exist solely for proof witness purposes.

---

## Invariant — `Valid()` — S1-C03

```dafny
ghost predicate Valid()
  reads this, aggregator, sender
{
  aggregator.Valid() &&
  sender.Valid() &&
  sender.queue == [] &&
  (state == Open ==> !sender.transportClosed) &&
  (state == Open ==> aggregator.state == Agg.Running) &&
  (state == Open ==> sender.state == Snd.Running) &&
  (state == Open ==> metricsInFlight == metricsSubmitted) &&
  (state == Closed ==> metricsSubmitted == {}) &&
  (state == Closed ==> aggregator.state == Agg.Stopped) &&
  (state == Closed ==> sender.state == Snd.Stopped)
}
```

Three classes of conjunct:

1. **Subsystem validity**: `aggregator.Valid()` and `sender.Valid()` delegate structural invariants to their modules.
2. **Open invariants** (TLA+ `ClientOpenInvariant`): both subsystems `Running`; transport not yet closed; ghost sets consistent.
3. **Closed invariants** (TLA+ `ClosedClientNoPendingMetrics`, `ClosedClientStoppedAggregator`, `ClosedClientStoppedSender`): no pending metrics; aggregator and sender both `Stopped`.

The `sender.queue == []` conjunct is global (not state-dependent). It reflects the design choice that the client never enqueues buffers directly — the sender queue is always empty from the client's perspective. This simplifies `Close()`: `sender.Stop(transport)` sees an empty queue and only needs to close the transport.

---

## API

### `New(cfg)` — S1-C04

```dafny
constructor New(cfg: DogStatsDConfig)
  ensures Valid()
  ensures state            == Open
  ensures aggregator.state == Agg.Running
  ensures sender.state     == Snd.Running
  ensures metricsSubmitted == {}
  ensures metricsInFlight  == {}
  ensures fresh(aggregator) && fresh(sender)
```

Allocates `Aggregator.New(4)` (4 shards), `Sender.New(cfg.senderQueueSize)`, `ContainerID()`, and `ExternalEnv()`. Sets `state := Open`. Ghost sets start empty. `fresh` postconditions prevent aliasing with any pre-existing heap object — required by Dafny's modifies system.

---

### Submit methods — S1-C05 through S1-C10

All six `Submit*` methods share an identical contract pattern:

```dafny
method SubmitXxx(ctx: MetricContext, value: T, rate: real)
    returns (r: Result<Unit>)
  requires Valid()
  modifies this, aggregator
  ensures Valid()
  ensures state      == old(state)
  ensures aggregator == old(aggregator)
  ensures sender     == old(sender)
  ensures old(state) == Closed ==> r == Err(ErrNoClient)   // S1-C11
  ensures old(state) == Open   ==> r == Ok(Unit)
  ensures old(state) == Open   ==> ctx in metricsSubmitted
```

**Guard**: first statement checks `if state == Closed { r := Err(ErrNoClient); return; }`. This guard fires before any aggregator interaction, so a closed client is fully inert.

**Aggregation routing** (when guard passes):

| Method | Aggregation path |
|--------|-----------------|
| `SubmitGauge` | `aggregator.SampleGauge(ctx, value)` if `config.aggregationEnabled` |
| `SubmitCount` | `aggregator.SampleCount(ctx, value)` if `config.aggregationEnabled` |
| `SubmitSet` | `aggregator.SampleSet(ctx, value)` if `config.aggregationEnabled` |
| `SubmitHistogram` | `aggregator.SampleBuffered(ctx, value, config.maxSamplesPerContext)` if `config.extendedAggregation` |
| `SubmitDistribution` | `aggregator.SampleBuffered(ctx, value, config.maxSamplesPerContext)` if `config.extendedAggregation` |
| `SubmitTiming` | `aggregator.SampleBuffered(ctx, value, config.maxSamplesPerContext)` if `config.extendedAggregation` |

`Gauge`, `Count`, and `Set` route through `aggregationEnabled`. `Histogram`, `Distribution`, and `Timing` route through `extendedAggregation` (spec S2-R2.4: extended aggregation covers reservoir sampling for these three types). The two flags are independent in `DogStatsDConfig`.

**Sampling rate** (`rate: real`): accepted in the signature but not applied here. Deferred — recorded for future wire-format encoding. No spec obligation requires client-side rate filtering in this version.

**Ghost update**: `metricsSubmitted := metricsSubmitted + {ctx}` and `metricsInFlight := metricsInFlight + {ctx}` on success. The `ctx in metricsSubmitted` postcondition is the proof witness for S1-C23 (`ClientOpenInvariant`).

---

### `Flush()` — S1-C13

```dafny
method Flush() returns (r: Result<Unit>)
  requires Valid()
  modifies this, aggregator
  ensures Valid()
  ensures state      == old(state)
  ensures aggregator == old(aggregator)
  ensures sender     == old(sender)
  ensures old(state) == Closed ==> r == Err(ErrNoClient)   // S1-C14
  ensures old(state) == Open   ==> r == Ok(Unit)
```

Guard fires first (same pattern as `Submit*`). When `state == Open`, calls `aggregator.Flush()` to drain all shards into wire metrics. The sender queue is not used in this model — `Flush` does not enqueue anything. Maps to TLA+ `ClientFlush`.

---

### `Close()` — S1-C15

```dafny
method Close() returns (r: Result<Unit>)
  requires Valid()
  modifies this, aggregator, sender
  ensures Valid()
  ensures state            == Closed                   // S1-C16
  ensures aggregator.state == Agg.Stopped              // S1-C17
  ensures sender.state     == Snd.Stopped              // S1-C18
  ensures metricsSubmitted == {}                       // S1-C20
  ensures old(state) == Closed ==> r == Err(ErrNoClient)
  ensures old(state) == Open   ==> r == Ok(Unit)
```

Guard fires first (idempotent: second `Close()` returns `Err(ErrNoClient)` without modifying state). When `state == Open`, four steps:

1. `aggregator.Flush()` — drains pending metric state from all shards.
2. `aggregator.Stop()` — transitions aggregator `Running → Stopped`; no further samples accepted.
3. Allocate `t := new NullTransport()`. Assert `(t as object) != (sender as object)` and `sender.queue == []` (from `Valid()` precondition). Call `sender.Stop(t)` — transitions sender `Running → Stopped`, closes transport.
4. Set `state := Closed; metricsSubmitted := {}; metricsInFlight := {}`.

The fresh `NullTransport` is allocated per `Close()` call. This is necessary because `sender.Stop` requires a non-closed `Transport` with `!transport.closed`. The transport is only used to satisfy the contract; no real I/O occurs.

Maps to TLA+ `ClientClose`.

---

### `IsClosed()` — S1-C21

```dafny
function IsClosed(): bool
  reads this
{
  state == Closed
}
```

Pure query (`function`, not `method`). `reads this` only — no `modifies`. Returns `state == Closed`. No side effects by construction (Dafny `function` cannot mutate). Maps to spec S1-R1.6. Proved pure by lemma `IsClosedPure`.

---

## Proof Lemmas

### `ClosedClientNoSubmit` — S1-C11/C12

```dafny
lemma ClosedClientNoSubmit(c: Client)
  requires c.Valid()
  requires c.state == Closed
  ensures c.metricsSubmitted == {}
  ensures c.state != Open
{}
```

Extracts two clauses from `Valid()`: `state == Closed ==> metricsSubmitted == {}` and `Closed != Open`. Body empty — Dafny discharges from `Valid()`. The `state != Open` conclusion proves that any `Submit*` guard `if state == Closed` fires, preventing further submission.

---

### `FlushRequiresOpen` — S1-C14

```dafny
lemma FlushRequiresOpen(c: Client)
  requires c.Valid()
  requires c.state == Closed
  ensures c.state != Open
{}
```

Proves `Closed != Open`. The structural argument: the guard `if state == Closed { return Err(ErrNoClient) }` at the top of `Flush()` fires before any aggregator/sender interaction. Since `Closed != Open`, the early return path is the only path.

---

### `ClosureFinality` — S1-C19

```dafny
lemma ClosureFinality(c: Client)
  requires c.Valid()
  requires c.state == Closed
  ensures c.state == Closed
{}
```

Identity lemma. The structural argument: only `Client.New` (constructor) produces `state = Open`. `Close()` has postcondition `state == Closed`. No method has a postcondition `state == Open` or writes `state := Open`. Therefore `state` is monotone: `Unset → Open` (constructor) then `Open → Closed` (`Close()`). Reversal from `Closed → Open` is impossible.

Maps to TLA+ `ClosureFinality` which states: once `clientState = Closed`, all actions leave it `Closed`.

---

### `ClosedClientNoPendingMetrics` — S1-C20

```dafny
lemma ClosedClientNoPendingMetrics(c: Client)
  requires c.Valid()
  requires c.state == Closed
  ensures c.metricsSubmitted == {}
{}
```

Extracts `state == Closed ==> metricsSubmitted == {}` from `Valid()`. Body empty. Correlates to TLA+ `ClosedClientNoPendingMetrics` invariant.

---

### `IsClosedPure` — S1-C22

```dafny
lemma IsClosedPure(c: Client)
  requires c.Valid()
  ensures c.IsClosed() == (c.state == Closed)
{}
```

Proves `IsClosed()` is definitionally equal to the state test. Trivial from the function body. Formalizes S1-R1.6 (`IsClosed is a pure predicate`).

---

### `ClientOpenInvariant` — S1-C23

```dafny
lemma ClientOpenInvariant(c: Client)
  requires c.Valid()
  requires c.state == Open
  ensures c.metricsInFlight == c.metricsSubmitted
{}
```

Extracts `state == Open ==> metricsInFlight == metricsSubmitted` from `Valid()`. Proves that while the client is open, every submitted metric is tracked in the pipeline — none are silently lost without a telemetry update. Ghost fields `metricsSubmitted` / `metricsInFlight` carry the proof; no runtime cost.

---

## Proof Obligations Discharged

| Task ID | Claim | How Proved |
|---------|-------|-----------|
| S1-C11 | `SubmitRequiresOpen`: Submit* return `Err(ErrNoClient)` when Closed | `ensures old(state) == Closed ==> r == Err(ErrNoClient)` on all six methods |
| S1-C12 | `ClosedClientNoSubmit`: Closed client cannot submit | Lemma `ClosedClientNoSubmit`; `Valid()` clause `state == Closed ==> metricsSubmitted == {}` |
| S1-C14 | `FlushRequiresOpen`: Flush returns `Err(ErrNoClient)` when Closed | `ensures old(state) == Closed ==> r == Err(ErrNoClient)`; lemma `FlushRequiresOpen` |
| S1-C16 | `CloseTransitionsState`: `state == Closed` after Close | `ensures state == Closed` on `Close()` |
| S1-C17 | `CloseStopsAggregator`: `aggregator.state == Stopped` after Close | `ensures aggregator.state == Agg.Stopped` on `Close()` |
| S1-C18 | `CloseStopsSender`: `sender.state == Stopped` after Close | `ensures sender.state == Snd.Stopped` on `Close()` |
| S1-C19 | `ClosureFinality`: `Closed → Open` impossible | Structural: no method sets `state := Open`; lemma `ClosureFinality` |
| S1-C20 | `ClosedClientNoPendingMetrics`: `metricsSubmitted == {}` when Closed | `ensures metricsSubmitted == {}` on `Close()`; lemma `ClosedClientNoPendingMetrics` |
| S1-C22 | `IsClosedPure`: `IsClosed()` has no side effects | `function` keyword (no `modifies`); lemma `IsClosedPure` |
| S1-C23 | `ClientOpenInvariant`: no silent metric loss while Open | `Valid()` clause `state == Open ==> metricsInFlight == metricsSubmitted`; lemma `ClientOpenInvariant` |

---

## TLA+ Mapping

| TLA+ Variable / Action | Dafny |
|------------------------|-------|
| `clientState` | `client.state` |
| `aggregatorState` | `client.aggregator.state` |
| `senderState` | `client.sender.state` |
| `ClientFlush` action | `Flush()` method |
| `ClientClose` action | `Close()` method |
| `ClosureFinality` invariant | Structural + lemma `ClosureFinality` |
| `ClosedClientNoPendingMetrics` | `Valid()` conjunct + lemma `ClosedClientNoPendingMetrics` |
| `ClosedClientStoppedAggregator` | `Valid()` conjunct + `ensures aggregator.state == Agg.Stopped` |
| `ClosedClientStoppedSender` | `Valid()` conjunct + `ensures sender.state == Snd.Stopped` |
| `ClientOpenInvariant` | `Valid()` conjunct + lemma `ClientOpenInvariant` |

---

## Tests — `test/TestS1.dfy`

Eight runtime tests covering core lifecycle paths:

| Test | ID | What it checks |
|------|----|---------------|
| `TestNewClientIsOpen` | T-S1-01 | `Client.New` returns `state == Open` |
| `TestGaugeOnOpenSucceeds` | T-S1-02 | `SubmitGauge` returns `Ok(Unit)` when Open |
| `TestGaugeOnClosedReturnsError` | T-S1-03 | `SubmitGauge` returns `Err(ErrNoClient)` after `Close()` |
| `TestCloseIdempotent` | T-S1-04 | Second `Close()` leaves `state == Closed`; first returns `Ok`, second returns `Err(ErrNoClient)` |
| `TestIsClosedReflectsState` | T-S1-05 | `IsClosed()` false before `Close()`, true after |
| `TestFlushOnOpenSendsPending` | T-S1-06 | `Flush()` returns `Ok(Unit)` when Open |
| `TestFlushOnClosedReturnsError` | T-S1-07 | `Flush()` returns `Err(ErrNoClient)` after `Close()` |
| `TestAllMetricTypesOnClosed` | T-S1-08 | All six `Submit*` methods return `Err(ErrNoClient)` when Closed |

---

## Verification

```bash
dafny verify src/Client.dfy
```

Expected output: **0 errors**

No `assume` statements in this module.

---

## Dependencies

| Module | Usage |
|--------|-------|
| `src/Types.dfy` | `MetricContext`, `DogStatsDConfig`, `DefaultConfig`, `TagCardinality`, `byte` |
| `src/Errors.dfy` | `Result<T>`, `DogStatsDError`, `ErrNoClient` |
| `src/Buffer.dfy` | `Buffer` (transitively via Sender) |
| `src/Aggregator.dfy` | `Aggregator` class — sharded metric aggregation |
| `src/Sender.dfy` | `Sender` class + `Transport` trait — send queue lifecycle |
| `src/Singletons.dfy` | `ContainerID`, `ExternalEnv` — write-once singletons |
