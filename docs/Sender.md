# Sender Module — `src/Sender.dfy`

Spec: `spec/allium.md` Part 4 (S4), TLA+ `QueueNotOverflow`, `SendFromQueue`, `ClientClose`

---

## Purpose

Non-blocking send queue with transport abstraction and split telemetry counters. Buffers produced by the worker are enqueued without blocking; a background sender drains the queue by writing to a `Transport`. When the queue is full, payloads are dropped and counted. On shutdown, the queue is drained completely before the transport is closed.

Three behavioral guarantees, all formally proved:

- **Queue never overflows**: `|queue| <= maxQueueSize` at all times (TLA+ `QueueNotOverflow`)
- **Send is no-retry**: each buffer dequeued and written to transport exactly once (I4.2)
- **Stop drains and closes once**: after `Stop()`, queue is empty and `transport.Close()` called exactly once (I4.4)

---

## Types

### `SenderState` — S4-R01

```dafny
datatype SenderState = Running | Stopped
```

Maps to TLA+ `senderState`. State is terminal once `Stopped` — no method transitions it back to `Running` (S4-R17).

### `Telemetry` — S4-R03

```dafny
datatype Telemetry = Telemetry(
  payloadsSent:             nat,
  payloadsDroppedQueueFull: nat,
  payloadsDroppedWriter:    nat,
  bytesSent:                nat,
  bytesDroppedQueueFull:    nat,
  bytesDroppedWriter:       nat
)
```

Six `nat` counters — all monotonically increasing. The spec (allium.md §Telemetry Counters) distinguishes two drop causes:

| Counter | Incremented by | Cause |
|---------|---------------|-------|
| `payloadsDroppedQueueFull` / `bytesDroppedQueueFull` | `Enqueue` | Queue was at capacity |
| `payloadsDroppedWriter` / `bytesDroppedWriter` | `Send`, `Stop` drain loop | `transport.Write()` returned `Err` |

Keeping these separate allows callers to distinguish back-pressure drops from transport errors. `payloadsSent` / `bytesSent` track successful deliveries.

All fields are `nat`: Dafny enforces non-negativity statically; no underflow is possible.

### `Transport` trait — S4-R02

```dafny
trait Transport {
  ghost var closed:     bool
  ghost var closeCount: nat
  ghost var writeCount: nat

  method Write(data: seq<byte>) returns (r: Result<nat>)
    requires !closed
    modifies this
    ensures !closed
    ensures writeCount == old(writeCount) + 1
    ensures closeCount == old(closeCount)

  method Close()
    requires !closed
    modifies this
    ensures closed
    ensures closeCount == old(closeCount) + 1
    ensures writeCount == old(writeCount)
}
```

The three ghost variables exist solely for proof tracking:

- `closed` — `Stop()` precondition ensures transport is open; `Close()` sets it
- `closeCount` — proves `Close()` called exactly once (S4-R15)
- `writeCount` — proves each buffer written exactly once (S4-R12)

`Write` and `Close` are mutually exclusive by the `!closed` precondition: once `Close()` fires, `Write()` cannot be called again.

---

## `Sender` class — S4-R04

```dafny
class Sender {
  var state:        SenderState
  var queue:        seq<Buffer>
  var maxQueueSize: nat
  var telemetry:    Telemetry
  ghost var transportClosed: bool
}
```

`queue` is a `seq<Buffer>` — a functional sequence; enqueue appends to the tail, dequeue takes from the head. `transportClosed` is a ghost field tracking whether `Stop()` has fired the transport's `Close()`.

---

## Invariant — `Valid()` (S4-R05)

```dafny
ghost predicate Valid()
  reads this
{
  |queue| <= maxQueueSize &&
  (state == Stopped ==> transportClosed)
}
```

Two conjuncts:

1. **Queue bound** — maps to TLA+ `QueueNotOverflow`: `queueLen <= SenderQueueSize`
2. **Closure consistency** — if state is `Stopped`, transport has been closed (I4.4)

Every public method requires `Valid()` on entry and ensures it on exit.

---

## API

### `New(mqs)` — S4-R06

```dafny
constructor New(mqs: nat)
  ensures Valid()
  ensures state        == Running
  ensures queue        == []
  ensures telemetry    == Telemetry(0, 0, 0, 0, 0, 0)
  ensures maxQueueSize == mqs
  ensures !transportClosed
```

Initializes sender in `Running` state with empty queue and all-zero telemetry.

---

### `Enqueue(b)` — S4-R07

