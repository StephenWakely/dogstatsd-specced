// src/Buffer.dfy — S3: transactional byte buffer
// Spec: allium.md §Part 3 (S3), TLA+ model.tla BufferNotOverflow, TransactionalWrites
include "Errors.dfy"
include "Types.dfy"

module Buffer {

  import opened Errors
  import opened Types

  // Unit type for Result<Unit> returns (no stdlib)
  datatype Unit = Unit

  // S3-B01: byte buffer with capacity invariants (TLA+ bufferLen, elementCount)
  class Buffer {
    var data: seq<byte>
    var len: nat
    var maxSize: nat
    var elementCount: nat
    var maxElements: nat

    // S3-B02: structural invariant (TLA+ BufferNotOverflow: bufferLen <= MaxBufferSize)
    predicate Valid()
      reads this
    {
      len <= maxSize &&
      elementCount <= maxElements &&
      |data| == maxSize
    }

    // S3-B03: empty buffer constructor
    constructor New(ms: nat, me: nat)
      ensures Valid()
      ensures len == 0 && elementCount == 0
      ensures maxSize == ms && maxElements == me
    {
      maxSize := ms;
      maxElements := me;
      data := seq(ms, _ => (0 as byte));
      len := 0;
      elementCount := 0;
    }

    // S3-B04: transactional append (spec S3-R3.1, R3.2)
    method WriteMetric(metric: seq<byte>) returns (r: Result<Unit>)
      requires Valid()
      modifies this
      ensures Valid()                                                          // S3-B07
      ensures r.Err? ==>                                                       // S3-B05: rollback (TLA+ TransactionalWrites, I3.3)
        len == old(len) && elementCount == old(elementCount) && data == old(data)
      ensures r.Ok? ==>                                                        // S3-B06: append
        len == old(len) + |metric| && elementCount == old(elementCount) + 1
    {
      var metricLen: nat := |metric|;
      if len + metricLen > maxSize || elementCount >= maxElements {
        // S3-R3.2: buffer unchanged — no fields written before this return
        r := Err(ErrorSenderChannelFull);
        return;
      }
      // Invariant: len + metricLen <= maxSize, elementCount < maxElements
      var newLen: nat := len + metricLen;
      var remaining: nat := maxSize - newLen;
      data := data[..len] + metric + seq(remaining, _ => (0 as byte));
      len := newLen;
      elementCount := elementCount + 1;
      r := Ok(Unit);
    }

    // S3-B10: reset to empty
    method Reset()
      requires Valid()
      modifies this
      ensures Valid()
      ensures len == 0 && elementCount == 0      // S3-B11: ResetProducesEmpty
    {
      data := seq(maxSize, _ => (0 as byte));
      len := 0;
      elementCount := 0;
    }

    // S3-B12
    function IsEmpty(): bool
      reads this
    {
      len == 0
    }

    // S3-B13: live bytes data[0..len]
    function Bytes(): seq<byte>
      reads this
      requires Valid()
    {
      data[..len]
    }
  }

  // S3-B08: NoBufferOverflow — Valid() implies len <= maxSize (TLA+ BufferNotOverflow)
  lemma NoBufferOverflow(buf: Buffer)
    requires buf.Valid()
    ensures buf.len <= buf.maxSize
  {}

  // S3-B09: NoElementOverflow — Valid() implies elementCount <= maxElements
  lemma NoElementOverflow(buf: Buffer)
    requires buf.Valid()
    ensures buf.elementCount <= buf.maxElements
  {}

}
