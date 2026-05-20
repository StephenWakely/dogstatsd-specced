// test/TestS1.dfy — T-S1-01 through T-S1-08: Client lifecycle tests
// Spec: allium.md §Part 1 (S1)
include "../src/Client.dfy"

module TestS1 {

  import opened Client
  import opened Types
  import opened Errors
  import opened Buffer

  // T-S1-01: Client.New returns client with state == Open
  method {:test} TestNewClientIsOpen()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    expect c.state == Open;
  }

  // T-S1-02: SubmitGauge returns Ok when state == Open
  method {:test} TestGaugeOnOpenSucceeds()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    var ctx := MetricContext("cpu", []);
    var r := c.SubmitGauge(ctx, 1.5, 1.0);
    expect r == Ok(Unit);
  }

  // T-S1-03: SubmitGauge returns Err(ErrNoClient) after Close()
  method {:test} TestGaugeOnClosedReturnsError()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    var ctx := MetricContext("cpu", []);
    var _ := c.Close();
    var r := c.SubmitGauge(ctx, 1.5, 1.0);
    expect r == Err(ErrNoClient);
  }

  // T-S1-04: second Close() call leaves state == Closed (idempotent state)
  method {:test} TestCloseIdempotent()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    var r1 := c.Close();
    expect r1 == Ok(Unit);
    expect c.state == Closed;
    // second Close returns ErrNoClient but state stays Closed
    var r2 := c.Close();
    expect c.state == Closed;
    expect r2 == Err(ErrNoClient);   // restore: Close() postcondition guarantees this
  }

  // T-S1-04b: Close() returns Err(ErrNoClient) on every subsequent call — error value explicit
  method {:test} TestCloseIdempotentReturnsErrNoClient()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    var r1 := c.Close();
    expect r1 == Ok(Unit);
    // S1-C15 postcondition: old(state)==Closed ==> r==Err(ErrNoClient)
    var r2 := c.Close();
    expect r2 == Err(ErrNoClient);
    // third call also returns error — not just second
    var r3 := c.Close();
    expect r3 == Err(ErrNoClient);
  }

  // T-S1-05: IsClosed() returns false before Close(), true after
  method {:test} TestIsClosedReflectsState()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    expect !c.IsClosed();
    var _ := c.Close();
    expect c.IsClosed();
  }

  // T-S1-06: Flush() returns Ok when state == Open
  method {:test} TestFlushOnOpenSendsPending()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    var r := c.Flush();
    expect r == Ok(Unit);
  }

  // T-S1-07: Flush() returns Err(ErrNoClient) when state == Closed
  method {:test} TestFlushOnClosedReturnsError()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    var _ := c.Close();
    var r := c.Flush();
    expect r == Err(ErrNoClient);
  }

  // T-S1-08: all six Submit* methods return ErrNoClient when Closed
  method {:test} TestAllMetricTypesOnClosed()
  {
    var cfg := DefaultConfig();
    var c := new Client.New(cfg);
    var ctx := MetricContext("m", []);
    var _ := c.Close();
    var r1 := c.SubmitGauge(ctx, 1.0, 1.0);
    var r2 := c.SubmitCount(ctx, 1, 1.0);
    var r3 := c.SubmitSet(ctx, "v", 1.0);
    var r4 := c.SubmitHistogram(ctx, 1.0, 1.0);
    var r5 := c.SubmitDistribution(ctx, 1.0, 1.0);
    var r6 := c.SubmitTiming(ctx, 1.0, 1.0);
    expect r1 == Err(ErrNoClient);
    expect r2 == Err(ErrNoClient);
    expect r3 == Err(ErrNoClient);
    expect r4 == Err(ErrNoClient);
    expect r5 == Err(ErrNoClient);
    expect r6 == Err(ErrNoClient);
  }

}
