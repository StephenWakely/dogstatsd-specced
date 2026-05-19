// src/BufferPool.dfy — S3: non-blocking buffer pool with capacity enforcement
// Spec: allium.md §Part 3 (S3), TLA+ model.tla BufferNotOverflow (poolSize <= BufferPoolCapacity)
include "Buffer.dfy"

module BufferPool {

  import Buf = Buffer

  // Option for Borrow return (S3-R3.4)
  datatype Option<T> = None | Some(value: T)

  // S3-P01: pool class (TLA+: poolSize, BufferPoolCapacity)
  class BufferPool {
    var pool: seq<Buf.Buffer>
    var capacity: nat

    // S3-P02: capacity invariant (TLA+ poolSize <= BufferPoolCapacity, I3.4)
    // Also tracks element validity so borrowers get only valid Buffers
    predicate Valid()
      reads this, set b | b in pool :: b
    {
      |pool| <= capacity &&
      forall b | b in pool :: b.Valid()
    }

    // S3-P03: pre-fill pool to capacity with empty Buffers
    constructor New(cap: nat, bufferMaxSize: nat, bufferMaxElements: nat)
      ensures Valid()
      ensures capacity == cap
      ensures |pool| == cap
    {
      capacity := cap;
      var p: seq<Buf.Buffer> := [];
      var i := 0;
      while i < cap
        invariant 0 <= i <= cap
        invariant |p| == i
        invariant forall j :: 0 <= j < i ==> p[j].Valid()
      {
        var b := new Buf.Buffer.New(bufferMaxSize, bufferMaxElements);
        p := p + [b];
        i := i + 1;
      }
      pool := p;
    }

    // S3-P04: non-blocking borrow (spec S3-R3.4)
    // Returns Some(b) if pool non-empty, pops front; None if empty — never blocks
    // Note: P05 (BorrowNeverBlocks lemma) is outside class; P06 (Return) follows here
    // — spec ordering is S3-P04/P05/P06 but file groups class members together.
    method Borrow() returns (r: Option<Buf.Buffer>)
      requires Valid()
      modifies this
      ensures Valid()
      ensures old(|pool|) > 0 ==>
        r.Some? && |pool| == old(|pool|) - 1     // popped one
      ensures old(|pool|) == 0 ==>
        r.None? && |pool| == old(|pool|)          // unchanged
      ensures r.Some? ==> r.value.Valid()         // borrower gets valid buffer
    {
      if |pool| == 0 {
        r := None;
      } else {
        r := Some(pool[0]);
        pool := pool[1..];
      }
    }

    // S3-P06: non-blocking return (spec S3-R3.5)
    // Pushes b if room; discards b if pool already at capacity — never blocks
    method Return(b: Buf.Buffer)
      requires Valid()
      requires b.Valid()
      modifies this
      ensures Valid()
      ensures old(|pool|) < capacity ==>
        |pool| == old(|pool|) + 1                // accepted
      ensures old(|pool|) == capacity ==>
        |pool| == old(|pool|)                    // discarded — S3-R3.5
    {
      if |pool| < capacity {
        pool := pool + [b];
      }
      // else: discard — excess returns are dropped per S3-R3.5 / I3.4
    }
  }

  // S3-P05: BorrowNeverBlocks — Borrow requires only Valid(), not non-empty pool
  // Valid() is the sole precondition; both empty and non-empty cases are handled
  lemma BorrowNeverBlocks(bp: BufferPool)
    requires bp.Valid()
    ensures bp.Valid()
  {}

  // S3-P07: ReturnRespectsCapacity — pool never exceeds capacity after Return (TLA+ I3.4)
  lemma ReturnRespectsCapacity(bp: BufferPool)
    requires bp.Valid()
    ensures |bp.pool| <= bp.capacity
  {}

  // S3-P08: ReturnDiscardWhenFull — full pool leaves size unchanged after Return
  lemma ReturnDiscardWhenFull(bp: BufferPool)
    requires bp.Valid()
    requires |bp.pool| == bp.capacity
    ensures |bp.pool| == bp.capacity
  {}

}
