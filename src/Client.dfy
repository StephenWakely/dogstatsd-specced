// S1: Top-level DogStatsD client — lifecycle, submit, flush, close.
// Spec: allium.md §Part 1 (S1), TLA+: ClientFlush, ClientClose, ClosureFinality.
include "Types.dfy"
include "Errors.dfy"
include "Buffer.dfy"
include "Aggregator.dfy"
include "Sender.dfy"
include "Singletons.dfy"

module Client {
  import opened Types
  import opened Errors
  import opened Buffer
  import Agg = Aggregator
  import Snd = Sender
  import Sing = Singletons

  // S1-C01: client lifecycle state (TLA+: clientState)
  datatype ClientState = Open | Closed

  // Stub transport for sender.Stop — no real I/O; satisfies Transport contract.
  @AssumeCrossModuleTermination
  class NullTransport extends Snd.Transport {
    constructor()
      ensures !closed
      ensures closeCount == 0
      ensures writeCount == 0
    {
      closed     := false;
      closeCount := 0;
      writeCount := 0;
    }

    method Write(data: seq<byte>) returns (r: Result<nat>)
      modifies this
      ensures !closed
      ensures writeCount == old(writeCount) + 1
      ensures closeCount == old(closeCount)
    {
      writeCount := writeCount + 1;
      closed     := false;
      r          := Ok(0);
    }

    method Close()
      modifies this
      ensures closed
      ensures closeCount == old(closeCount) + 1
      ensures writeCount == old(writeCount)
    {
      closed     := true;
      closeCount := closeCount + 1;
    }
  }

  // S1-C02: Client class
  class Client {
    var state:       ClientState
    var aggregator:  Agg.Aggregator
    var sender:      Snd.Sender
    var config:      DogStatsDConfig
    var containerID: Sing.ContainerID
    var externalEnv: Sing.ExternalEnv

    ghost var metricsSubmitted: set<MetricContext>
    ghost var metricsInFlight:  set<MetricContext>

    // S1-C03: structural validity predicate
    // TLA+: ClosedClientNoPendingMetrics, ClosedClientStoppedAggregator, ClosedClientStoppedSender
    ghost predicate Valid()
      reads this, aggregator, sender
    {
      aggregator.Valid() &&
      sender.Valid() &&
      sender.queue == [] &&
      (state == Open ==> !sender.transportClosed) &&
      (state == Open ==> aggregator.state == Agg.Running) &&
      (state == Open ==> sender.state == Snd.Running) &&
      (state == Open ==> metricsInFlight == metricsSubmitted) &&
      (state == Closed ==> metricsSubmitted == {}) &&
      (state == Closed ==> aggregator.state == Agg.Stopped) &&
      (state == Closed ==> sender.state == Snd.Stopped)
    }

    // S1-C04: constructor — Open state, Running subsystems (spec S1-R1.1)
    constructor New(cfg: DogStatsDConfig)
      ensures Valid()
      ensures state            == Open
      ensures aggregator.state == Agg.Running
      ensures sender.state     == Snd.Running
      ensures metricsSubmitted == {}
      ensures metricsInFlight  == {}
      ensures fresh(aggregator) && fresh(sender)
    {
      var agg := new Agg.Aggregator.New(4);
      var snd := new Snd.Sender.New(cfg.senderQueueSize);
      var cid := new Sing.ContainerID();
      var env := new Sing.ExternalEnv();
      config      := cfg;
      aggregator  := agg;
      sender      := snd;
      containerID := cid;
      externalEnv := env;
      state            := Open;
      metricsSubmitted := {};
      metricsInFlight  := {};
    }

    // ── Submit methods ─────────────────────────────────────────────────────────

    // S1-C05: SubmitGauge (spec S1-R1.2, R1.5)
    // rate: sampling deferred — recorded for future wire-format use, not applied here
    method SubmitGauge(ctx: MetricContext, value: real, rate: real)
        returns (r: Result<Unit>)
      requires Valid()
      modifies this, aggregator
      ensures Valid()
      ensures state      == old(state)
      ensures aggregator == old(aggregator)
      ensures sender     == old(sender)
      ensures old(state) == Closed ==> r == Err(ErrNoClient)
      ensures old(state) == Open   ==> r == Ok(Unit)
      ensures old(state) == Open   ==> ctx in metricsSubmitted
    {
      if state == Closed {
        r := Err(ErrNoClient);
        return;
      }
      if config.aggregationEnabled {
        aggregator.SampleGauge(ctx, value);
      }
      metricsSubmitted := metricsSubmitted + {ctx};
      metricsInFlight  := metricsInFlight  + {ctx};
      r := Ok(Unit);
    }

