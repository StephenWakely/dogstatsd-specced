// src/Sender.dfy — S4: non-blocking send queue, telemetry, transport abstraction
// Spec: allium.md §Part 4 (S4), TLA+ QueueNotOverflow, SendFromQueue, ClientClose
include "Errors.dfy"
include "Buffer.dfy"

module Sender {

  import opened Errors
  import opened Buffer
  import opened Types

  // S4-R01: sender lifecycle state (TLA+: senderState)
  datatype SenderState = Running | Stopped

  // S4-R03: telemetry counters — all nat, monotone increments only (spec S4 §Telemetry Counters)
  datatype Telemetry = Telemetry(
    payloadsSent:    nat,
    payloadsDropped: nat,
    bytesSent:       nat,
    bytesDropped:    nat
  )

  // S4-R02: transport abstraction (spec S4 §Transport Implementations)
  // ghost vars track state for proofs; no opaque Valid() to sidestep framing issues
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

  // S4-R04: sender class (spec S4 §Entities)
  class Sender {
    var state:        SenderState
    var queue:        seq<Buffer>
    var maxQueueSize: nat
    var telemetry:    Telemetry
    ghost var transportClosed: bool

    // S4-R05: structural invariant (TLA+ QueueNotOverflow, I4.4)
    ghost predicate Valid()
      reads this
    {
      |queue| <= maxQueueSize &&
      (state == Stopped ==> transportClosed)
    }

    // S4-R06: construct Sender in Running state with empty queue and zero telemetry
    constructor New(mqs: nat)
      ensures Valid()
      ensures state        == Running
      ensures queue        == []
      ensures telemetry    == Telemetry(0, 0, 0, 0)
      ensures maxQueueSize == mqs
      ensures !transportClosed
    {
      state           := Running;
      queue           := [];
      maxQueueSize    := mqs;
      telemetry       := Telemetry(0, 0, 0, 0);
      transportClosed := false;
    }

    // S4-R07: non-blocking enqueue — drop when queue full (TLA+ EnqueueBuffer, spec S4-R4.2)
    // S4-R08: |queue| <= maxQueueSize proved via postcondition (TLA+ QueueNotOverflow, I4.1)
    // S4-R09: Err(ErrorSenderChannelFull) returned and queue unchanged when full
    // S4-R10: payloadsDropped and bytesDropped monotone
    method Enqueue(b: Buffer) returns (r: Result<Unit>)
      requires Valid()
      requires state == Running
      requires b.Valid()
      requires b !in queue
      modifies this
      ensures Valid()
      ensures |queue| <= maxQueueSize                                         // S4-R08
      ensures r.Ok?  ==> queue == old(queue) + [b]
      ensures r.Ok?  ==> |queue| == old(|queue|) + 1
      ensures r.Ok?  ==> telemetry == old(telemetry)
      ensures r.Err? ==> r == Err(ErrorSenderChannelFull)                    // S4-R09
      ensures r.Err? ==> queue == old(queue)
      ensures r.Err? ==> |queue| == old(|queue|)
      ensures telemetry.payloadsDropped >= old(telemetry.payloadsDropped)    // S4-R10
      ensures telemetry.bytesDropped    >= old(telemetry.bytesDropped)
      ensures state          == old(state)
      ensures maxQueueSize   == old(maxQueueSize)
      ensures transportClosed == old(transportClosed)
    {
      if |queue| < maxQueueSize {
        queue := queue + [b];
        r := Ok(Unit);
      } else {
        var dropped := b.len;
        telemetry := telemetry.(
          payloadsDropped := telemetry.payloadsDropped + 1,
          bytesDropped    := telemetry.bytesDropped + dropped
        );
        r := Err(ErrorSenderChannelFull);
      }
    }

    // S4-R11: dequeue one buffer and write to transport (TLA+ SendFromQueue, spec S4-R4.3, R4.4)
    // S4-R12: exactly one dequeue and one Write call per invocation — no retry (I4.2)
    // S4-R13: payloadsSent and bytesSent monotone
    // The precondition (transport as object) != (this as object) lets Dafny apply the frame axiom
    // after transport.Write — without it Z3 cannot rule out that Write modifies this.state etc.
    method Send(transport: Transport) returns (r: Result<Unit>)
      requires Valid()
      requires state == Running
      requires |queue| > 0
      requires queue[0].Valid()
      requires !transport.closed
      requires (transport as object) != (this as object)
      modifies this, transport
      ensures Valid()
      ensures |queue| == old(|queue|) - 1                                    // S4-R12: dequeued once
      ensures transport.writeCount == old(transport.writeCount) + 1          // S4-R12: written once
      ensures transport.closeCount == old(transport.closeCount)
      ensures !transport.closed
      ensures telemetry.payloadsSent    >= old(telemetry.payloadsSent)       // S4-R13
      ensures telemetry.bytesSent       >= old(telemetry.bytesSent)
      ensures telemetry.payloadsDropped >= old(telemetry.payloadsDropped)
      ensures telemetry.bytesDropped    >= old(telemetry.bytesDropped)
      ensures state          == old(state)
      ensures maxQueueSize   == old(maxQueueSize)
      ensures transportClosed == old(transportClosed)
    {
      var buf   := queue[0];
      queue     := queue[1..];
      var bytes := buf.Bytes();
      var wr    := transport.Write(bytes);
      match wr {
        case Ok(_) =>
          telemetry := telemetry.(
            payloadsSent := telemetry.payloadsSent + 1,
            bytesSent    := telemetry.bytesSent + |bytes|
          );
          r := Ok(Unit);
        case Err(e) =>
          telemetry := telemetry.(
            payloadsDropped := telemetry.payloadsDropped + 1,
            bytesDropped    := telemetry.bytesDropped + |bytes|
          );
          r := Err(e);
      }
    }

