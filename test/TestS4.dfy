// test/TestS4.dfy — T-S4-01 through T-S4-07: sender tests
// Spec: allium.md §Part 4 (S4)
include "../src/Sender.dfy"

module TestS4 {

  import S = Sender
  import Buf = Buffer
  import opened Errors
  import opened Types

  // Concrete Transport for tests — non-ghost writes/closes counters observable in expect
  @AssumeCrossModuleTermination
  class MockTransport extends S.Transport {
    var writes: nat
    var closes: nat

    constructor()
      ensures !closed
      ensures closeCount == 0
      ensures writeCount == 0
      ensures writes == 0
      ensures closes == 0
    {
      closed     := false;
      closeCount := 0;
      writeCount := 0;
      writes     := 0;
      closes     := 0;
    }

    method Write(data: seq<byte>) returns (r: Result<nat>)
      modifies this
      ensures !closed
      ensures writeCount == old(writeCount) + 1
      ensures closeCount == old(closeCount)
      ensures writes == old(writes) + 1
      ensures closes == old(closes)
    {
      writeCount := writeCount + 1;
      writes     := writes + 1;
      r          := Ok(|data|);
      closed     := false;
    }

    method Close()
      modifies this
      ensures closed
      ensures closeCount == old(closeCount) + 1
      ensures writeCount == old(writeCount)
      ensures writes == old(writes)
      ensures closes == old(closes) + 1
    {
      closed     := true;
      closeCount := closeCount + 1;
      closes     := closes + 1;
    }
  }

  // T-S4-01: Enqueue on Running sender with |queue| < maxQueueSize returns Ok; |queue| increases
  method {:test} TestEnqueueSucceedsIfQueueOpen()
  {
    var s   := new S.Sender.New(5);
    var buf := new Buf.Buffer.New(64, 8);
    var oldLen := |s.queue|;
    var r := s.Enqueue(buf);
    expect r.Ok?;
    expect |s.queue| == oldLen + 1;
  }

  // T-S4-02: Enqueue when |queue| == maxQueueSize returns Err; queue unchanged (I4.1)
  method {:test} TestEnqueueDropsIfQueueFull()
  {
    var s    := new S.Sender.New(1);
    var buf1 := new Buf.Buffer.New(64, 8);
    var buf2 := new Buf.Buffer.New(64, 8);
    var r1   := s.Enqueue(buf1);
    expect r1.Ok?;
    var oldLen := |s.queue|;
    var r2     := s.Enqueue(buf2);
    expect r2.Err?;
    expect |s.queue| == oldLen;
    expect r2 == Err(ErrorSenderChannelFull);
  }

  // T-S4-03: Dropped Enqueue increments payloadsDroppedQueueFull by 1
  method {:test} TestTelemetryIncrementsOnDrop()
  {
    var s      := new S.Sender.New(0);  // capacity 0 — every Enqueue drops
    var buf    := new Buf.Buffer.New(64, 8);
    var oldDrops := s.telemetry.payloadsDroppedQueueFull;
    var r      := s.Enqueue(buf);
    expect r.Err?;
    expect s.telemetry.payloadsDroppedQueueFull == oldDrops + 1;
  }

  // T-S4-04: Send calls transport.Write exactly once per buffer regardless of result (I4.2)
  method {:test} TestSendNoRetry()
  {
    var s         := new S.Sender.New(5);
    var buf       := new Buf.Buffer.New(64, 8);
    var r1        := s.Enqueue(buf);
    expect r1.Ok?;                        // expect gives verifier the fact r1.Ok?
    var transport := new MockTransport();
    var r         := s.Send(transport);
    expect transport.writes == 1;
  }

  // T-S4-05: After Stop(), |queue| == 0
  method {:test} TestStopDrainsQueue()
  {
    var s         := new S.Sender.New(5);
    var buf1      := new Buf.Buffer.New(64, 8);
    var buf2      := new Buf.Buffer.New(64, 8);
    var transport := new MockTransport();
    var r1        := s.Enqueue(buf1);
    expect r1.Ok?;
    var r2        := s.Enqueue(buf2);
    expect r2.Ok?;
    // Verification hints: both bufs valid, both disjoint from transport
    assert buf1.Valid();
    assert buf2.Valid();
    assert (buf1 as object) != (transport as object);
    assert (buf2 as object) != (transport as object);
    s.Stop(transport);
    expect |s.queue| == 0;
  }

  // T-S4-06: transport.Close() called exactly once during Stop() (I4.4)
  method {:test} TestTransportCloseCalledOnStop()
  {
    var s         := new S.Sender.New(5);
    var transport := new MockTransport();
    s.Stop(transport);
    expect transport.closes == 1;
  }

  // T-S4-07: Repeated Enqueue calls never push |queue| above maxQueueSize
  method {:test} TestQueueNeverOverflows()
  {
    var s := new S.Sender.New(3);
    var i: nat := 0;
    while i < 6
      invariant s.Valid()
      invariant s.state == S.Running
      invariant |s.queue| <= s.maxQueueSize
      decreases 6 - i
    {
      var buf    := new Buf.Buffer.New(64, 8);
      var enqRes := s.Enqueue(buf);
      expect |s.queue| <= s.maxQueueSize;
      i := i + 1;
    }
  }

}
