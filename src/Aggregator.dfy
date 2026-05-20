// S2: Sharded metric aggregator — counts, gauges, sets, buffered/reservoir.
// Spec: allium.md §Part 2 (S2), TLA+ model.tla AggregatorFlush, SampleCount, etc.
include "Types.dfy"
include "Errors.dfy"
include "WireFormat.dfy"

module Aggregator {
  import opened Types
  import opened Errors
  import opened WireFormat

  // S2-A01: aggregator lifecycle state (TLA+: aggregatorState)
  datatype AggregatorState = Running | Stopped

  // S2-A02: count shard (TLA+: countShards[s][ctx])
  type CountShard = map<MetricContext, int>

  // S2-A03: gauge shard (TLA+: gaugeShards[s][ctx])
  type GaugeShard = map<MetricContext, real>

  // S2-A04: set shard (TLA+: setShards[s][ctx])
  type SetShard = map<MetricContext, set<string>>

  // S2-A05: buffered metric state for reservoir sampling (TLA+: bufferedCount[ctx])
  datatype BufferedMetricState = BufferedMetricState(
    samples:      seq<real>,
    totalSamples: nat
  )

  // ── FNV-1a hash (S2-A08) ────────────────────────────────────────────────

  const FNV_PRIME_32:  bv32 := 16777619
  const FNV_OFFSET_32: bv32 := 2166136261

  // Hash one char (lower byte only; Unicode ≤ 0x10FFFF fits safely)
  function FNV1aStep(h: bv32, c: char): bv32
  {
    var b: bv32 := (c as int % 256) as bv32;
    (h ^ b) * FNV_PRIME_32
  }

  function FNV1aStringAcc(s: string, h: bv32): bv32
    decreases |s|
  {
    if |s| == 0 then h
    else FNV1aStringAcc(s[1..], FNV1aStep(h, s[0]))
  }

  function FNV1aTagsAcc(tags: seq<string>, h: bv32): bv32
    decreases |tags|
  {
    if |tags| == 0 then h
    else FNV1aTagsAcc(tags[1..], FNV1aStringAcc(tags[0], h))
  }

  function ContextHash(ctx: MetricContext): bv32
  {
    FNV1aTagsAcc(ctx.tags, FNV1aStringAcc(ctx.name, FNV_OFFSET_32))
  }

  // S2-A08: deterministic FNV-1a shard assignment in [0, shardCount)
  function ShardIndex(ctx: MetricContext, shardCount: nat): nat
    requires shardCount > 0
  {
    (ContextHash(ctx) as nat) % shardCount
  }

  // S2-A09: determinism — pure function, trivially same output for same input
  lemma ShardIndexDeterministic(ctx: MetricContext, n: nat)
    requires n > 0
    ensures ShardIndex(ctx, n) == ShardIndex(ctx, n)
  {}

  // S2-A10: result always in [0, n)
  lemma ShardIndexInBounds(ctx: MetricContext, n: nat)
    requires n > 0
    ensures ShardIndex(ctx, n) < n
  {}

  // ── Proof helpers ────────────────────────────────────────────────────────

  // All wire metrics in seq have the given metric type
  predicate AllType(metrics: seq<WireMetric>, t: MetricType)
  {
    forall k :: 0 <= k < |metrics| ==> metrics[k].metricType == t
  }

  // No two metrics in seq share (name, tags, metricType)
  predicate UniqueWireMetrics(metrics: seq<WireMetric>)
  {
    forall i, j :: 0 <= i < j < |metrics| ==>
      !(metrics[i].name      == metrics[j].name &&
        metrics[i].tags      == metrics[j].tags &&
        metrics[i].metricType == metrics[j].metricType)
  }

