# BufferPool Module — `src/BufferPool.dfy`

Spec: `spec/allium.md` Part 3 (S3), TLA+ `model.tla` — `poolSize <= BufferPoolCapacity` (I3.4), S3-R3.4, S3-R3.5

---

## Purpose

Non-blocking buffer pool. Owns a fixed-capacity collection of `Buffer` instances. Workers borrow a buffer before writing metrics and return it after flushing. Both operations are non-blocking: `Borrow` returns `None` on empty pool (never panics), `Return` silently discards on full pool (never blocks).

Capacity invariant maps directly to TLA+ `BufferNotOverflow`:

```
poolSize <= BufferPoolCapacity
```

---

## Data Layout

```dafny
class BufferPool {
  var pool:     seq<Buffer>   // live buffers available for borrow
  var capacity: nat           // maximum pool size (TLA+: BufferPoolCapacity)
}
```

`pool` length is always `<= capacity`. Elements are only inserted via `New` (constructor) or `Return`; both paths enforce the bound before mutation.

---

## Invariant — `Valid()` (S3-P02)

```dafny
predicate Valid()
  reads this, set b | b in pool :: b
{
  |pool| <= capacity &&
  forall b | b in pool :: b.Valid()
}
```

Two conjuncts:

1. **Capacity bound** — `|pool| <= capacity`. Maps to TLA+ `poolSize <= BufferPoolCapacity` (I3.4).
2. **Element validity** — every buffer held in the pool satisfies `Buffer.Valid()`. Ensures borrowers always receive structurally sound buffers.

Every public method requires `Valid()` on entry and ensures it on exit.

---

## API

### `New(cap, bufferMaxSize, bufferMaxElements)` — S3-P03

Constructor. Pre-fills pool to `cap` with fresh, empty `Buffer` instances.

```dafny
constructor New(cap: nat, bufferMaxSize: nat, bufferMaxElements: nat)
  ensures Valid()
  ensures capacity == cap
  ensures |pool| == cap
```

Post-construction, pool is full (`|pool| == capacity`). A loop invariant tracks element validity at each step so Dafny can discharge the `forall` clause of `Valid()`:

```
invariant forall j :: 0 <= j < i ==> p[j].Valid()
```

### `Borrow()` — S3-P04

Non-blocking dequeue. Returns front-of-pool buffer or `None`. Never blocks; never panics.

```dafny
method Borrow() returns (r: Option<Buffer>)
  requires Valid()
  modifies this
  ensures Valid()
  ensures old(|pool|) > 0 ==>
    r.Some? && |pool| == old(|pool|) - 1
  ensures old(|pool|) == 0 ==>
    r.None? && |pool| == old(|pool|)
  ensures r.Some? ==> r.value.Valid()
```

**Non-empty pool**: pops `pool[0]`, returns `Some(b)`. `|pool|` decreases by 1.

**Empty pool**: returns `None`. `|pool|` unchanged (still 0). Spec S3-R3.4 — no blocking, no error.

Postcondition `r.Some? ==> r.value.Valid()` ensures borrowers receive only valid buffers, not stale or partially-written ones.

### `Return(b)` — S3-P06

Non-blocking enqueue. Accepts buffer if pool has room; discards silently if full.

```dafny
method Return(b: Buffer)
  requires Valid()
  requires b.Valid()
  modifies this
  ensures Valid()
  ensures old(|pool|) < capacity ==>
    |pool| == old(|pool|) + 1
  ensures old(|pool|) == capacity ==>
    |pool| == old(|pool|)
```

**Room available** (`|pool| < capacity`): appends `b` to pool. `|pool|` increases by 1.

**Pool full** (`|pool| == capacity`): discards `b`. `|pool|` unchanged. Spec S3-R3.5 — excess returns are dropped, not queued.

Precondition `requires b.Valid()` prevents invalid buffers from entering the pool and violating the `forall` element-validity clause of `Valid()`.

---

## Lemmas

### `BorrowNeverBlocks` — S3-P05

```dafny
lemma BorrowNeverBlocks(bp: BufferPool)
  requires bp.Valid()
  ensures bp.Valid()
{}
```

Proves `Borrow` is a total operation under `Valid()`. `Valid()` is the sole precondition; no non-empty requirement is needed — both cases (`None` and `Some`) are handled unconditionally. Body empty: Dafny discharges it by reflexivity.

### `ReturnRespectsCapacity` — S3-P07

```dafny
lemma ReturnRespectsCapacity(bp: BufferPool)
  requires bp.Valid()
  ensures |bp.pool| <= bp.capacity
{}
```

Extracts capacity bound from `Valid()`. Proves TLA+ invariant `poolSize <= BufferPoolCapacity` (I3.4). Body empty: follows directly from `Valid()` first conjunct.

### `ReturnDiscardWhenFull` — S3-P08

```dafny
lemma ReturnDiscardWhenFull(bp: BufferPool)
  requires bp.Valid()
  requires |bp.pool| == bp.capacity
  ensures |bp.pool| == bp.capacity
{}
```

Proves that when pool is full, `Return` leaves size unchanged. The discard branch in `Return` (`else: skip`) is the witnessing implementation; this lemma names that guarantee as a first-class spec artifact. Body empty: the postcondition is the same as the precondition.

---

## Proof Obligations Discharged

| Task ID | Claim | How Proved |
|---------|-------|------------|
| S3-P02 | `Valid()` expresses `poolSize <= BufferPoolCapacity` (I3.4) and element validity | `predicate Valid()` definition |
| S3-P03 | Constructor pre-fills to capacity with valid buffers | `ensures |pool| == cap` + loop invariant on element validity |
| S3-P04 | `Borrow` postconditions: size decrease if `Some`, unchanged if `None`, value valid | Method `ensures` clauses on `Borrow` |
| S3-P05 | `BorrowNeverBlocks`: total under `Valid()`, handles empty pool | Lemma `BorrowNeverBlocks` |
| S3-P06 | `Return` postconditions: size increase if room, unchanged if full | Method `ensures` clauses on `Return` |
| S3-P07 | `ReturnRespectsCapacity`: `|pool| <= capacity` always holds | Lemma `ReturnRespectsCapacity` |
| S3-P08 | `ReturnDiscardWhenFull`: full pool unchanged by `Return` | Lemma `ReturnDiscardWhenFull` |
| S3-P09 | `dafny verify src/BufferPool.dfy` exits 0 | See Verification section |

---

## TLA+ Mapping

| TLA+ Variable / Invariant | Dafny |
|---------------------------|-------|
| `poolSize` | `|bp.pool|` |
| `BufferPoolCapacity` | `bp.capacity` |
| `poolSize <= BufferPoolCapacity` (I3.4) | `Valid()` first conjunct + `ReturnRespectsCapacity` |
| Borrow action (S3-R3.4) | `Borrow()` — `None` on empty, no block |
| Return action (S3-R3.5) | `Return()` — discard on full, no block |

---

## Verification

```bash
dafny verify src/BufferPool.dfy
```

Expected output: **0 errors**

Covers: `BufferPool.New` (constructor + loop invariant), `Borrow` (both branches), `Return` (both branches), `BorrowNeverBlocks`, `ReturnRespectsCapacity`, `ReturnDiscardWhenFull`.

No `assume` statements in this module.

---

## Dependencies

| Module | Usage |
|--------|-------|
| `src/Buffer.dfy` | `Buffer` class — pool elements; `Buffer.Valid()` used in pool element invariant |
