// test/BufferPoolTest.dfy — regression tests for BufferPool review fixes
// Each test targets a specific fix from feedback round 1.
include "../src/BufferPool.dfy"

module BufferPoolTest {

  import BP = BufferPool
  import Buf = Buffer

  // Fix 3: Borrow postcondition guarantees returned buffer is Valid().
  // BEFORE fix: `ensures r.Some? ==> r.value.Valid()` absent — assert below unprovable.
  // AFTER fix: postcondition exists — verifier discharges assertion.
  method {:test} TestBorrowYieldsValidBuffer()
  {
    var pool := new BP.BufferPool.New(2, 64, 8);
    var r := pool.Borrow();
    expect r.Some?;
    expect r.value.Valid();
  }

  // Fix 2: Return enforces b.Valid() precondition — only valid buffers enter pool.
  // BEFORE fix: no requires b.Valid() — invalid buffers silently accumulated.
  // AFTER fix: requires b.Valid() — callers must supply valid buffer.
  method {:test} TestReturnValidBufferKeepsPoolValid()
  {
    var pool := new BP.BufferPool.New(2, 64, 8);
    var b := new Buf.Buffer.New(64, 8);
    pool.Return(b);
    expect pool.Valid();
  }

  // Fix 3: Expanded Valid() — all elements in pool satisfy Valid().
  // BEFORE fix: Valid() only checked |pool| <= capacity — no element guarantee.
  // AFTER fix: Valid() requires forall b in pool :: b.Valid().
  lemma TestValidTracksElementValidity(pool: BP.BufferPool)
    requires pool.Valid()
  {
    forall b | b in pool.pool
      ensures b.Valid()
    {
      // follows directly from expanded Valid() definition
    }
  }

}
