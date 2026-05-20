# Aggregator Module — `src/Aggregator.dfy`

Spec: `spec/allium.md` Part 2 (S2), TLA+ `AggregatorFlush`, `SampleCount`, `SampleGauge`, `SampleSet`, `SampleBuffered`, `ClientClose`

---

## Purpose

Sharded metric aggregator for counts, gauges, sets, and buffered/reservoir samples. Metrics are assigned to one of `n` shards via FNV-1a hash of `MetricContext`; each shard is an independent map, isolating concurrent writes. `Flush()` drains all shards into a `seq<WireMetric>` and resets them. `Stop()` permanently disables sampling.

Four behavioral guarantees, all formally proved:

- **Counts accumulate**: each `SampleCount` increases `count[ctx]` by exactly `value`; counts never decrease (S2-A13, S2-A14)
- **Gauges are last-write-wins**: `SampleGauge` sets `gauge[ctx] := value`, not `+= value` (S2-A16)
- **Sets deduplicate**: `SampleSet` inserts into a Dafny `set<string>`; duplicate values leave cardinality unchanged (S2-A18)
- **Flush emits at most one metric per context per type**: proved via `UniqueWireMetrics` postcondition (S2-A22)

---

## Types

### `AggregatorState` — S2-A01

```dafny
datatype AggregatorState = Running | Stopped
```

Maps to TLA+ `aggregatorState`. `Stop()` transitions `Running → Stopped`; no method reverses this (S2-A26).

### Shard types — S2-A02 through S2-A04

```dafny
type CountShard = map<MetricContext, int>
type GaugeShard = map<MetricContext, real>
type SetShard   = map<MetricContext, set<string>>
```

Each shard is a functional map. A context lives in exactly one shard — the one at `ShardIndex(ctx, shardCount)`. The `Valid()` invariant proves this structural property (`WellFormedShards`).

### `BufferedMetricState` — S2-A05

```dafny
datatype BufferedMetricState = BufferedMetricState(
  samples:      seq<real>,
  totalSamples: nat
)
```

Tracks reservoir sampling state per context. `totalSamples` counts every call to `SampleBuffered` for this context (monotone, proved S2-A20). `samples` holds the capped window: when `|samples| < maxSamples`, the new value is appended; once full, the sequence is kept as-is. `totalSamples` still increments even when the reservoir is full.

---

## FNV-1a Sharding — S2-A08 through S2-A10

```dafny
const FNV_PRIME_32:  bv32 := 16777619
const FNV_OFFSET_32: bv32 := 2166136261

function FNV1aStep(h: bv32, c: char): bv32
function FNV1aStringAcc(s: string, h: bv32): bv32
function FNV1aTagsAcc(tags: seq<string>, h: bv32): bv32
function ContextHash(ctx: MetricContext): bv32

function ShardIndex(ctx: MetricContext, shardCount: nat): nat
  requires shardCount > 0
```

`ContextHash` hashes the metric name first (FNV-1a character-by-character), then each tag string in order. Only the lower 8 bits of each `char` are used (`c as int % 256`), keeping the hash well-defined for all Unicode code points.

`ShardIndex` returns `ContextHash(ctx) as nat % shardCount`, placing the result in `[0, shardCount)`.

Two proved lemmas:

| Lemma | Statement |
|-------|-----------|
| `ShardIndexDeterministic` (S2-A09) | Same context + same count → same index. Trivial: `ShardIndex` is a pure function. |
| `ShardIndexInBounds` (S2-A10) | `ShardIndex(ctx, n) < n` for all `n > 0`. Follows from `% n`. |

---

## `Aggregator` class — S2-A06

```dafny
class Aggregator {
  var state:       AggregatorState
  var countShards: seq<CountShard>
  var gaugeShards: seq<GaugeShard>
  var setShards:   seq<SetShard>
  var buffered:    map<MetricContext, BufferedMetricState>
  var shardCount:  nat
  ghost var metricsSubmitted: set<MetricContext>
}
```

`metricsSubmitted` is a ghost field accumulating every context ever passed to any `Sample*` method. It is used for proof witness purposes and carries no runtime cost.

---

## Invariant — `Valid()` (S2-A07)

