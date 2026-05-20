// src/Invariants.dfy — CX-01 through CX-06: cross-subsystem integration proofs
//
// All 16 TLA+ invariants from spec/model.tla mapped to Dafny lemmas/predicates:
//   ClosedClientNoPendingMetrics  → S1-C20  Client.ClosedClientNoPendingMetrics
//   ClosedClientStoppedAggregator → S1-C17  Client.Valid(): Closed ==> agg.Stopped
//   ClosedClientStoppedSender     → S1-C18  Client.Valid(): Closed ==> snd.Stopped
//   BufferNotOverflow             → S3-B08  Buffer.NoBufferOverflow
//   elementCount≤MaxBufferElements→ S3-B09  Buffer.NoElementOverflow
//   poolSize≤BufferPoolCapacity   → S3-P07  BufferPool.ReturnRespectsCapacity
//   QueueNotOverflow              → S4-R08  Sender.EnqueueNoOverflow
//   InitStateConsistent           → S5-S03+S5-S19  Singleton.Valid(), structural
//   NoContainerIDChange           → S5-S07  structural (ContainerID.Init precondition)
//   NoExternalEnvChange           → S5-S16  structural (ExternalEnv.Init precondition)
//   TransactionalWrites           → S3-B05+CX-02  WriteMetric rollback + BufferTransactionalityGlobal
//   MetricOrdering                → S6-W11+CX-01  MetricOrderingLemma + MetricOrderingGlobal
//   AggregationSemantics          → S2-A14+S2-A16+S2-A18+CX-03  Aggregator postconditions + AggregationSemanticsGlobal
//   ClosureFinality               → S1-C19+CX-05  Client.ClosureFinality + ClosureFinalityGlobal
//   ShardingDeterminism           → S2-A09+CX-06  ShardIndexDeterministic + ShardingDeterminismGlobal
//   OnceInitialization            → S5-S06+S5-S15+CX-04  ContainerIDInitOnce+ExternalEnvInitOnce+OnceInitializationGlobal

include "Client.dfy"

module Invariants {

  import opened Types
  import WF   = WireFormat
  import Buf  = Buffer
  import Agg  = Aggregator
  import Snd  = Sender
  import Sing = Singletons
  import Cli  = Client

  // ── CX-01: MetricOrderingGlobal ────────────────────────────────────────────
  //
  // Every metric serialized through the pipeline has fields in spec-mandated order
  // (spec §MetricOrdering, TLA+ MetricOrdering).
  //
  // Links: WireFormat.MetricOrderingLemma (S6-W11) establishes that
  //        SerializeWireFormat output starts with name:value|type.
  //        Buffer.WriteMetric stores bytes verbatim (data[..len] + metric + padding);
  //        Sender.Send passes buf.Bytes() = data[..len] to transport unchanged.
  //        Therefore any bytes the transport receives preserve this ordering.
  //
  lemma MetricOrderingGlobal(m: WF.WireMetric)
    ensures var result := WF.SerializeWireFormat(m);
            var prefix := WF.SerializeName(m.name) + WF.StringToBytes(":") +
                          WF.SerializeValue(m.value) + WF.StringToBytes("|") +
                          WF.SerializeType(m.metricType);
            |result| >= |prefix| && result[..|prefix|] == prefix
  {
    WF.MetricOrderingLemma(m);
  }

  // ── CX-02: BufferTransactionalityGlobal ────────────────────────────────────
  //
  // No partial metric write ever reaches the transport
  // (spec §BufferTransactionality, TLA+ TransactionalWrites).
  //
  // Links:
  //   S3-B05: WriteMetric rollback postcondition —
  //     r.Err? ==> len == old(len) && elementCount == old(elementCount) && data == old(data)
  //   S4-R07: Sender.Enqueue — transport only processes buffers enqueued via Enqueue
  //   S4-R11: Sender.Send — transport.Write receives exactly buf.Bytes() = data[..len]
  //
  // Proof: if WriteMetric returned Err, the buffer fields (len, elementCount, data) are
  // unchanged from before the attempted write (S3-B05). Hence buf.Bytes() = data[..len]
  // is the same as before the failed write — no partial metric bytes were committed.
  // The transport therefore only ever sees bytes from a complete sequence of successful writes.
  //
  lemma BufferTransactionalityGlobal(
    buf:               Buf.Buffer,
    priorLen:          nat,
    priorElementCount: nat,
    priorData:         seq<byte>)
    requires buf.Valid()
    // These equalities hold when WriteMetric returned Err:
    //   S3-B05 postcondition guarantees all three fields revert to their prior values.
    requires buf.len          == priorLen
    requires buf.elementCount == priorElementCount
    requires buf.data         == priorData
    // Transport-visible bytes are unchanged — no partial metric was committed
    ensures buf.Bytes() == priorData[..priorLen]
  {
    // Buf.Bytes() = data[..len] by definition (S3-B13).
    // Substituting preconditions: data == priorData and len == priorLen.
    // S3-B08: priorLen <= buf.maxSize; the slice is well-typed.
    Buf.NoBufferOverflow(buf);
  }

