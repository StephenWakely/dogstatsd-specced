// test/TestS2.dfy — T-S2-01 through T-S2-06: Aggregator runtime tests
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

  // T-S2-04: flush emits one entry per (ctx, type) — multiple samples on same ctx produce one result (I2.2)
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
  }

  // T-S2-05: Stop() prevents further samples — state is Stopped; SampleCount requires Running
  method {:test} TestStopPreventsFurtherSamples()
  {
    var agg := new Aggregator.New(1);
    var ctx := MetricContext("reqs", []);
    agg.SampleCount(ctx, 1);
    expect agg.state == Running;
    agg.Stop();
    expect agg.state == Stopped;
    // SampleCount(ctx, 1) here would fail requires state==Running at verification time.
  }

  // T-S2-06: ShardIndex is deterministic — same ctx and n always returns same shard
  method {:test} TestShardingIsDeterministic()
  {
    var ctx  := MetricContext("orders", ["region:us"]);
    var n    := 8;
    var idx1 := ShardIndex(ctx, n);
    var idx2 := ShardIndex(ctx, n);
    expect idx1 == idx2;
  }

}