```dafny
predicate Valid()
  reads this
{
  shardCount > 0 &&
  |countShards| == shardCount &&
  |gaugeShards| == shardCount &&
  |setShards|   == shardCount &&
  // I2.3: all counts non-negative
  (forall s :: 0 <= s < shardCount ==>
     forall ctx :: ctx in countShards[s] ==> countShards[s][ctx] >= 0) &&
  // WellFormedShards: each ctx hashes to its shard index
  (forall s :: 0 <= s < shardCount ==>
     forall ctx :: ctx in countShards[s] ==> ShardIndex(ctx, shardCount) == s) &&
  (forall s :: 0 <= s < shardCount ==>
     forall ctx :: ctx in gaugeShards[s] ==> ShardIndex(ctx, shardCount) == s) &&
  (forall s :: 0 <= s < shardCount ==>
     forall ctx :: ctx in setShards[s] ==> ShardIndex(ctx, shardCount) == s)
}
```

Three classes of conjunct:

1. **Structural**: `shardCount > 0` and all three shard seqs have length `shardCount`.
2. **Non-negativity (I2.3)**: every stored count is `>= 0`. Since count values are `int` (not `nat`), this must be stated explicitly. Proved by postcondition on `SampleCount`.
3. **WellFormedShards**: each context stored in shard `s` hashes to exactly `s`. This is the key invariant enabling the `CountShardsDisjoint` / `GaugeShardsDisjoint` / `SetShardsDisjoint` lemmas, which prove a context cannot appear in two shards simultaneously.

`buffered` is an unsharded map — it has no `Valid()` clause beyond the structural invariant of the containing class.

---

## API

### `New(n)` — S2-A06

```dafny
constructor New(n: nat)
  requires n > 0
  ensures Valid()
  ensures state == Running
  ensures shardCount == n
  ensures metricsSubmitted == {}
  ensures buffered == map[]
  ensures forall s :: 0 <= s < shardCount ==> countShards[s] == map[]
  ensures forall s :: 0 <= s < shardCount ==> gaugeShards[s] == map[]
  ensures forall s :: 0 <= s < shardCount ==> setShards[s] == map[]
```

Allocates `n` empty shards for each metric type using `seq(n, _ => map[])`. All ghost state is empty.

---

### `SampleCount(ctx, value)` — S2-A11

```dafny
method SampleCount(ctx: MetricContext, value: nat)
  requires Valid()
  requires state == Running
  modifies this
  ensures Valid()
  ensures state == Running
  // S2-A14: increment-only
  ensures var s := ShardIndex(ctx, shardCount);
          ctx in countShards[s] &&
          (var prev := if ctx in old(countShards)[s] then old(countShards)[s][ctx] else 0;
           countShards[s][ctx] == prev + value)
  // other shards unchanged; same shard, other keys unchanged
```

Computes `s := ShardIndex(ctx, shardCount)`, reads the previous value (defaulting to 0), writes `countShards[s][ctx] := prev + value`. Since `value: nat`, `prev >= 0` (from `Valid()`), the new value is `>= 0`, preserving I2.3.

The `requires state == Running` postcondition discharges S2-A12 (`SampleCountPreservesRunning`): a `Stopped` aggregator cannot call this method — the precondition fails at verification time.

---

### `SampleGauge(ctx, value)` — S2-A15

```dafny
method SampleGauge(ctx: MetricContext, value: real)
  requires Valid()
  requires state == Running
  modifies this
  ensures Valid()
  // S2-A16: last-write-wins
  ensures var s := ShardIndex(ctx, shardCount);
          ctx in gaugeShards[s] && gaugeShards[s][ctx] == value
```

Sets `gaugeShards[s][ctx] := value` unconditionally. The postcondition `gaugeShards[s][ctx] == value` (not `+= value`) directly proves S2-A16 (`GaugeLastWriteWins`).

---

### `SampleSet(ctx, value)` — S2-A17

```dafny
method SampleSet(ctx: MetricContext, value: string)
  requires Valid()
  requires state == Running
  modifies this
  ensures Valid()
  // value present after
  ensures var s := ShardIndex(ctx, shardCount);
          ctx in setShards[s] && value in setShards[s][ctx]
  // S2-A18: deduplication — if value was already present, set is unchanged
  ensures var s      := ShardIndex(ctx, shardCount);
          var oldSet := if ctx in old(setShards)[s] then old(setShards)[s][ctx] else {};
          value in oldSet ==> setShards[s][ctx] == oldSet
```

Reads the existing set (defaulting to `{}`), writes `setShards[s][ctx] := oldSet + {value}`. Dafny's set union is idempotent: if `value in oldSet` then `oldSet + {value} == oldSet`, satisfying S2-A18 (`SetDeduplication`).

---

### `SampleBuffered(ctx, value, maxSamples)` — S2-A19

