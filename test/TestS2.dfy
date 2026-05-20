// test/TestS2.dfy — T-S2-01 through T-S2-07: Aggregator runtime tests
// Spec: allium.md §Part 2 (S2)
include "../src/Aggregator.dfy"

module TestS2 {

  import opened Aggregator
  import opened Types

  // T-S2-01: counts accumulate — two SampleCount calls sum, not overwrite
  method {:test} TestCountAccumulates()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("requests", ["env:prod"]);
    agg.SampleCount(ctx, 3);
    agg.SampleCount(ctx, 5);
    var s := ShardIndex(ctx, agg.shardCount);
    expect ctx in agg.countShards[s];
    expect agg.countShards[s][ctx] == 8;
  }

  // T-S2-02: gauge last-write-wins — second write replaces first (not accumulated sum)
  method {:test} TestGaugeOverwrites()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("cpu", ["host:a"]);
    agg.SampleGauge(ctx, 1.0);
    agg.SampleGauge(ctx, 2.0);
    var s := ShardIndex(ctx, agg.shardCount);
    expect ctx in agg.gaugeShards[s];
    expect agg.gaugeShards[s][ctx] == 2.0;  // last write wins
    expect agg.gaugeShards[s][ctx] != 3.0;  // not accumulated 1.0 + 2.0
  }

  // T-S2-03: set deduplication — same value added twice appears exactly once
  method {:test} TestSetDeduplicates()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("users", []);
    agg.SampleSet(ctx, "foo");
    agg.SampleSet(ctx, "foo");
    var s := ShardIndex(ctx, agg.shardCount);
    expect ctx in agg.setShards[s];
    expect "foo" in agg.setShards[s][ctx];
    expect |agg.setShards[s][ctx]| == 1;
  }

  // T-S2-04: flush emits one entry per (ctx, type) — multiple samples on same ctx → one result (I2.2)
  //          also verifies FlushResetsShards (S2-A23): all shards empty after flush
  method {:test} TestFlushEmitsOnePerContext()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("hits", ["env:prod"]);
    agg.SampleCount(ctx, 1);
    agg.SampleCount(ctx, 2);
    agg.SampleCount(ctx, 3);
    var result := agg.Flush();
    // Three counts on one context → exactly one Count entry in result
    expect |result| == 1;
    expect result[0].name       == ctx.name;
    expect result[0].tags       == ctx.tags;
    expect result[0].metricType == Count;
    // S2-A23: all shards reset after flush
    var s := 0;
    while s < agg.shardCount
      decreases agg.shardCount - s
    {
      expect agg.countShards[s] == map[];
      expect agg.gaugeShards[s] == map[];
      expect agg.setShards[s]   == map[];
      s := s + 1;
    }
  }

  // TestShardingInBounds is not a runtime test — it's covered by the compile-time proof
  // lemma ShardIndexInBounds in Aggregator.dfy (S2-A10), which Dafny verifies statically.
  // A {:test} version would only redundantly re-check what the proof already guarantees.

  // T-S2-06: Stop disables SampleCount — postcondition state==Stopped is provable;
  // calling SampleCount after Stop() would fail verification (requires state==Running).
  // This test confirms Stop() sets state to Stopped at runtime.
  method {:test} TestStopSetsStateStopped()
  {
    var agg := new Aggregator.New(1);
    var ctx := MetricContext("reqs", []);
    agg.SampleCount(ctx, 1);
    expect agg.state == Running;
    agg.Stop();
    expect agg.state == Stopped;
    // SampleCount(ctx, 1) here would fail requires state==Running at verification time.
  }

  // T-S2-06: ShardIndex in-bounds — result in [0, n) for distinct contexts (behavioral)
  method {:test} TestShardingInBounds()
  {
    var n := 8;
    var ctx1 := MetricContext("orders",  ["region:us"]);
    var ctx2 := MetricContext("errors",  ["region:eu"]);
    var ctx3 := MetricContext("latency", ["service:api"]);
    var idx1 := ShardIndex(ctx1, n);
    var idx2 := ShardIndex(ctx2, n);
    var idx3 := ShardIndex(ctx3, n);
    expect 0 <= idx1 < n;
    expect 0 <= idx2 < n;
    expect 0 <= idx3 < n;
  }

  // T-S2-07: SampleBuffered reservoir cap — below cap appends, at cap keeps samples unchanged,
  //           totalSamples increments in both cases (R2.4, I2.6)
  method {:test} TestSampleBufferedReservoir()
  {
    var agg := new Aggregator.New(4);
    var ctx := MetricContext("latency", ["service:web"]);
    var cap := 3;

    // Below cap: each sample appends
    agg.SampleBuffered(ctx, 1.0, cap);
    expect ctx in agg.buffered;
    expect agg.buffered[ctx].totalSamples == 1;
    expect agg.buffered[ctx].samples == [1.0];

    agg.SampleBuffered(ctx, 2.0, cap);
    expect agg.buffered[ctx].totalSamples == 2;
    expect agg.buffered[ctx].samples == [1.0, 2.0];

    agg.SampleBuffered(ctx, 3.0, cap);
    expect agg.buffered[ctx].totalSamples == 3;
    expect agg.buffered[ctx].samples == [1.0, 2.0, 3.0];

    // At cap: samples unchanged, totalSamples still increments
    agg.SampleBuffered(ctx, 4.0, cap);
    expect agg.buffered[ctx].totalSamples == 4;
    expect agg.buffered[ctx].samples == [1.0, 2.0, 3.0];
  }

}