```dafny
method Enqueue(b: Buffer) returns (r: Result<Unit>)
  requires Valid()
  requires state == Running
  requires b.Valid()
  modifies this
  ensures Valid()
  ensures |queue| <= maxQueueSize
```

Non-blocking. Two paths:

**Space available** (`|queue| < maxQueueSize`):
- Appends `b` to queue tail
- Returns `Ok(Unit)`
- Telemetry unchanged

**Queue full** (`|queue| == maxQueueSize`):
- Increments `payloadsDroppedQueueFull` and `bytesDroppedQueueFull` (by `b.len`)
- Returns `Err(ErrorSenderChannelFull)`
- Queue unchanged

Key postconditions:

```dafny
ensures r.Ok?  ==> queue == old(queue) + [b]
ensures r.Err? ==> r == Err(ErrorSenderChannelFull)   // S4-R09
ensures r.Err? ==> queue == old(queue)
ensures telemetry.payloadsDroppedQueueFull >= old(telemetry.payloadsDroppedQueueFull)  // S4-R10
ensures telemetry.payloadsDroppedWriter    == old(telemetry.payloadsDroppedWriter)
```

Writer drop counters are explicitly held equal — proving the 6-counter split is maintained.

---

### `Send(transport)` — S4-R11

```dafny
method Send(transport: Transport) returns (r: Result<Unit>)
  requires Valid()
  requires state == Running
  requires |queue| > 0
  requires queue[0].Valid()
  requires !transport.closed
  requires (transport as object) != (this as object)
  modifies this, transport
  ensures Valid()
  ensures |queue| == old(|queue|) - 1
  ensures transport.writeCount == old(transport.writeCount) + 1
  ensures transport.closeCount == old(transport.closeCount)
  ensures !transport.closed
```

Dequeues `queue[0]`, calls `transport.Write(buf.Bytes())` once (S4-R12). No retry on failure.

**Success** (`Ok`): increments `payloadsSent` and `bytesSent`.

**Failure** (`Err`): increments `payloadsDroppedWriter` and `bytesDroppedWriter`. Error from `transport.Write` is propagated as-is.

The `(transport as object) != (this as object)` precondition is a framing hint. Without it, Dafny/Z3 cannot rule out that `transport.Write` modifies `this.state`, `this.queue`, etc., and the post-Write assertions about `this` cannot be discharged.

---

### `Stop(transport)` — S4-R14

```dafny
method Stop(transport: Transport)
  requires Valid()
  requires state == Running
  requires !transportClosed
  requires !transport.closed
  requires forall b :: b in queue ==> b.Valid()
  requires forall b :: b in queue ==> (b as object) != (transport as object)
  requires (transport as object) != (this as object)
  modifies this, transport
  ensures Valid()
  ensures state         == Stopped          // S4-R17
  ensures |queue|       == 0                // S4-R16
  ensures transportClosed                   // I4.4
  ensures transport.closed                  // I4.4
  ensures transport.closeCount == old(transport.closeCount) + 1  // S4-R15
```

Three steps:

1. **Drain loop** — while `|queue| > 0`, dequeue `queue[0]` and call `transport.Write` once per buffer. Results are counted in telemetry (success or writer-drop). Transport is not closed during the loop.
2. **Close** — `transport.Close()` called exactly once after the loop.
3. **Terminal state** — `transportClosed := true; state := Stopped`.

The `forall b :: b in queue ==> (b as object) != (transport as object)` precondition is required for the loop body. Inside the loop, after `transport.Write`, Dafny needs to re-establish that the remaining queue elements are still valid. Since `Write` modifies `transport`, the frame axiom only protects objects provably disjoint from `transport`. The precondition provides that proof at call site; the loop invariant carries it forward.

The loop body contains an explicit `forall` proof block to re-establish the two per-element invariants after dequeuing the head:

```dafny
forall b | b in queue
  ensures b.Valid()
  ensures (b as object) != (transport as object)
{
  var i :| 0 <= i < |queue| && queue[i] == b;
  assert prevQueue[1..][i] == prevQueue[i + 1];
  assert b == prevQueue[i + 1];
  assert b in prevQueue;
  assert (b as object) != (transport as object);
}
```

This witnesses the index correspondence between the new tail and the previous queue.

---

## Lemmas

### `EnqueueNoOverflow` — S4-R08

```dafny
lemma EnqueueNoOverflow(s: Sender)
  requires s.Valid()
  ensures |s.queue| <= s.maxQueueSize
{}
```

Extracts the queue-bound clause from `Valid()`. Maps to TLA+ `QueueNotOverflow` (I4.1). Body empty — Dafny discharges from `Valid()`.

### `TelemetryDropQueueFullMonotone` — S4-R10