```dafny
method SampleBuffered(ctx: MetricContext, value: real, maxSamples: int)
  requires Valid()
  requires state == Running
  modifies this
  ensures Valid()
  // S2-A20: totalSamples strictly increases by 1
  ensures ctx in buffered
  ensures buffered[ctx].totalSamples ==
          (if ctx in old(buffered) then old(buffered)[ctx].totalSamples else 0) + 1
  // reservoir: append when below cap, keep otherwise
  ensures var oldSamples := if ctx in old(buffered) then old(buffered)[ctx].samples else [];
          (maxSamples > 0 && |oldSamples| < maxSamples) ==>
            buffered[ctx].samples == oldSamples + [value]
  ensures var oldSamples := if ctx in old(buffered) then old(buffered)[ctx].samples else [];
          !(maxSamples > 0 && |oldSamples| < maxSamples) ==>
            buffered[ctx].samples == oldSamples
```

Reservoir logic: if `maxSamples > 0` and the current sample window is below capacity, append `value`; otherwise leave `samples` unchanged. In both cases `totalSamples` is incremented by 1. S2-A20 (`BufferedTotalSamplesMonotone`) follows directly from the `+= 1` postcondition.

---

### `Flush()` — S2-A21

```dafny
method Flush() returns (result: seq<WireMetric>)
  requires Valid()
  requires state == Running
  modifies this
  ensures Valid()
  ensures state == Running
  ensures shardCount == old(shardCount)
  // S2-A23: all shards reset
  ensures forall s :: 0 <= s < shardCount ==> countShards[s] == map[]
  ensures forall s :: 0 <= s < shardCount ==> gaugeShards[s] == map[]
  ensures forall s :: 0 <= s < shardCount ==> setShards[s]   == map[]
  ensures buffered == map[]
  // S2-A22: at most one metric per (name, tags, metricType)
  ensures UniqueWireMetrics(result)
```

Four steps:

1. **Collect** — call `CollectCountMetrics()`, `CollectGaugeMetrics()`, `CollectSetMetrics()`, `CollectBufferedMetrics()`, each returning a typed segment.
2. **Reset** — overwrite all shard seqs with `seq(shardCount, _ => map[])` and `buffered := map[]` (S2-A23).
3. **Chain uniqueness** — assert single-type predicates (`AllType(countResult, Count)` etc.) then call `ConcatUniqueByType` / `ConcatCGWithSet` / `ConcatCGSWithBuffered` to prove the concatenated output is `UniqueWireMetrics` (S2-A22).
4. **Return** — `result := cgs + bufferedResult`.

The uniqueness proof is type-segregated: within each segment, uniqueness is proved by the shard-iteration invariant (each context emitted at most once, tracked by ghost `emittedCtxs`). Across segments, uniqueness follows because all four metric types are distinct — no `(name, tags, Count)` entry can collide with a `(name, tags, Gauge)` entry.

Zero-valued counts (`v == 0`) and empty sets (`v == {}`) are **not emitted**. This means `IntToString` / `RealToString` externs are only called on non-default values. Gauges are always emitted (any real value is meaningful).

---

### `Stop()` — S2-A24

```dafny
method Stop()
  requires Valid()
  modifies this
  ensures Valid()
  ensures state == Stopped
  ensures shardCount  == old(shardCount)
  ensures countShards == old(countShards)
  ensures gaugeShards == old(gaugeShards)
  ensures setShards   == old(setShards)
  ensures buffered    == old(buffered)
  ensures metricsSubmitted == old(metricsSubmitted)
```

Sets `state := Stopped`. All shard state is preserved — a flush before Stop is the caller's responsibility. No `requires state == Running` precondition: `Stop()` is idempotent on state (calling it twice is safe, state stays `Stopped`).

S2-A25 (`StopPreventsNewSamples`) holds structurally: all `Sample*` methods carry `requires state == Running`, so a `Stopped` aggregator cannot call them.

S2-A26 (`StopIsTerminal`) holds structurally: no method sets `state := Running` after construction.

---

## Helper Methods

All four collectors are called only from `Flush()`. They read shard state without modifying it.

### `CollectCountMetrics()` — S2-A21

```dafny
method CollectCountMetrics() returns (r: seq<WireMetric>)
  requires Valid()
  ensures AllType(r, Count)
  ensures UniqueWireMetrics(r)
```

Outer loop over shards `0..shardCount`; inner loop over `shard.Keys` using `remaining := shard.Keys`. Each context popped from `remaining` is checked: if its count is non-zero, a `WireMetric` with `metricType := Count` and `value := IntToString(v)` is appended. Ghost set `emittedCtxs` accumulates processed contexts; the uniqueness invariant holds because each context's shard index is strictly less than the current outer index once the outer loop advances.