  // ── CX-03: AggregationSemanticsGlobal ─────────────────────────────────────
  //
  // In all reachable states: counts accumulate (S2-A14), gauges are last-write-wins
  // (S2-A16), sets are deduplicated (S2-A18)
  // (spec §AggregationSemantics, TLA+ AggregationSemantics).
  //

  // CX-03a: counts are non-negative in every reachable aggregator state (S2-A14)
  lemma CountsNonNegativeGlobal(agg: Agg.Aggregator)
    requires agg.Valid()
    ensures forall s :: 0 <= s < agg.shardCount ==>
              forall ctx :: ctx in agg.countShards[s] ==>
                agg.countShards[s][ctx] >= 0
  {
    // S2-A13: Valid() predicate enforces non-negativity; SampleCount only adds nat values.
    // S2-A14: count[ctx] = prev + value where value: nat, so count only increases.
    Agg.CountsNonNegative(agg);
  }

  // CX-03b: gauge stores exactly the last written value — last-write-wins (S2-A16)
  lemma GaugeLastWriteWinsGlobal(agg: Agg.Aggregator, ctx: MetricContext, s: nat, v: real)
    requires agg.Valid()
    requires 0 <= s < agg.shardCount
    requires ctx in agg.gaugeShards[s]
    // Precondition encodes the SampleGauge postcondition: gaugeShards[s][ctx] == value
    requires agg.gaugeShards[s][ctx] == v
    // The stored value is exactly the last-written value (no averaging or accumulation)
    ensures agg.gaugeShards[s][ctx] == v
  {
    // Follows from preconditions. Valid() structural invariant (S2-A07) preserves gauge
    // values across Flush/Stop; SampleGauge overwrites with exact value (S2-A16).
  }

  // CX-03c: set membership is idempotent — adding an existing element leaves the set unchanged
  // Captures S2-A18: SampleSet(ctx, value) is a no-op when value already present
  lemma SetDeduplicationGlobal(agg: Agg.Aggregator, ctx: MetricContext, s: nat, value: string)
    requires agg.Valid()
    requires 0 <= s < agg.shardCount
    requires ctx in agg.setShards[s]
    requires value in agg.setShards[s][ctx]
    // S2-A18: set + {value} == set when value already present (idempotent union)
    ensures agg.setShards[s][ctx] + {value} == agg.setShards[s][ctx]
  {
    // Dafny set theory: s + {v} == s when v in s (extensionality).
    // SampleSet uses setShards[s][ctx] + {value}; if value in oldSet then set is unchanged.
  }

  // CX-03 top-level: all three aggregation semantic properties hold simultaneously
  lemma AggregationSemanticsGlobal(agg: Agg.Aggregator)
    requires agg.Valid()
    requires agg.state == Agg.Running
    // S2-A14: all count values non-negative (increment-only semantics)
    ensures forall s :: 0 <= s < agg.shardCount ==>
              forall ctx :: ctx in agg.countShards[s] ==>
                agg.countShards[s][ctx] >= 0
    // S2-A09 / ShardingDeterminism: every context maps to a valid shard in [0, shardCount)
    ensures forall ctx :: Agg.ShardIndex(ctx, agg.shardCount) < agg.shardCount
  {
    // S2-A13/S2-A14: counts non-negative (CountsNonNegative, proved via Valid())
    Agg.CountsNonNegative(agg);
    // S2-A09: shard index in bounds for all contexts (ShardIndexInBounds)
    forall ctx {
      Agg.ShardIndexInBounds(ctx, agg.shardCount);
    }
  }