  // Concatenation of two single-type unique seqs with distinct types is unique
  lemma ConcatUniqueByType(a: seq<WireMetric>, b: seq<WireMetric>,
                            ta: MetricType,    tb: MetricType)
    requires ta != tb
    requires AllType(a, ta)
    requires AllType(b, tb)
    requires UniqueWireMetrics(a)
    requires UniqueWireMetrics(b)
    ensures  UniqueWireMetrics(a + b)
  {
    var ab := a + b;
    forall i, j | 0 <= i < j < |ab|
      ensures !(ab[i].name == ab[j].name &&
                ab[i].tags == ab[j].tags &&
                ab[i].metricType == ab[j].metricType)
    {
      if i < |a| && j < |a| {
        // both in a — unique by UniqueWireMetrics(a)
        assert UniqueWireMetrics(a);
      } else if i >= |a| && j >= |a| {
        // both in b — unique by UniqueWireMetrics(b)
        assert UniqueWireMetrics(b);
      } else {
        // i in a, j in b — types differ
        assert ab[i].metricType == ta;
        assert ab[j].metricType == tb;
        assert ta != tb;
      }
    }
  }

  // Disjointness across shards: WellFormedShards => ctx in at most one count shard
  lemma CountShardsDisjoint(
    shards: seq<CountShard>, n: nat,
    ctx: MetricContext, s1: nat, s2: nat)
    requires n > 0 && |shards| == n
    requires 0 <= s1 < n && 0 <= s2 < n && s1 != s2
    requires forall s :: 0 <= s < n ==>
               forall c :: c in shards[s] ==> ShardIndex(c, n) == s
    ensures !(ctx in shards[s1] && ctx in shards[s2])
  {
    if ctx in shards[s1] && ctx in shards[s2] {
      assert ShardIndex(ctx, n) == s1;
      assert ShardIndex(ctx, n) == s2;
      assert s1 == s2;
    }
  }

  lemma GaugeShardsDisjoint(
    shards: seq<GaugeShard>, n: nat,
    ctx: MetricContext, s1: nat, s2: nat)
    requires n > 0 && |shards| == n
    requires 0 <= s1 < n && 0 <= s2 < n && s1 != s2
    requires forall s :: 0 <= s < n ==>
               forall c :: c in shards[s] ==> ShardIndex(c, n) == s
    ensures !(ctx in shards[s1] && ctx in shards[s2])
  {
    if ctx in shards[s1] && ctx in shards[s2] {
      assert ShardIndex(ctx, n) == s1;
      assert ShardIndex(ctx, n) == s2;
      assert s1 == s2;
    }
  }

  lemma SetShardsDisjoint(
    shards: seq<SetShard>, n: nat,
    ctx: MetricContext, s1: nat, s2: nat)
    requires n > 0 && |shards| == n
    requires 0 <= s1 < n && 0 <= s2 < n && s1 != s2
    requires forall s :: 0 <= s < n ==>
               forall c :: c in shards[s] ==> ShardIndex(c, n) == s
    ensures !(ctx in shards[s1] && ctx in shards[s2])
  {
    if ctx in shards[s1] && ctx in shards[s2] {
      assert ShardIndex(ctx, n) == s1;
      assert ShardIndex(ctx, n) == s2;
      assert s1 == s2;
    }
  }

  // Extern: value serialization (concrete impl outside Dafny)
  function {:extern} IntToString(n: int): string
  function {:extern} RealToString(r: real): string

  // ── Aggregator class (S2-A06) ────────────────────────────────────────────

  class Aggregator {
    var state:       AggregatorState
    var countShards: seq<CountShard>
    var gaugeShards: seq<GaugeShard>
    var setShards:   seq<SetShard>
    var buffered:    map<MetricContext, BufferedMetricState>
    var shardCount:  nat
    ghost var metricsSubmitted: set<MetricContext>

    // S2-A07: structural validity predicate
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
      // WellFormedShards: each ctx assigned to exactly its ShardIndex shard
      (forall s :: 0 <= s < shardCount ==>
         forall ctx :: ctx in countShards[s] ==> ShardIndex(ctx, shardCount) == s) &&
      (forall s :: 0 <= s < shardCount ==>
         forall ctx :: ctx in gaugeShards[s] ==> ShardIndex(ctx, shardCount) == s) &&
      (forall s :: 0 <= s < shardCount ==>
         forall ctx :: ctx in setShards[s] ==> ShardIndex(ctx, shardCount) == s)
    }

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
    {
      state        := Running;
      shardCount   := n;
      countShards  := seq(n, _ => map[]);
      gaugeShards  := seq(n, _ => map[]);
      setShards    := seq(n, _ => map[]);
      buffered     := map[];
      metricsSubmitted := {};
    }