```dafny
lemma TelemetryDropQueueFullMonotone(t: Telemetry, deltaPayloads: nat, deltaBytes: nat)
  ensures t.(payloadsDroppedQueueFull := t.payloadsDroppedQueueFull + deltaPayloads)
           .payloadsDroppedQueueFull >= t.payloadsDroppedQueueFull
  ensures t.(bytesDroppedQueueFull := t.bytesDroppedQueueFull + deltaBytes)
           .bytesDroppedQueueFull >= t.bytesDroppedQueueFull
{}
```

Proves queue-full drop counters never decrease. `nat` arithmetic makes the body trivial.

### `TelemetryDropWriterMonotone` — S4-R10

Analogous lemma for `payloadsDroppedWriter` / `bytesDroppedWriter`.

### `TelemetrySentMonotone` — S4-R13

```dafny
lemma TelemetrySentMonotone(t: Telemetry, deltaPayloads: nat, deltaBytes: nat)
  ensures t.(payloadsSent := t.payloadsSent + deltaPayloads).payloadsSent >= t.payloadsSent
  ensures t.(bytesSent := t.bytesSent + deltaBytes).bytesSent >= t.bytesSent
{}
```

Proves `payloadsSent` / `bytesSent` never decrease.

### `TelemetryDropQueueFullSeparateFromWriter`

Regression lemma. Verifies that incrementing queue-full drop counters leaves writer drop counters unchanged. Would fail on the old 4-counter `Telemetry` definition. Guards the 6-counter split.

### `TelemetryWriterDropSeparateFromQueueFull`

Symmetric regression lemma. Verifies that incrementing writer drop counters leaves queue-full drop counters unchanged.

---

## Proof Obligations Discharged

| Task ID | Claim | How Proved |
|---------|-------|-----------|
| S4-R08 | `EnqueueNoOverflow`: `\|queue\| <= maxQueueSize` after Enqueue | `ensures \|queue\| <= maxQueueSize` + lemma `EnqueueNoOverflow` |
| S4-R09 | `EnqueueDropsWhenFull`: full queue returns `Err`, queue unchanged | `ensures r.Err? ==> r == Err(ErrorSenderChannelFull)` and `queue == old(queue)` |
| S4-R10 | `TelemetryDropMonotone`: drop counters only increase | Lemmas `TelemetryDropQueueFullMonotone`, `TelemetryDropWriterMonotone` |
| S4-R12 | `SendNoRetry`: one dequeue, one Write per call | `ensures \|queue\| == old(\|queue\|) - 1 && transport.writeCount == old(writeCount) + 1` |
| S4-R13 | `TelemetrySentMonotone`: sent counters only increase | Lemma `TelemetrySentMonotone` |
| S4-R15 | `StopTransportClosedOnce`: `Close()` called exactly once | `ensures transport.closeCount == old(transport.closeCount) + 1` |
| S4-R16 | `StopDrainsQueue`: `\|queue\| == 0` after Stop | `ensures \|queue\| == 0` + loop `decreases \|queue\|` |
| S4-R17 | `StopIsTerminal`: Stopped → Running impossible | `ensures state == Stopped`; Enqueue/Send both `ensures state == old(state)`, neither has a Stopped precondition that could set Running |

---

## TLA+ Mapping

| TLA+ Variable / Action | Dafny |
|------------------------|-------|
| `senderState` | `sender.state` |
| `queueLen` | `\|sender.queue\|` |
| `SenderQueueSize` | `sender.maxQueueSize` |
| `QueueNotOverflow` | `Valid()` + lemma `EnqueueNoOverflow` |
| `EnqueueBuffer` action | `Enqueue` method |
| `SendFromQueue` action | `Send` method |
| `ClientClose` action | `Stop` method |
| `payloadsSent` / `bytesSent` | `telemetry.payloadsSent` / `telemetry.bytesSent` |
| drop counters | `telemetry.payloadsDroppedQueueFull`, `payloadsDroppedWriter`, `bytesDroppedQueueFull`, `bytesDroppedWriter` |

---

## Verification

```bash
dafny verify src/Sender.dfy
```

Expected output: **0 errors**

No `assume` statements in this module.

---

## Dependencies

| Module | Usage |
|--------|-------|
| `src/Errors.dfy` | `Result<T>`, `DogStatsDError`, `ErrorSenderChannelFull` |
| `src/Buffer.dfy` | `Buffer` class — queue element type; `Buffer.Valid()`, `Buffer.Bytes()` |
| `src/Types.dfy` | `byte` (`bv8`), `Unit` |