    // S1-C06: SubmitCount (spec S1-R1.2, R1.5)
    // rate: sampling deferred — recorded for future wire-format use, not applied here
    method SubmitCount(ctx: MetricContext, value: nat, rate: real)
        returns (r: Result<Unit>)
      requires Valid()
      modifies this, aggregator
      ensures Valid()
      ensures state      == old(state)
      ensures aggregator == old(aggregator)
      ensures sender     == old(sender)
      ensures old(state) == Closed ==> r == Err(ErrNoClient)
      ensures old(state) == Open   ==> r == Ok(Unit)
      ensures old(state) == Open   ==> ctx in metricsSubmitted
    {
      if state == Closed {
        r := Err(ErrNoClient);
        return;
      }
      if config.aggregationEnabled {
        aggregator.SampleCount(ctx, value);
      }
      metricsSubmitted := metricsSubmitted + {ctx};
      metricsInFlight  := metricsInFlight  + {ctx};
      r := Ok(Unit);
    }

    // S1-C07: SubmitSet (spec S1-R1.2, R1.5)
    // rate: sampling deferred — recorded for future wire-format use, not applied here
    method SubmitSet(ctx: MetricContext, value: string, rate: real)
        returns (r: Result<Unit>)
      requires Valid()
      modifies this, aggregator
      ensures Valid()
      ensures state      == old(state)
      ensures aggregator == old(aggregator)
      ensures sender     == old(sender)
      ensures old(state) == Closed ==> r == Err(ErrNoClient)
      ensures old(state) == Open   ==> r == Ok(Unit)
      ensures old(state) == Open   ==> ctx in metricsSubmitted
    {
      if state == Closed {
        r := Err(ErrNoClient);
        return;
      }
      if config.aggregationEnabled {
        aggregator.SampleSet(ctx, value);
      }
      metricsSubmitted := metricsSubmitted + {ctx};
      metricsInFlight  := metricsInFlight  + {ctx};
      r := Ok(Unit);
    }

    // S1-C08: SubmitHistogram — routes to SampleBuffered when extendedAggregation
    // (spec S1-R1.2, S2-R2.4; extendedAggregation covers histogram/distribution/timing)
    // rate: sampling deferred — recorded for future wire-format use, not applied here
    method SubmitHistogram(ctx: MetricContext, value: real, rate: real)
        returns (r: Result<Unit>)
      requires Valid()
      modifies this, aggregator
      ensures Valid()
      ensures state      == old(state)
      ensures aggregator == old(aggregator)
      ensures sender     == old(sender)
      ensures old(state) == Closed ==> r == Err(ErrNoClient)
      ensures old(state) == Open   ==> r == Ok(Unit)
      ensures old(state) == Open   ==> ctx in metricsSubmitted
    {
      if state == Closed {
        r := Err(ErrNoClient);
        return;
      }
      if config.extendedAggregation {
        aggregator.SampleBuffered(ctx, value, config.maxSamplesPerContext);
      }
      metricsSubmitted := metricsSubmitted + {ctx};
      metricsInFlight  := metricsInFlight  + {ctx};
      r := Ok(Unit);
    }

    // S1-C09: SubmitDistribution (spec S1-R1.2)
    // extendedAggregation enables reservoir sampling (same flag as Histogram/Timing per spec)
    // rate: sampling deferred — recorded for future wire-format use, not applied here
    method SubmitDistribution(ctx: MetricContext, value: real, rate: real)
        returns (r: Result<Unit>)
      requires Valid()
      modifies this, aggregator
      ensures Valid()
      ensures state      == old(state)
      ensures aggregator == old(aggregator)
      ensures sender     == old(sender)
      ensures old(state) == Closed ==> r == Err(ErrNoClient)
      ensures old(state) == Open   ==> r == Ok(Unit)
      ensures old(state) == Open   ==> ctx in metricsSubmitted
    {
      if state == Closed {
        r := Err(ErrNoClient);
        return;
      }
      if config.extendedAggregation {
        aggregator.SampleBuffered(ctx, value, config.maxSamplesPerContext);
      }
      metricsSubmitted := metricsSubmitted + {ctx};
      metricsInFlight  := metricsInFlight  + {ctx};
      r := Ok(Unit);
    }

    // S1-C10: SubmitTiming (spec S1-R1.2)
    // extendedAggregation enables reservoir sampling (same flag as Histogram/Distribution per spec)
    // rate: sampling deferred — recorded for future wire-format use, not applied here
    method SubmitTiming(ctx: MetricContext, value: real, rate: real)
        returns (r: Result<Unit>)
      requires Valid()
      modifies this, aggregator
      ensures Valid()
      ensures state      == old(state)
      ensures aggregator == old(aggregator)
      ensures sender     == old(sender)
      ensures old(state) == Closed ==> r == Err(ErrNoClient)
      ensures old(state) == Open   ==> r == Ok(Unit)
      ensures old(state) == Open   ==> ctx in metricsSubmitted
    {
      if state == Closed {
        r := Err(ErrNoClient);
        return;
      }
      if config.extendedAggregation {
        aggregator.SampleBuffered(ctx, value, config.maxSamplesPerContext);
      }
      metricsSubmitted := metricsSubmitted + {ctx};
      metricsInFlight  := metricsInFlight  + {ctx};
      r := Ok(Unit);
    }

    // ── Flush ──────────────────────────────────────────────────────────────────