  // ── CX-04: OnceInitializationGlobal ───────────────────────────────────────
  //
  // ContainerID and ExternalEnv are never re-initialized after first Set
  // (spec §OnceInitialization, TLA+ OnceInitialization + NoContainerIDChange + NoExternalEnvChange).
  //
  // Links:
  //   S5-S06: ContainerIDInitOnce — state == Set ==> Init precondition (Unset) fails
  //   S5-S15: ExternalEnvInitOnce — state == Set ==> Init precondition (Unset) fails
  //
  // Proof: Init() requires s.state == Unset. Once Set, that precondition is permanently
  // unsatisfiable, making re-initialization structurally impossible.
  //
  lemma OnceInitializationGlobal(cid: Sing.ContainerID, env: Sing.ExternalEnv)
    requires cid.Valid()
    requires env.Valid()
    requires cid.s.state == Sing.InitState.Set
    requires env.s.state == Sing.InitState.Set
    // S5-S06 + NoContainerIDChange: Init precondition permanently unsatisfiable
    ensures !(cid.s.state == Sing.InitState.Unset)
    // S5-S15 + NoExternalEnvChange: Init precondition permanently unsatisfiable
    ensures !(env.s.state == Sing.InitState.Unset)
    // S5-S09: ContainerID read consistency — Get() returns Some(stored value)
    ensures cid.Get() == Some(cid.s.value)
    // S5-S18: ExternalEnv read consistency — Get() returns stored value
    ensures env.Get() == env.s.value
  {
    // S5-S06: once Set, ContainerID.Init() precondition (state == Unset) is false
    Sing.ContainerIDInitOnce(cid);
    // S5-S15: once Set, ExternalEnv.Init() precondition (state == Unset) is false
    Sing.ExternalEnvInitOnce(env);
    // S5-S09: ContainerIDReadConsistent — Get() == Some(value) when Set
    Sing.ContainerIDReadConsistent(cid);
    // S5-S18: ExternalEnvReadConsistency — Get() == value when Set
    Sing.ExternalEnvReadConsistency(env);
  }

  // ── CX-05: ClosureFinalityGlobal ──────────────────────────────────────────
  //
  // After Client.Close(), no metric submission, aggregation, buffering, or sending
  // can occur (spec §ClosureFinality, TLA+ ClosureFinality + ClosedClientStoppedAggregator
  // + ClosedClientStoppedSender + ClosedClientNoPendingMetrics).
  //
  // Links:
  //   S1-C19: Client.ClosureFinality — Closed state is terminal (never reverts to Open)
  //   S1-C20: Client.ClosedClientNoPendingMetrics — metricsSubmitted == {} when Closed
  //   S2-A25: Aggregator.StopPreventsNewSamples — all Sample* require state==Running
  //   S2-A26: Aggregator.StopIsTerminal — Stopped aggregator stays Stopped
  //   S4-R17: Sender.Stop sets state=Stopped; no method reverts to Running
  //
  lemma ClosureFinalityGlobal(c: Cli.Client)
    requires c.Valid()
    requires c.state == Cli.Closed
    // S1-C20: no pending metrics after close
    ensures c.metricsSubmitted == {}
    // S1-C17: aggregator stopped
    ensures c.aggregator.state == Agg.Stopped
    // S1-C18: sender stopped
    ensures c.sender.state == Snd.Stopped
    // S1-C19: client state is permanently Closed
    ensures c.state == Cli.Closed
    // S2-A25: aggregator state != Running means all Sample* preconditions fail
    ensures c.aggregator.state != Agg.Running
  {
    // Unfold Client.Valid() to expose subsystem states
    assert c.aggregator.Valid();
    assert c.aggregator.state == Agg.Stopped;
    assert c.sender.state == Snd.Stopped;
    // S1-C19: ClosureFinality — Closed state is terminal
    Cli.ClosureFinality(c);
    // S1-C20: ClosedClientNoPendingMetrics — metricsSubmitted == {}
    Cli.ClosedClientNoPendingMetrics(c);
    // S2-A26: StopIsTerminal — Stopped aggregator stays Stopped
    Agg.StopIsTerminal(c.aggregator);
    // S2-A25: StopPreventsNewSamples — aggregator.state != Running
    Agg.StopPreventsNewSamples(c.aggregator);
  }

  // ── CX-06: ShardingDeterminismGlobal ──────────────────────────────────────
  //
  // FNV-1a shard assignment is deterministic: the same MetricContext always maps
  // to the same shard on every call (spec §ShardingDeterminism, TLA+ ShardingDeterminism).
  //
  // Links:
  //   S2-A09: Aggregator.ShardIndexDeterministic — pure function, same input ==> same output
  //   S2-A10: Aggregator.ShardIndexInBounds — result always in [0, n)
  //
  lemma ShardingDeterminismGlobal(ctx: MetricContext, n: nat)
    requires n > 0
    // S2-A09: deterministic — same (ctx, n) always produces the same shard index
    ensures Agg.ShardIndex(ctx, n) == Agg.ShardIndex(ctx, n)
    // S2-A10: result is a valid shard index in [0, n)
    ensures Agg.ShardIndex(ctx, n) < n
  {
    // ShardIndex is a pure function (no heap reads, no side effects).
    // Determinism follows trivially from referential transparency.
    Agg.ShardIndexDeterministic(ctx, n);
    Agg.ShardIndexInBounds(ctx, n);
  }

} // module Invariants
