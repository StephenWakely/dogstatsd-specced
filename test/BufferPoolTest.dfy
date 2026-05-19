// test/BufferPoolTest.dfy — regression tests for BufferPool review fixes
// Each test targets a specific fix from feedback round 1.
include "../src/BufferPool.dfy"

module BufferPoolTest {

  import BP = BufferPool
  import Buf = Buffer

  // Fix 3: Borrow postcondition guarantees returned buffer is Valid().
  // BEFORE fix: `ensures r.Some? ==> r.value.Valid()` absent — assert below unprovable.
  // AFTER fix: postcondition exists — verifier discharges assertion.
  method {:test} TestBorrowYieldsValidBuffer(pool: BP.BufferPool)
    requires pool.Valid()
    requires |pool.pool| > 0
    modifies pool, set b | b in pool.pool :: b
  {
    var r := pool.Borrow();
    assert r.Some?;
    assert r.value.Valid();  // needs `ensures r.Some? ==> r.value.Valid()`
  }

  // Fix 2: Return enforces b.Valid() precondition — only valid buffers enter pool.
  // BEFORE fix: no requires b.Valid() — invalid buffers silently accumulated.
  // AFTER fix: requires b.Valid() — callers must supply valid buffer.
  method {:test} TestReturnRequiresValidBuffer(pool: BP.BufferPool, b: Buf.Buffer)
    requires pool.Valid()
    requires b.Valid()
    modifies pool, b, set x | x in pool.pool :: x
  {
    pool.Return(b);
    assert pool.Valid();  // pool Valid() now guarantees all elements Valid()
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