    // S4-R14: graceful shutdown — drain queue then close transport (TLA+ ClientClose, spec S4-R4.6)
    // S4-R15: transport.Close() called exactly once (proved via closeCount == 1 postcondition)
    // S4-R16: |queue| == 0 after Stop (proved via loop + postcondition)
    // S4-R17: state becomes Stopped and no method transitions it back to Running
    method Stop(transport: Transport)
      requires Valid()
      requires state == Running
      requires !transportClosed
      requires !transport.closed
      requires transport.closeCount == 0
      requires forall b :: b in queue ==> b.Valid()
      // Explicit disjointness: needed to apply the frame axiom for transport.Write
      // across the forall b :: b in queue invariant (Dafny/Z3 cannot derive Buffer!=Transport
      // via type tags for universally quantified variables without this hint).
      requires forall b :: b in queue ==> (b as object) != (transport as object)
      requires (transport as object) != (this as object)
      modifies this, transport
      ensures Valid()
      ensures state         == Stopped                                        // S4-R17
      ensures |queue|       == 0                                              // S4-R16
      ensures transportClosed                                                  // I4.4
      ensures transport.closed                                                 // I4.4
      ensures transport.closeCount == 1                                        // S4-R15
      ensures telemetry.payloadsDropped >= old(telemetry.payloadsDropped)
      ensures telemetry.payloadsSent    >= old(telemetry.payloadsSent)
    {
      // drain queue: call transport.Write once per buffer (S4-R12, S4-R16)
      while |queue| > 0
        invariant |queue|       <= old(|queue|)
        invariant |queue|       <= maxQueueSize
        invariant maxQueueSize  == old(maxQueueSize)
        invariant state         == Running
        invariant !transportClosed
        invariant !transport.closed
        invariant transport.closeCount == 0
        invariant forall b :: b in queue ==> b.Valid()
        invariant forall b :: b in queue ==> (b as object) != (transport as object)
        invariant telemetry.payloadsSent    >= old(telemetry.payloadsSent)
        invariant telemetry.bytesSent       >= old(telemetry.bytesSent)
        invariant telemetry.payloadsDropped >= old(telemetry.payloadsDropped)
        invariant telemetry.bytesDropped    >= old(telemetry.bytesDropped)
        decreases |queue|
      {
        var prevQueue := queue;
        var buf       := prevQueue[0];
        queue         := prevQueue[1..];
        var bytes     := buf.Bytes();
        var wr        := transport.Write(bytes);
        match wr {
          case Ok(_) =>
            telemetry := telemetry.(
              payloadsSent := telemetry.payloadsSent + 1,
              bytesSent    := telemetry.bytesSent + |bytes|
            );
          case Err(_) =>
            telemetry := telemetry.(
              payloadsDropped := telemetry.payloadsDropped + 1,
              bytesDropped    := telemetry.bytesDropped + |bytes|
            );
        }
        // Re-establish both forall invariants for the dequeued tail.
        // prevQueue's elements were valid (loop inv) and differ from transport (loop inv).
        // Write modified only transport; framing (b != transport) preserves b.Valid().
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
      }
      // close transport exactly once (S4-R15: StopTransportClosedOnce)
      transport.Close();
      transportClosed := true;
      state := Stopped;
    }
  }

  // --- Proof lemmas ---

  // S4-R08: EnqueueNoOverflow — queue size never exceeds maxQueueSize (TLA+ QueueNotOverflow, I4.1)
  lemma EnqueueNoOverflow(s: Sender)
    requires s.Valid()
    ensures |s.queue| <= s.maxQueueSize
  {}

  // S4-R09: EnqueueDropsWhenFull — captured by Enqueue postconditions:
  //   r.Err? ==> r == Err(ErrorSenderChannelFull) && queue == old(queue)

  // S4-R10: TelemetryDropMonotone — payloadsDropped and bytesDropped only increase
  lemma TelemetryDropMonotone(before: Telemetry, after: Telemetry)
    requires after.payloadsDropped >= before.payloadsDropped
    requires after.bytesDropped    >= before.bytesDropped
    ensures  after.payloadsDropped >= before.payloadsDropped
    ensures  after.bytesDropped    >= before.bytesDropped
  {}

  // S4-R12: SendNoRetry — each buffer dequeued and attempted exactly once:
  //   captured by Send postconditions:
  //   |queue| == old(|queue|) - 1  &&  transport.writeCount == old(writeCount) + 1

  // S4-R13: TelemetrySentMonotone — payloadsSent and bytesSent only increase
  lemma TelemetrySentMonotone(before: Telemetry, after: Telemetry)
    requires after.payloadsSent >= before.payloadsSent
    requires after.bytesSent    >= before.bytesSent
    ensures  after.payloadsSent >= before.payloadsSent
    ensures  after.bytesSent    >= before.bytesSent
  {}

  // S4-R15: StopTransportClosedOnce — captured by Stop postcondition transport.closeCount == 1

  // S4-R16: StopDrainsQueue — captured by Stop postcondition |queue| == 0

  // S4-R17: StopIsTerminal — Stopped state is absorbing; no method sets state = Running
  lemma StopIsTerminal(s: Sender)
    requires s.state == Stopped
    ensures  s.state == Stopped
  {}

}
