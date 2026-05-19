// test/TestS3.dfy — T-S3-01 through T-S3-07: buffer and pool tests
// Spec: allium.md §Part 3 (S3)
include "../src/BufferPool.dfy"

module TestS3 {

  import BP = BufferPool
  import Buf = Buffer
  import opened Types

  // T-S3-01: WriteMetric succeeds within capacity; len and elementCount increase correctly
  method {:test} TestWriteWithinCapacity()
  {
    var buf := new Buf.Buffer.New(64, 8);
    var metric: seq<byte> := [104, 101, 108, 108, 111]; // "hello"
    var r := buf.WriteMetric(metric);
    expect r.Ok?;
    expect buf.len == |metric|;
    expect buf.elementCount == 1;
  }

  // T-S3-02: WriteMetric returns Err when len + |metric| > maxSize; buffer unchanged (I3.3 rollback)
  method {:test} TestWriteOverflowRollsBack()
  {
    var buf := new Buf.Buffer.New(4, 8);
    var metric: seq<byte> := [1, 2, 3, 4, 5]; // 5 bytes > maxSize 4
    var oldLen := buf.len;
    var oldData := buf.data;
    var r := buf.WriteMetric(metric);
    expect r.Err?;
    expect buf.len == oldLen;
    expect buf.data == oldData;
  }

  // T-S3-03: WriteMetric returns Err when elementCount == maxElements; buffer unchanged
  method {:test} TestElementCountOverflowRollsBack()
  {
    var buf := new Buf.Buffer.New(64, 1); // maxElements = 1
    var m1: seq<byte> := [1];
    var r1 := buf.WriteMetric(m1);
    expect r1.Ok?;
    // now elementCount == maxElements == 1
    var oldLen := buf.len;
    var oldData := buf.data;
    var m2: seq<byte> := [2];
    var r2 := buf.WriteMetric(m2);
    expect r2.Err?;
    expect buf.len == oldLen;
    expect buf.data == oldData;
  }

  // T-S3-04: Reset() produces empty buffer (len == 0, elementCount == 0)
  method {:test} TestFlushBufferResetsToEmpty()
  {
    var buf := new Buf.Buffer.New(64, 8);
    var metric: seq<byte> := [1, 2, 3];
    var r := buf.WriteMetric(metric);
    expect r.Ok?;
    buf.Reset();
    expect buf.len == 0;
    expect buf.elementCount == 0;
  }

  // T-S3-05: Borrow on empty pool returns None immediately — never blocks (S3-R3.4)
  method {:test} TestPoolBorrowNeverBlocks()
  {
    var pool := new BP.BufferPool.New(0, 64, 8); // capacity 0 — pool starts empty
    var r := pool.Borrow();
    expect r.None?;
  }

  // T-S3-06: Return to full pool leaves pool size unchanged (I3.4, S3-R3.5)
  method {:test} TestPoolReturnRespectsCapacity()
  {
    var pool := new BP.BufferPool.New(1, 64, 8); // capacity 1, pre-filled with 1 buffer
    var b := new Buf.Buffer.New(64, 8);
    var oldSize := |pool.pool|;
    pool.Return(b); // pool already at capacity — b discarded
    expect |pool.pool| == oldSize;
  }

  // T-S3-07: first write survives; second overflow fully rolls back (I3.3)
  method {:test} TestTransactionalWritesAllOrNothing()
  {
    var buf := new Buf.Buffer.New(6, 8); // maxSize = 6
    var m1: seq<byte> := [1, 2, 3];     // fits: 0 + 3 <= 6
    var m2: seq<byte> := [4, 5, 6, 7];  // overflows: 3 + 4 > 6
    var r1 := buf.WriteMetric(m1);
    expect r1.Ok?;
    expect buf.len == 3;
    var lenAfterFirst := buf.len;
    var dataAfterFirst := buf.data;
    var r2 := buf.WriteMetric(m2);
    expect r2.Err?;
    expect buf.len == lenAfterFirst;
    expect buf.data == dataAfterFirst;
  }

}