### `CollectGaugeMetrics()` — S2-A21

Identical structure to `CollectCountMetrics()` but iterates `gaugeShards`. All contexts are emitted (no zero-filter), with `value := RealToString(v)` and `metricType := Gauge`.

### `CollectSetMetrics()` — S2-A21

Identical structure; iterates `setShards`. Empty sets are filtered (`if v != {}`); emitted metrics use `value := IntToString(|v|)` (set cardinality) and `metricType := Set`.

### `CollectBufferedMetrics()` — S2-A21

Single-level loop over `buffered.Keys`. Emits one `WireMetric` per context with `value := IntToString(totalSamples as int)` and `metricType := Histogram`. No filtering — a context only appears in `buffered` after at least one `SampleBuffered` call, so `totalSamples >= 1`.

---

## Proof Helpers and Lemmas

### `UniqueWireMetrics` / `AllType` predicates

```dafny
predicate AllType(metrics: seq<WireMetric>, t: MetricType)
predicate UniqueWireMetrics(metrics: seq<WireMetric>)
```

`UniqueWireMetrics` asserts no two entries share `(name, tags, metricType)`. Used as the S2-A22 postcondition on `Flush()`.

### `ConcatUniqueByType` — S2-A22

```dafny
lemma ConcatUniqueByType(a: seq<WireMetric>, b: seq<WireMetric>,
                          ta: MetricType,    tb: MetricType)
  requires ta != tb
  requires AllType(a, ta) && AllType(b, tb)
  requires UniqueWireMetrics(a) && UniqueWireMetrics(b)
  ensures  UniqueWireMetrics(a + b)
```

Proves concatenation of two single-type unique segments is unique when the types differ. Three-case proof: both in `a` (use `UniqueWireMetrics(a)`), both in `b` (use `UniqueWireMetrics(b)`), one in each (types differ, so `metricType` fields cannot match).

### `ConcatCGWithSet` / `ConcatCGSWithBuffered`

Generalizations of `ConcatUniqueByType` for mixed-type prefixes. `ConcatCGWithSet` handles the step `(Count|Gauge sequence) ++ (Set sequence)`; `ConcatCGSWithBuffered` handles `(Count|Gauge|Set sequence) ++ (Histogram sequence)`. Both use the same three-case structure, relying on type-disjointness across segments.

### `CountShardsDisjoint` / `GaugeShardsDisjoint` / `SetShardsDisjoint`

```dafny
lemma CountShardsDisjoint(
  shards: seq<CountShard>, n: nat,
  ctx: MetricContext, s1: nat, s2: nat)
  requires n > 0 && |shards| == n
  requires 0 <= s1 < n && 0 <= s2 < n && s1 != s2
  requires forall s :: 0 <= s < n ==>
             forall c :: c in shards[s] ==> ShardIndex(c, n) == s
  ensures !(ctx in shards[s1] && ctx in shards[s2])
```

Proves a context cannot appear in two distinct shards simultaneously. Key step: if `ctx in shards[s1]` and `ctx in shards[s2]`, then `ShardIndex(ctx, n) == s1` and `ShardIndex(ctx, n) == s2`, contradicting `s1 != s2`.

### `CountsNonNegative` — S2-A13

```dafny
lemma CountsNonNegative(agg: Aggregator)
  requires agg.Valid()
  ensures forall s :: 0 <= s < agg.shardCount ==>
            forall ctx :: ctx in agg.countShards[s] ==> agg.countShards[s][ctx] >= 0
{}
```

Extracts the non-negativity clause from `Valid()`. Body empty — Dafny discharges from the invariant.

### `StopPreventsNewSamples` — S2-A25

```dafny
lemma StopPreventsNewSamples(agg: Aggregator)
  requires agg.Valid()
  requires agg.state == Stopped
  ensures agg.state != Running
{}
```

Trivial (`Stopped != Running` by datatype). The structural enforcement is that `Sample*` methods carry `requires state == Running`.

### `StopIsTerminal` — S2-A26

```dafny
lemma StopIsTerminal(agg: Aggregator)
  requires agg.Valid()
  requires agg.state == Stopped
  ensures agg.state == Stopped
{}
```

Identity lemma. The structural enforcement is that no method sets `state := Running` post-construction. The constructor sets `Running`; `Stop()` sets `Stopped`; no reversal exists.

### Extern stubs