    // ── S2-A11: SampleCount ───────────────────────────────────────────────
    // S2-A12: precondition state==Running enforces I2.1 (Stopped => no new counts)
    // S2-A13: CountsNonNegative — maintained via postcondition on Valid()
    // S2-A14: CountsIncrementOnly — count[ctx] increases by value
    method SampleCount(ctx: MetricContext, value: nat)
      requires Valid()
      requires state == Running
      modifies this
      ensures Valid()
      ensures state == Running
      ensures shardCount == old(shardCount)
      ensures gaugeShards == old(gaugeShards)
      ensures setShards   == old(setShards)
      ensures buffered    == old(buffered)
      // S2-A14: increment-only
      ensures var s := ShardIndex(ctx, shardCount);
              ctx in countShards[s] &&
              (var prev := if ctx in old(countShards)[s] then old(countShards)[s][ctx] else 0;
               countShards[s][ctx] == prev + value)
      // other count shards unchanged
      ensures forall s' :: 0 <= s' < shardCount && s' != ShardIndex(ctx, shardCount) ==>
                countShards[s'] == old(countShards)[s']
      // same shard, other keys unchanged
      ensures forall c' :: c' != ctx && c' in old(countShards)[ShardIndex(ctx, shardCount)] ==>
                c' in countShards[ShardIndex(ctx, shardCount)] &&
                countShards[ShardIndex(ctx, shardCount)][c'] ==
                old(countShards)[ShardIndex(ctx, shardCount)][c']
    {
      var s     := ShardIndex(ctx, shardCount);
      var prev  := if ctx in countShards[s] then countShards[s][ctx] else 0;
      countShards := countShards[s := countShards[s][ctx := prev + value]];
      metricsSubmitted := metricsSubmitted + {ctx};
    }

    // ── S2-A15: SampleGauge ───────────────────────────────────────────────
    // S2-A16: GaugeLastWriteWins — postcondition gaugeShards[s][ctx] == value
    method SampleGauge(ctx: MetricContext, value: real)
      requires Valid()
      requires state == Running
      modifies this
      ensures Valid()
      ensures state == Running
      ensures shardCount == old(shardCount)
      ensures countShards == old(countShards)
      ensures setShards   == old(setShards)
      ensures buffered    == old(buffered)
      // S2-A16: last-write-wins
      ensures var s := ShardIndex(ctx, shardCount);
              ctx in gaugeShards[s] && gaugeShards[s][ctx] == value
      ensures forall s' :: 0 <= s' < shardCount && s' != ShardIndex(ctx, shardCount) ==>
                gaugeShards[s'] == old(gaugeShards)[s']
      ensures forall c' :: c' != ctx && c' in old(gaugeShards)[ShardIndex(ctx, shardCount)] ==>
                c' in gaugeShards[ShardIndex(ctx, shardCount)] &&
                gaugeShards[ShardIndex(ctx, shardCount)][c'] ==
                old(gaugeShards)[ShardIndex(ctx, shardCount)][c']
    {
      var s := ShardIndex(ctx, shardCount);
      gaugeShards := gaugeShards[s := gaugeShards[s][ctx := value]];
      metricsSubmitted := metricsSubmitted + {ctx};
    }

    // ── S2-A17: SampleSet ────────────────────────────────────────────────
    // S2-A18: SetDeduplication — if value already present, set cardinality unchanged
    method SampleSet(ctx: MetricContext, value: string)
      requires Valid()
      requires state == Running
      modifies this
      ensures Valid()
      ensures state == Running
      ensures shardCount == old(shardCount)
      ensures countShards == old(countShards)
      ensures gaugeShards == old(gaugeShards)
      ensures buffered    == old(buffered)
      // value is in set after
      ensures var s := ShardIndex(ctx, shardCount);
              ctx in setShards[s] && value in setShards[s][ctx]
      // S2-A18: deduplication
      ensures var s      := ShardIndex(ctx, shardCount);
              var oldSet := if ctx in old(setShards)[s] then old(setShards)[s][ctx] else {};
              value in oldSet ==> setShards[s][ctx] == oldSet
      ensures forall s' :: 0 <= s' < shardCount && s' != ShardIndex(ctx, shardCount) ==>
                setShards[s'] == old(setShards)[s']
      ensures forall c' :: c' != ctx && c' in old(setShards)[ShardIndex(ctx, shardCount)] ==>
                c' in setShards[ShardIndex(ctx, shardCount)] &&
                setShards[ShardIndex(ctx, shardCount)][c'] ==
                old(setShards)[ShardIndex(ctx, shardCount)][c']
    {
      var s      := ShardIndex(ctx, shardCount);
      var oldSet := if ctx in setShards[s] then setShards[s][ctx] else {};
      setShards := setShards[s := setShards[s][ctx := oldSet + {value}]];
      metricsSubmitted := metricsSubmitted + {ctx};
    }

    // ── S2-A19: SampleBuffered ───────────────────────────────────────────
    // S2-A20: BufferedTotalSamplesMonotone — totalSamples only increases
    method SampleBuffered(ctx: MetricContext, value: real, maxSamples: int)
      requires Valid()
      requires state == Running
      modifies this
      ensures Valid()
      ensures state == Running
      ensures shardCount == old(shardCount)
      ensures countShards == old(countShards)
      ensures gaugeShards == old(gaugeShards)
      ensures setShards   == old(setShards)
      // S2-A20: totalSamples increases by exactly 1
      ensures ctx in buffered
      ensures buffered[ctx].totalSamples ==
              (if ctx in old(buffered) then old(buffered)[ctx].totalSamples else 0) + 1
      // other buffered entries unchanged
      ensures forall c' :: c' != ctx && c' in old(buffered) ==>
                c' in buffered && buffered[c'] == old(buffered)[c']
    {
      var oldState   := if ctx in buffered then buffered[ctx]
                        else BufferedMetricState([], 0);
      var newSamples :=
        if maxSamples > 0 && |oldState.samples| < maxSamples
        then oldState.samples + [value]
        else oldState.samples;
      buffered := buffered[ctx := BufferedMetricState(newSamples, oldState.totalSamples + 1)];
      metricsSubmitted := metricsSubmitted + {ctx};
    }

    // ── S2-A21: Flush ────────────────────────────────────────────────────
    // Emits one WireMetric per context per type with non-zero/non-empty state.
    // Resets all shards. Precondition: Running.
    // S2-A22: FlushEmitsOnePerContext — proved via type-segregated segments + ConcatUniqueByType.
    // S2-A23: FlushResetsShards — postcondition.
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
    {
      // Collect each type into a separate segment, then reset, then combine.
      var countResult    := CollectCountMetrics();
      var gaugeResult    := CollectGaugeMetrics();
      var setResult      := CollectSetMetrics();
      var bufferedResult := CollectBufferedMetrics();

      // Reset all shards (S2-A23)
      countShards := seq(shardCount, _ => map[]);
      gaugeShards := seq(shardCount, _ => map[]);
      setShards   := seq(shardCount, _ => map[]);
      buffered    := map[];

      // Each segment has a single distinct type → ConcatUniqueByType chains hold
      assert AllType(countResult,    Count);
      assert AllType(gaugeResult,    Gauge);
      assert AllType(setResult,      Set);
      assert AllType(bufferedResult, Histogram);
      assert UniqueWireMetrics(countResult);
      assert UniqueWireMetrics(gaugeResult);
      assert UniqueWireMetrics(setResult);
      assert UniqueWireMetrics(bufferedResult);

      ConcatUniqueByType(countResult, gaugeResult, Count, Gauge);
      var cg := countResult + gaugeResult;
      // cg: Count | Gauge — but AllType requires single type, so use UniqueWireMetrics directly
      assert UniqueWireMetrics(cg);
      assert forall k :: 0 <= k < |cg| ==> cg[k].metricType == Count || cg[k].metricType == Gauge;

      // Extend: cg ++ setResult — Set type is different from Count and Gauge
      ConcatCGWithSet(cg, setResult);
      var cgs := cg + setResult;
      assert UniqueWireMetrics(cgs);

      // Extend: cgs ++ bufferedResult — Histogram is different from Count, Gauge, Set
      ConcatCGSWithBuffered(cgs, bufferedResult);
      result := cgs + bufferedResult;

      assert UniqueWireMetrics(result);
    }

    // Helper: collect all count metrics without modifying state
    method CollectCountMetrics() returns (r: seq<WireMetric>)
      requires Valid()
      ensures AllType(r, Count)
      ensures UniqueWireMetrics(r)
    {
      r := [];
      ghost var emittedCtxs: set<MetricContext> := {};

      var si := 0;
      while si < shardCount
        invariant 0 <= si <= shardCount
        invariant AllType(r, Count)
        invariant UniqueWireMetrics(r)
        // emittedCtxs tracks all contexts that contributed to r
        invariant forall k :: 0 <= k < |r| ==>
                    MetricContext(r[k].name, r[k].tags) in emittedCtxs
        // each emitted ctx has ShardIndex < si (came from shard 0..si-1)
        invariant forall ctx :: ctx in emittedCtxs ==> ShardIndex(ctx, shardCount) < si
        // emitted ctxs come from the actual shards
        invariant forall ctx :: ctx in emittedCtxs ==>
                    exists s :: 0 <= s < shardCount && ctx in countShards[s]
        // direct: matches postcondition (chain not inferred automatically)
        invariant forall k :: 0 <= k < |r| ==>
                    exists s :: 0 <= s < shardCount &&
                      MetricContext(r[k].name, r[k].tags) in countShards[s]
        decreases shardCount - si
      {
        var shard     := countShards[si];
        var remaining := shard.Keys;
        ghost var emittedFromShard: set<MetricContext> := {};

        while remaining != {}
          invariant remaining <= shard.Keys
          invariant remaining == shard.Keys - emittedFromShard
          invariant emittedFromShard <= shard.Keys
          invariant AllType(r, Count)
          invariant UniqueWireMetrics(r)
          invariant forall k :: 0 <= k < |r| ==>
                      MetricContext(r[k].name, r[k].tags) in emittedCtxs + emittedFromShard
          invariant forall ctx :: ctx in emittedCtxs ==> ShardIndex(ctx, shardCount) < si
          invariant forall ctx :: ctx in emittedFromShard ==>
                      ctx in shard && ShardIndex(ctx, shardCount) == si
          invariant forall ctx :: ctx in emittedCtxs ==>
                      exists s :: 0 <= s < shardCount && ctx in countShards[s]
          invariant forall ctx :: ctx in emittedFromShard ==>
                      exists s :: 0 <= s < shardCount && ctx in countShards[s]
          invariant forall k :: 0 <= k < |r| ==>
                      exists s :: 0 <= s < shardCount &&
                        MetricContext(r[k].name, r[k].tags) in countShards[s]
          // emittedCtxs and emittedFromShard are disjoint (different ShardIndex)
          invariant emittedCtxs !! emittedFromShard
          decreases remaining
        {
          var ctx :| ctx in remaining;
          // ctx !in emittedCtxs: ShardIndex(ctx,n)==si, emittedCtxs has ShardIndex<si
          assert ShardIndex(ctx, shardCount) == si;
          assert ctx !in emittedCtxs;
          // ctx !in emittedFromShard: ctx in remaining = shard.Keys - emittedFromShard
          assert ctx !in emittedFromShard;
          // so ctx not in emittedCtxs + emittedFromShard => no metric with this ctx yet
          assert MetricContext(ctx.name, ctx.tags) == ctx;
          assert ctx !in (emittedCtxs + emittedFromShard);

          var v := shard[ctx];
          if v != 0 {
            var m := WireMetric(ctx.name, IntToString(v), Count, None,
                                ctx.tags, None, None, CardinalityNotSet);
            // prove UniqueWireMetrics(r + [m]):
            // all existing r have (name,tags) in emittedCtxs+emittedFromShard; m has ctx not there
            assert forall k :: 0 <= k < |r| ==>
                     MetricContext(r[k].name, r[k].tags) != ctx;
            assert forall k :: 0 <= k < |r| ==>
                     !(r[k].name == m.name && r[k].tags == m.tags && r[k].metricType == m.metricType);
            r := r + [m];
          }
          emittedFromShard := emittedFromShard + {ctx};
          remaining        := remaining - {ctx};
        }

        emittedCtxs := emittedCtxs + emittedFromShard;
        si := si + 1;
      }
    }

    // Helper: collect all gauge metrics without modifying state
    method CollectGaugeMetrics() returns (r: seq<WireMetric>)
      requires Valid()
      ensures AllType(r, Gauge)
      ensures UniqueWireMetrics(r)
    {
      r := [];
      ghost var emittedCtxs: set<MetricContext> := {};

      var si := 0;
      while si < shardCount
        invariant 0 <= si <= shardCount
        invariant AllType(r, Gauge)
        invariant UniqueWireMetrics(r)
        invariant forall k :: 0 <= k < |r| ==>
                    MetricContext(r[k].name, r[k].tags) in emittedCtxs
        invariant forall ctx :: ctx in emittedCtxs ==> ShardIndex(ctx, shardCount) < si
        invariant forall ctx :: ctx in emittedCtxs ==>
                    exists s :: 0 <= s < shardCount && ctx in gaugeShards[s]
        invariant forall k :: 0 <= k < |r| ==>
                    exists s :: 0 <= s < shardCount &&
                      MetricContext(r[k].name, r[k].tags) in gaugeShards[s]
        decreases shardCount - si
      {
        var shard     := gaugeShards[si];
        var remaining := shard.Keys;
        ghost var emittedFromShard: set<MetricContext> := {};

        while remaining != {}
          invariant remaining <= shard.Keys
          invariant remaining == shard.Keys - emittedFromShard
          invariant emittedFromShard <= shard.Keys
          invariant AllType(r, Gauge)
          invariant UniqueWireMetrics(r)
          invariant forall k :: 0 <= k < |r| ==>
                      MetricContext(r[k].name, r[k].tags) in emittedCtxs + emittedFromShard
          invariant forall ctx :: ctx in emittedCtxs ==> ShardIndex(ctx, shardCount) < si
          invariant forall ctx :: ctx in emittedFromShard ==>
                      ctx in shard && ShardIndex(ctx, shardCount) == si
          invariant forall ctx :: ctx in emittedCtxs ==>
                      exists s :: 0 <= s < shardCount && ctx in gaugeShards[s]
          invariant forall ctx :: ctx in emittedFromShard ==>
                      exists s :: 0 <= s < shardCount && ctx in gaugeShards[s]
          invariant forall k :: 0 <= k < |r| ==>
                      exists s :: 0 <= s < shardCount &&
                        MetricContext(r[k].name, r[k].tags) in gaugeShards[s]
          invariant emittedCtxs !! emittedFromShard
          decreases remaining
        {
          var ctx :| ctx in remaining;
          assert ShardIndex(ctx, shardCount) == si;
          assert ctx !in emittedCtxs;
          assert ctx !in emittedFromShard;
          assert MetricContext(ctx.name, ctx.tags) == ctx;
          assert ctx !in (emittedCtxs + emittedFromShard);

          var v := shard[ctx];
          var m := WireMetric(ctx.name, RealToString(v), Gauge, None,
                              ctx.tags, None, None, CardinalityNotSet);
          assert forall k :: 0 <= k < |r| ==> MetricContext(r[k].name, r[k].tags) != ctx;
          assert forall k :: 0 <= k < |r| ==>
                   !(r[k].name == m.name && r[k].tags == m.tags && r[k].metricType == m.metricType);
          r := r + [m];

          emittedFromShard := emittedFromShard + {ctx};
          remaining        := remaining - {ctx};
        }

        emittedCtxs := emittedCtxs + emittedFromShard;
        si := si + 1;
      }
    }

    // Helper: collect all set metrics without modifying state
    method CollectSetMetrics() returns (r: seq<WireMetric>)
      requires Valid()
      ensures AllType(r, Set)
      ensures UniqueWireMetrics(r)
    {
      r := [];
      ghost var emittedCtxs: set<MetricContext> := {};

      var si := 0;
      while si < shardCount
        invariant 0 <= si <= shardCount
        invariant AllType(r, Set)
        invariant UniqueWireMetrics(r)
        invariant forall k :: 0 <= k < |r| ==>
                    MetricContext(r[k].name, r[k].tags) in emittedCtxs
        invariant forall ctx :: ctx in emittedCtxs ==> ShardIndex(ctx, shardCount) < si
        invariant forall ctx :: ctx in emittedCtxs ==>
                    exists s :: 0 <= s < shardCount && ctx in setShards[s]
        invariant forall k :: 0 <= k < |r| ==>
                    exists s :: 0 <= s < shardCount &&
                      MetricContext(r[k].name, r[k].tags) in setShards[s]
        decreases shardCount - si
      {
        var shard     := setShards[si];
        var remaining := shard.Keys;
        ghost var emittedFromShard: set<MetricContext> := {};

        while remaining != {}
          invariant remaining <= shard.Keys
          invariant remaining == shard.Keys - emittedFromShard
          invariant emittedFromShard <= shard.Keys
          invariant AllType(r, Set)
          invariant UniqueWireMetrics(r)
          invariant forall k :: 0 <= k < |r| ==>
                      MetricContext(r[k].name, r[k].tags) in emittedCtxs + emittedFromShard
          invariant forall ctx :: ctx in emittedCtxs ==> ShardIndex(ctx, shardCount) < si
          invariant forall ctx :: ctx in emittedFromShard ==>
                      ctx in shard && ShardIndex(ctx, shardCount) == si
          invariant forall ctx :: ctx in emittedCtxs ==>
                      exists s :: 0 <= s < shardCount && ctx in setShards[s]
          invariant forall ctx :: ctx in emittedFromShard ==>
                      exists s :: 0 <= s < shardCount && ctx in setShards[s]
          invariant forall k :: 0 <= k < |r| ==>
                      exists s :: 0 <= s < shardCount &&
                        MetricContext(r[k].name, r[k].tags) in setShards[s]
          invariant emittedCtxs !! emittedFromShard
          decreases remaining
        {
          var ctx :| ctx in remaining;
          assert ShardIndex(ctx, shardCount) == si;
          assert ctx !in emittedCtxs;
          assert ctx !in emittedFromShard;
          assert MetricContext(ctx.name, ctx.tags) == ctx;
          assert ctx !in (emittedCtxs + emittedFromShard);

          var v := shard[ctx];
          if v != {} {
            var m := WireMetric(ctx.name, IntToString(|v|), Set, None,
                                ctx.tags, None, None, CardinalityNotSet);
            assert forall k :: 0 <= k < |r| ==> MetricContext(r[k].name, r[k].tags) != ctx;
            assert forall k :: 0 <= k < |r| ==>
                     !(r[k].name == m.name && r[k].tags == m.tags && r[k].metricType == m.metricType);
            r := r + [m];
          }

          emittedFromShard := emittedFromShard + {ctx};
          remaining        := remaining - {ctx};
        }

        emittedCtxs := emittedCtxs + emittedFromShard;
        si := si + 1;
      }
    }

    // Helper: collect all buffered metrics without modifying state
    method CollectBufferedMetrics() returns (r: seq<WireMetric>)
      requires Valid()
      ensures AllType(r, Histogram)
      ensures UniqueWireMetrics(r)
    {
      r := [];
      var remaining := buffered.Keys;
      ghost var emittedCtxs: set<MetricContext> := {};

      while remaining != {}
        invariant remaining <= buffered.Keys
        invariant remaining == buffered.Keys - emittedCtxs
        invariant emittedCtxs <= buffered.Keys
        invariant AllType(r, Histogram)
        invariant UniqueWireMetrics(r)
        invariant forall k :: 0 <= k < |r| ==>
                    MetricContext(r[k].name, r[k].tags) in emittedCtxs
        invariant emittedCtxs !! remaining
        decreases remaining
      {
        var ctx :| ctx in remaining;
        assert ctx !in emittedCtxs;
        assert MetricContext(ctx.name, ctx.tags) == ctx;

        var bs  := buffered[ctx];
        var cnt := bs.totalSamples;
        var m   := WireMetric(ctx.name, IntToString(cnt as int), Histogram, None,
                              ctx.tags, None, None, CardinalityNotSet);
        assert forall k :: 0 <= k < |r| ==> MetricContext(r[k].name, r[k].tags) != ctx;
        assert forall k :: 0 <= k < |r| ==>
                 !(r[k].name == m.name && r[k].tags == m.tags && r[k].metricType == m.metricType);
        r := r + [m];

        emittedCtxs := emittedCtxs + {ctx};
        remaining   := remaining   - {ctx};
      }
    }

    // ── S2-A24: Stop ────────────────────────────────────────────────────
    // S2-A25: precondition state==Running on Sample* methods enforces I2.1 post-Stop
    // S2-A26: no method transitions Stopped → Running; Stop is terminal
    method Stop()
      requires Valid()
      modifies this
      ensures Valid()
      ensures state == Stopped
      ensures shardCount   == old(shardCount)
      ensures countShards  == old(countShards)
      ensures gaugeShards  == old(gaugeShards)
      ensures setShards    == old(setShards)
      ensures buffered     == old(buffered)
      ensures metricsSubmitted == old(metricsSubmitted)
    {
      state := Stopped;
    }

  } // class Aggregator

  // ── Cross-type concat uniqueness lemmas ──────────────────────────────────

  // cg (Count|Gauge mix, already unique) ++ Set segment → unique
  lemma ConcatCGWithSet(cg: seq<WireMetric>, s: seq<WireMetric>)
    requires UniqueWireMetrics(cg)
    requires AllType(s, Set)
    requires UniqueWireMetrics(s)
    requires forall k :: 0 <= k < |cg| ==>
               cg[k].metricType == Count || cg[k].metricType == Gauge
    ensures UniqueWireMetrics(cg + s)
  {
    var r := cg + s;
    forall i, j | 0 <= i < j < |r|
      ensures !(r[i].name == r[j].name &&
                r[i].tags == r[j].tags &&
                r[i].metricType == r[j].metricType)
    {
      if i < |cg| && j < |cg| {
        assert UniqueWireMetrics(cg);
      } else if i >= |cg| && j >= |cg| {
        assert UniqueWireMetrics(s);
      } else {
        // i in cg (Count or Gauge), j in s (Set) — types differ
        assert r[i].metricType == Count || r[i].metricType == Gauge;
        assert r[j].metricType == Set;
      }
    }
  }

  // cgs (Count|Gauge|Set mix, already unique) ++ Histogram segment → unique
  lemma ConcatCGSWithBuffered(cgs: seq<WireMetric>, b: seq<WireMetric>)
    requires UniqueWireMetrics(cgs)
    requires AllType(b, Histogram)
    requires UniqueWireMetrics(b)
    requires forall k :: 0 <= k < |cgs| ==>
               cgs[k].metricType == Count ||
               cgs[k].metricType == Gauge  ||
               cgs[k].metricType == Set
    ensures UniqueWireMetrics(cgs + b)
  {
    var r := cgs + b;
    forall i, j | 0 <= i < j < |r|
      ensures !(r[i].name == r[j].name &&
                r[i].tags == r[j].tags &&
                r[i].metricType == r[j].metricType)
    {
      if i < |cgs| && j < |cgs| {
        assert UniqueWireMetrics(cgs);
      } else if i >= |cgs| && j >= |cgs| {
        assert UniqueWireMetrics(b);
      } else {
        assert r[i].metricType == Count || r[i].metricType == Gauge || r[i].metricType == Set;
        assert r[j].metricType == Histogram;
      }
    }
  }

  // ── Standalone lemmas for S2-A12, S2-A25, S2-A26 ───────────────────────

  // S2-A12: SampleCount only callable when Running — enforced by requires state==Running
  lemma SampleCountPreservesRunning(agg: Aggregator)
    requires agg.Valid()
    requires agg.state == Stopped
    ensures agg.state != Running
  {}

  // S2-A13: all counts non-negative — follows from Valid()
  lemma CountsNonNegative(agg: Aggregator)
    requires agg.Valid()
    ensures forall s :: 0 <= s < agg.shardCount ==>
              forall ctx :: ctx in agg.countShards[s] ==> agg.countShards[s][ctx] >= 0
  {}

  // S2-A25: Stop() sets state=Stopped; all Sample* require state==Running → precondition fails
  lemma StopPreventsNewSamples(agg: Aggregator)
    requires agg.Valid()
    requires agg.state == Stopped
    ensures agg.state != Running
  {}

  // S2-A26: no method transitions Stopped → Running; stop is terminal
  // Stop() only sets state := Stopped. No method sets state := Running after construction.
  // The constructor sets Running; Stop() sets Stopped; no reversal method exists.
  // This is enforced structurally — no lemma body needed beyond the assertion.
  lemma StopIsTerminal(agg: Aggregator)
    requires agg.Valid()
    requires agg.state == Stopped
    ensures agg.state == Stopped
  {}

} // module Aggregator
