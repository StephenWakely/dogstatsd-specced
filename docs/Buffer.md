# Buffer Module — `src/Buffer.dfy`

Spec: `spec/allium.md` Part 3 (S3), TLA+ `BufferNotOverflow`, `TransactionalWrites`

---

## Purpose

Transactional byte buffer. Serialized metrics append into `data[0..len]`. Write either commits fully or rolls back to pre-call state — no partial writes reach the sender.

Two capacity bounds enforced simultaneously:
- **Byte capacity**: `len <= maxSize` (TLA+ `bufferLen <= MaxBufferSize`)
- **Element capacity**: `elementCount <= maxElements` (TLA+ `elementCount <= MaxBufferElements`)

---

## Data Layout

```dafny
class Buffer {
  var data:         seq<byte>   // backing store, always |data| == maxSize
  var len:          nat         // live bytes in data[0..len]
  var maxSize:      nat         // byte capacity (TLA+: MaxBufferSize)
  var elementCount: nat         // number of metrics written since last Reset
  var maxElements:  nat         // max metrics per flush cycle
}
```

`data` is always allocated to full `maxSize`; only `data[0..len]` is live. This keeps `|data|` stable so `Valid()` can express `|data| == maxSize` as a simple equality.

---

## Invariant — `Valid()` (S3-B02)

```dafny
predicate Valid()
  reads this
{
  len <= maxSize &&
  elementCount <= maxElements &&
  |data| == maxSize
}
```

Maps to TLA+ `BufferNotOverflow`:

```
BufferNotOverflow == bufferLen <= MaxBufferSize /\ elementCount <= MaxBufferElements
```

Every public method requires `Valid()` on entry and ensures it on exit.

---

## API

### `New(ms, me)` — S3-B03

Constructor. Returns empty buffer with `len == 0`, `elementCount == 0`, `data` zeroed to `ms` bytes.

```dafny
constructor New(ms: nat, me: nat)
  ensures Valid()
  ensures len == 0 && elementCount == 0
  ensures maxSize == ms && maxElements == me
```

### `WriteMetric(metric)` — S3-B04

Transactional append. Spec: S3-R3.1, R3.2.

```dafny
method WriteMetric(metric: seq<byte>) returns (r: Result<Unit>)
  requires Valid()
  modifies this
  ensures Valid()
```

**Success path** (`Ok`):
- Appends `metric` bytes at `data[len..]`
- `len' == len + |metric|`
- `elementCount' == elementCount + 1`

**Failure path** (`Err(ErrorSenderChannelFull)`):
- Triggered when `len + |metric| > maxSize` OR `elementCount >= maxElements`
- `data`, `len`, `elementCount` all unchanged — bit-for-bit rollback (S3-R3.2, TLA+ `TransactionalWrites`)

Rollback is structural: no fields are written before the early `return`. The `ensures` clause enforces it:

```dafny
ensures r.Err? ==>
  len == old(len) && elementCount == old(elementCount) && data == old(data)
```

### `Reset()` — S3-B10

Zeros buffer to empty state. Called by worker after buffer is flushed to sender.

```dafny
method Reset()
  requires Valid()
  modifies this
  ensures Valid()
  ensures len == 0 && elementCount == 0
```

`data` is re-zeroed to `maxSize` bytes (not shrunk), preserving `|data| == maxSize` for `Valid()`.

### `IsEmpty()` — S3-B12

Pure predicate. Returns `len == 0`.

### `Bytes()` — S3-B13

Returns live slice `data[0..len]`. Used by `Sender.Send()` to write payload to transport.

```dafny
function Bytes(): seq<byte>
  reads this
  requires Valid()
{
  data[..len]
}
```

---

## Lemmas

### `NoBufferOverflow` — S3-B08

```dafny
lemma NoBufferOverflow(buf: Buffer)
  requires buf.Valid()
  ensures buf.len <= buf.maxSize
```

Extracts the byte-capacity clause from `Valid()`. Proves TLA+ invariant `BufferNotOverflow`. Body is empty — Dafny discharges it from `Valid()`'s definition.

### `NoElementOverflow` — S3-B09

```dafny
lemma NoElementOverflow(buf: Buffer)
  requires buf.Valid()
  ensures buf.elementCount <= buf.maxElements
```

Analogous to `NoBufferOverflow` for element count. Proves TLA+ `elementCount <= MaxBufferElements`.

---

## Proof Obligations Discharged

| Task ID | Claim | How Proved |
|---------|-------|-----------|
| S3-B05 | `WriteMetricRollback`: Err path leaves buffer unchanged | `ensures r.Err? ==> len == old(len) && ...` — no writes before early return |
| S3-B06 | `WriteMetricAppend`: Ok path increments len + elementCount correctly | `ensures r.Ok? ==> len == old(len) + \|metric\| && ...` |
| S3-B07 | `WriteMetricPreservesValid`: Valid() holds in all cases | `ensures Valid()` on WriteMetric |
| S3-B08 | `NoBufferOverflow`: len <= maxSize invariant | Lemma `NoBufferOverflow` + Valid() conjunction |
| S3-B09 | `NoElementOverflow`: elementCount <= maxElements invariant | Lemma `NoElementOverflow` + Valid() conjunction |
| S3-B11 | `ResetProducesEmpty`: Reset() yields len == 0, elementCount == 0 | `ensures len == 0 && elementCount == 0` on Reset() |

---

## TLA+ Mapping

| TLA+ Variable / Action | Dafny |
|------------------------|-------|
| `bufferLen` | `buf.len` |
| `elementCount` | `buf.elementCount` |
| `MaxBufferSize` | `buf.maxSize` (per-instance; set at construction) |
| `MaxBufferElements` | `buf.maxElements` (per-instance) |
| `BufferNotOverflow` | `Valid()` conjunction + lemmas S3-B08, S3-B09 |
| `TransactionalWrites` | `WriteMetric` Err postcondition (S3-B05) |
| `WriteToBuffer` action | `WriteMetric` method |
| `ResetBuffer` action | `Reset()` method |

---

## Verification

```bash
dafny verify src/Buffer.dfy
```

Expected output: **11 verified, 0 errors**

Verification covers: constructor, WriteMetric (both branches), Reset, IsEmpty, Bytes, NoBufferOverflow, NoElementOverflow — all method contracts and lemma bodies.

No `assume` statements in this module.

---

## Dependencies

| Module | Usage |
|--------|-------|
| `src/Errors.dfy` | `Result<T>`, `DogStatsDError`, `ErrorSenderChannelFull` |
| `src/Types.dfy` | `byte` (`bv8`) |