```dafny
function {:extern} IntToString(n: int): string  { "" }
function {:extern} RealToString(r: real): string { "" }
```

Concrete implementations are provided outside Dafny (Go/C#). Stub bodies (`""`) satisfy the compiler when no extern override is linked. The empty-string fallback never affects verification — Dafny treats `{:extern}` function bodies as opaque; only the signatures are used in proofs.

---

## Proof Obligations Discharged

| Task ID | Claim | How Proved |
|---------|-------|-----------|
| S2-A09 | `ShardIndexDeterministic`: same ctx → same shard | Trivial: `ShardIndex` is a pure function |
| S2-A10 | `ShardIndexInBounds`: `ShardIndex(ctx,n) < n` | Follows from `% n` |
| S2-A12 | `SampleCountPreservesRunning`: Stopped → no new counts | `requires state == Running` on `SampleCount` |
| S2-A13 | `CountsNonNegative`: all counts `>= 0` | `Valid()` conjunct + lemma `CountsNonNegative` |
| S2-A14 | `CountsIncrementOnly`: `count[ctx] >= old(count[ctx])` | `ensures countShards[s][ctx] == prev + value` with `value: nat` |
| S2-A16 | `GaugeLastWriteWins`: `gauge[ctx] == value` after write | `ensures gaugeShards[s][ctx] == value` |
| S2-A18 | `SetDeduplication`: duplicate value leaves `\|set\|` unchanged | `ensures value in oldSet ==> setShards[s][ctx] == oldSet` |
| S2-A20 | `BufferedTotalSamplesMonotone`: totalSamples only increases | `ensures buffered[ctx].totalSamples == old(...) + 1` |
| S2-A22 | `FlushEmitsOnePerContext`: `UniqueWireMetrics(result)` | Type-segregated segments + `ConcatUniqueByType` / `ConcatCGWithSet` / `ConcatCGSWithBuffered` |
| S2-A23 | `FlushResetsShards`: all shards `== map[]` after Flush | `ensures` on all four shard fields; `buffered == map[]` |
| S2-A25 | `StopPreventsNewSamples`: Stopped blocks Sample* | `requires state == Running` on all `Sample*`; lemma `StopPreventsNewSamples` |
| S2-A26 | `StopIsTerminal`: no Stopped → Running transition | Structural: no method sets `state := Running`; lemma `StopIsTerminal` |

---

## TLA+ Mapping

| TLA+ Variable / Action | Dafny |
|------------------------|-------|
| `aggregatorState` | `agg.state` |
| `countShards[s][ctx]` | `agg.countShards[s][ctx]` |
| `gaugeShards[s][ctx]` | `agg.gaugeShards[s][ctx]` |
| `setShards[s][ctx]` | `agg.setShards[s][ctx]` |
| `bufferedCount[ctx]` | `agg.buffered[ctx].totalSamples` |
| `ShardingDeterminism` | `ShardIndexDeterministic` lemma |
| `SampleCount` action | `SampleCount` method |
| `SampleGauge` action | `SampleGauge` method |
| `SampleSet` action | `SampleSet` method |
| `SampleBuffered` action | `SampleBuffered` method |
| `AggregatorFlush` action | `Flush` method |
| `ClientClose` action | `Stop` method |

---

## Tests — `test/TestS2.dfy`

Six runtime tests covering the core invariants:

| Test | What it checks |
|------|---------------|
| `TestSampleCountAccumulates` (T-S2-01) | Two `SampleCount` calls sum correctly |
| `TestSampleGaugeLastWriteWins` (T-S2-02) | Second `SampleGauge` replaces first |
| `TestSampleSetDeduplication` (T-S2-03) | Duplicate `SampleSet` value leaves `\|set\| == 1` |
| `TestSampleBufferedMonotoneAndCap` (T-S2-04) | `totalSamples` increments; reservoir cap respected |
| `TestFlushResetsShards` (T-S2-05) | All shards empty after `Flush()`; zero-count entries not emitted |
| `TestStopSetsStateStopped` (T-S2-06) | `Stop()` sets `state == Stopped` |

---

## Verification

```bash
dafny verify src/Aggregator.dfy
```

Expected output: **0 errors**

No `assume` statements in this module.

---

## Dependencies

| Module | Usage |
|--------|-------|
| `src/Types.dfy` | `MetricContext`, `MetricType`, `TagCardinality`, `Option<T>` |
| `src/Errors.dfy` | `DogStatsDError` (transitively via imports) |
| `src/WireFormat.dfy` | `WireMetric` datatype — output type of `Flush()` |