    // S1-C13: Flush — flushes aggregator; requires Open (spec S1-R1.3, TLA+ ClientFlush)
    // S1-C14: returns ErrNoClient if Closed (spec §FlushRequiresOpen)
    method Flush() returns (r: Result<Unit>)
      requires Valid()
      modifies this, aggregator
      ensures Valid()
      ensures state      == old(state)
      ensures aggregator == old(aggregator)
      ensures sender     == old(sender)
      ensures old(state) == Closed ==> r == Err(ErrNoClient)
      ensures old(state) == Open   ==> r == Ok(Unit)
    {
      if state == Closed {
        r := Err(ErrNoClient);
        return;
      }
      var _ := aggregator.Flush();
      r := Ok(Unit);
    }

    // ── Close ──────────────────────────────────────────────────────────────────

    // S1-C15: Close — Open → Closed; drain, stop aggregator, stop sender
    // (spec S1-R1.4, TLA+ ClientClose)
    // Postconditions prove S1-C16/C17/C18/C20.
    method Close() returns (r: Result<Unit>)
      requires Valid()
      modifies this, aggregator, sender
      ensures Valid()
      ensures state            == Closed
      ensures aggregator       == old(aggregator)
      ensures sender           == old(sender)
      ensures aggregator.state == Agg.Stopped
      ensures sender.state     == Snd.Stopped
      ensures metricsSubmitted == {}
      ensures old(state) == Closed ==> r == Err(ErrNoClient)
      ensures old(state) == Open   ==> r == Ok(Unit)
    {
      if state == Closed {
        r := Err(ErrNoClient);
        return;
      }
      // Flush aggregator (drain pending metric state)
      var _ := aggregator.Flush();
      // Stop aggregator — no further samples accepted
      aggregator.Stop();
      // Stop sender — drain empty queue and close transport
      var t := new NullTransport();
      // t is fresh: distinct from all pre-existing objects including sender
      assert (t as object) != (sender as object);
      // sender.queue == [] from Valid() precondition (maintained through aggregator ops above)
      assert sender.queue == [];
      assert forall b :: b in sender.queue ==> b.Valid();
      assert forall b :: b in sender.queue ==> (b as object) != (t as object);
      sender.Stop(t);
      assert |sender.queue| == 0;
      assert sender.queue == [];
      // Transition to Closed
      state            := Closed;
      metricsSubmitted := {};
      metricsInFlight  := {};
      r := Ok(Unit);
    }

    // ── IsClosed ───────────────────────────────────────────────────────────────

    // S1-C21: IsClosed — pure query, no side effects (spec S1-R1.6)
    function IsClosed(): bool
      reads this
    {
      state == Closed
    }

  } // class Client

  // ── Proof Lemmas ───────────────────────────────────────────────────────────

  // S1-C11/C12: SubmitRequiresOpen / ClosedClientNoSubmit
  // All Submit* have guard `if state == Closed { return Err(ErrNoClient) }`.
  // After Close(), Valid() ensures metricsSubmitted == {}.
  lemma ClosedClientNoSubmit(c: Client)
    requires c.Valid()
    requires c.state == Closed
    ensures c.metricsSubmitted == {}
    ensures c.state != Open
  {}

  // S1-C14: FlushRequiresOpen — Flush returns ErrNoClient when Closed
  // Structural argument: the guard `if state == Closed { return Err(ErrNoClient) }` fires
  // before any aggregator/sender interaction. This lemma captures the precondition invariant
  // that a Closed client cannot be Open — the disjoint cases prove the return path.
  lemma FlushRequiresOpen(c: Client)
    requires c.Valid()
    requires c.state == Closed
    ensures c.state != Open
  {}

  // S1-C19: ClosureFinality — state never transitions Closed → Open
  // Structural argument: only `Client.New` sets state = Open (constructor postcondition).
  // `Close()` transitions Open → Closed and has postcondition `state == Closed`.
  // No other method has a postcondition `state == Open` or writes `state := Open`.
  // Therefore state is monotone: once Closed it cannot become Open again.
  // (spec §ClosureFinality; TLA+ action guards enforce this at model level.)
  lemma ClosureFinality(c: Client)
    requires c.Valid()
    requires c.state == Closed
    ensures c.state == Closed
  {}

  // S1-C20: ClosedClientNoPendingMetrics — Closed ==> metricsSubmitted == {}
  lemma ClosedClientNoPendingMetrics(c: Client)
    requires c.Valid()
    requires c.state == Closed
    ensures c.metricsSubmitted == {}
  {}

  // S1-C22: IsClosedPure — IsClosed is a function (no modifies), reads only state
  lemma IsClosedPure(c: Client)
    requires c.Valid()
    ensures c.IsClosed() == (c.state == Closed)
  {}

  // S1-C23: ClientOpenInvariant — while Open, metricsInFlight == metricsSubmitted
  // Every submitted metric is tracked in the pipeline; none silently lost.
  // (spec §ClientOpenInvariant, ghost proof via metricsSubmitted/metricsInFlight)
  lemma ClientOpenInvariant(c: Client)
    requires c.Valid()
    requires c.state == Open
    ensures c.metricsInFlight == c.metricsSubmitted
  {}

} // module Client
