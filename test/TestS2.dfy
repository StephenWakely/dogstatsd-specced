// test/TestS2.dfy — T-S2-01 through T-S2-06: Aggregator runtime tests
// Spec: allium.md §Part 2 (S2)
include "../src/Aggregator.dfy"

module TestS2 {

  import opened Aggregator
  import opened Types

  // T-S2-01: SampleCount on same context twice → value is sum of both increments
  method {:test} TestSampleCountAccumulates()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("requests", ["env:prod"]);
    agg.SampleCount(ctx, 3);
    agg.SampleCount(ctx, 5);
    var s := ShardIndex(ctx, agg.shardCount);
    expect ctx in agg.countShards[s];
    expect agg.countShards[s][ctx] == 8;
  }

  // T-S2-02: SampleGauge last-write-wins — second write replaces first
  method {:test} TestSampleGaugeLastWriteWins()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("cpu", ["host:a"]);
    agg.SampleGauge(ctx, 0.5);
    agg.SampleGauge(ctx, 0.9);
    var s := ShardIndex(ctx, agg.shardCount);
    expect ctx in agg.gaugeShards[s];
    expect agg.gaugeShards[s][ctx] == 0.9;
  }

  // T-S2-03: SampleSet deduplication — adding same value twice leaves set size == 1
  method {:test} TestSampleSetDeduplication()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("users", []);
    agg.SampleSet(ctx, "alice");
    agg.SampleSet(ctx, "alice");
    var s := ShardIndex(ctx, agg.shardCount);
    expect ctx in agg.setShards[s];
    expect |agg.setShards[s][ctx]| == 1;
  }

  // T-S2-04: SampleBuffered — totalSamples monotone; reservoir cap respected
  method {:test} TestSampleBufferedMonotoneAndCap()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("latency", []);
    // First sample: below cap of 2 → appended
    agg.SampleBuffered(ctx, 1.0, 2);
    expect ctx in agg.buffered;
    expect agg.buffered[ctx].totalSamples == 1;
    expect agg.buffered[ctx].samples == [1.0];
    // Second sample: still below cap → appended
    agg.SampleBuffered(ctx, 2.0, 2);
    expect agg.buffered[ctx].totalSamples == 2;
    expect agg.buffered[ctx].samples == [1.0, 2.0];
    // Third sample: at cap → samples seq unchanged, totalSamples still increments
    agg.SampleBuffered(ctx, 3.0, 2);
    expect agg.buffered[ctx].totalSamples == 3;
    expect |agg.buffered[ctx].samples| == 2;
  }

  // T-S2-05: Flush resets all shards; UniqueWireMetrics is a Dafny postcondition (compile-time proof).
  // Externs IntToString/RealToString are not invoked: count=0 is filtered by `if v != 0`
  // in CollectCountMetrics; gaugeShards and setShards are left empty; buffered is empty.
  method {:test} TestFlushResetsShards()
  {
    var agg := new Aggregator.New(2);
    var c1  := MetricContext("hits", ["env:prod"]);
    // SampleCount with value=0 → shard contains c1 with count 0, but CollectCountMetrics
    // skips emission (if v != 0 guard), so IntToString never called at runtime.
    agg.SampleCount(c1, 0);
    var s1 := ShardIndex(c1, agg.shardCount);
    expect c1 in agg.countShards[s1];
    var result := agg.Flush();
    // all shards reset after Flush (S2-A23)
    expect forall s :: 0 <= s < agg.shardCount ==> agg.countShards[s] == map[];
    expect forall s :: 0 <= s < agg.shardCount ==> agg.gaugeShards[s] == map[];
    expect forall s :: 0 <= s < agg.shardCount ==> agg.setShards[s] == map[];
    expect agg.buffered == map[];
    // result is empty (zero count filtered) → trivially unique
    expect |result| == 0;
  }

  // T-S2-06: Stop disables SampleCount — postcondition state==Stopped is provable;
  // calling SampleCount after Stop() would fail verification (requires state==Running).
  // This test confirms Stop() sets state to Stopped at runtime.
  method {:test} TestStopSetsStateStopped()
  {
    var agg := new Aggregator.New(1);
    expect agg.state == Running;
    agg.Stop();
    expect agg.state == Stopped;
    // SampleCount(ctx, 1) here is intentionally omitted — it would fail the
    // requires state==Running precondition check at verification time.
  }

}
