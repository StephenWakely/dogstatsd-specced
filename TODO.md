# TODO — DogStatsD Dafny Client

All tasks reference the spec. Format: `[SUBSYSTEM] Description (spec ref)`.
Verification must pass (`dafny verify`) before any task is complete.

---

## Phase 0: Project Setup ✅

- [x] Create `dfyconfig.toml` project config
- [x] Create `src/` and `test/` directories
- [x] Write `AGENTS.md` and `README.md`
- [x] Write `TODO.md`

---

## Phase 1: Types and Constants (S6) ✅

`src/Types.dfy`

- [x] **[S6-T01]** Define `MetricType` datatype: `Gauge | Count | Histogram | Distribution | Set | Timing`
- [x] **[S6-T02]** Define type symbol function `MetricTypeSymbol(t: MetricType): string` mapping to `g/c/h/d/s/ms` (S6, allium.md §Wire Format Summary)
- [x] **[S6-T03]** Define `TransportMode` datatype: `UDP | UDS | Pipe` (S1, allium.md §Entities)
- [x] **[S6-T04]** Define `TagCardinality` datatype: `CardinalityNotSet | CardinalityNone | CardinalityLow | CardinalityOrchestrator | CardinalityHigh` (S6, allium.md §Tag Cardinality Levels)
- [x] **[S6-T05]** Define cardinality string function `CardinalityString(c: TagCardinality): Option<string>` returning None for `CardinalityNotSet`, `Some("none"/"low"/"orchestrator"/"high")` for others
- [x] **[S6-T06]** Define `MetricContext` as a record: `name: string`, `tags: seq<string>` (S2, allium.md §Entities)
- [x] **[S6-T07]** Define configuration constants: `UDP_MAX_BYTES := 1432`, `UDS_MAX_BYTES := 8192`, `DEFAULT_BUFFER_FLUSH_INTERVAL_MS := 100`, `DEFAULT_AGGREGATION_FLUSH_INTERVAL_MS := 2000`, `DEFAULT_SENDER_QUEUE_SIZE := 512`, `DEFAULT_BUFFER_POOL_CAPACITY := 2048` (S6, allium.md §Key Configuration Options)
- [x] **[S6-T08]** Define `DogStatsDConfig` record: `maxBytesPerPayload: nat`, `bufferFlushIntervalMs: nat`, `aggregationFlushIntervalMs: nat`, `senderQueueSize: nat`, `bufferPoolCapacity: nat`, `aggregationEnabled: bool`, `extendedAggregation: bool`, `maxSamplesPerContext: int`, `originDetection: bool`, `cardinality: TagCardinality`
- [x] **[S6-T09]** Define `DefaultConfig()` function returning config with all defaults from allium.md §Key Configuration Options
- [x] **[S6-T10]** Prove `DefaultConfig().maxBytesPerPayload == UDP_MAX_BYTES` lemma (ties constants to config)
- [x] **[S6-T11]** Verify `src/Types.dfy` with `dafny verify src/Types.dfy` — **7 verified, 0 errors**

---

## Phase 2: Error Types (S6)

`src/Errors.dfy`

- [x] **[S6-E01]** Define `DogStatsDError` datatype: `ErrNoClient | ErrorInputChannelFull | ErrorSenderChannelFull | MessageTooLongError` (S6, allium.md §Error Types)
- [x] **[S6-E02]** Define error message function `ErrorMessage(e: DogStatsDError): string` for human-readable descriptions
- [x] **[S6-E03]** Define `Result<T>` as `datatype Result<T> = Ok(value: T) | Err(error: DogStatsDError)` (or use Dafny standard library if available)
- [x] **[S6-E04]** Verify `src/Errors.dfy` with `dafny verify src/Errors.dfy`

---

## Phase 3: Wire Format Serialization (S6)

`src/WireFormat.dfy`

- [ ] **[S6-W01]** Define `WireMetric` record: `name: string`, `value: string`, `metricType: MetricType`, `rate: Option<real>`, `tags: seq<string>`, `containerID: Option<string>`, `externalEnv: Option<string>`, `cardinality: TagCardinality`
- [ ] **[S6-W02]** Implement `SerializeName(name: string): seq<byte>` (name as ASCII bytes)
- [ ] **[S6-W03]** Implement `SerializeValue(value: string): seq<byte>` (value as ASCII bytes)
- [ ] **[S6-W04]** Implement `SerializeType(t: MetricType): seq<byte>` producing `g/c/h/d/s/ms`
- [ ] **[S6-W05]** Implement `SerializeRate(rate: Option<real>): seq<byte>` — empty if None or rate==1.0; `|@<rate>` if rate < 1.0 (S3, allium.md §Wire Format Ordering R3)
- [ ] **[S6-W06]** Implement `SerializeTags(tags: seq<string>): seq<byte>` — empty if no tags; `|#tag1,tag2,...` if present (S3, allium.md §Wire Format Ordering R4)
- [ ] **[S6-W07]** Implement `SerializeContainerID(cid: Option<string>): seq<byte>` — `|c:<cid>` if Some (S3, allium.md §Wire Format Ordering R5)
- [ ] **[S6-W08]** Implement `SerializeExternalEnv(env: Option<string>): seq<byte>` — `|e:<env>` if Some and non-empty (S3, allium.md §Wire Format Ordering R6)
- [ ] **[S6-W09]** Implement `SerializeCardinality(c: TagCardinality): seq<byte>` — `|card:<level>` if not CardinalityNotSet (S3, allium.md §Wire Format Ordering R7)
- [ ] **[S6-W10]** Implement `SerializeWireFormat(m: WireMetric): seq<byte>` composing all fields in exact order: `name:value|type[|@rate][|#tags][|c:cid][|e:env][|card:x]\n` (S3-R3.1, allium.md §Wire Format Ordering)
- [ ] **[S6-W11]** Prove `MetricOrderingLemma`: result of `SerializeWireFormat` starts with `name:value|type` prefix — verifies field ordering invariant (allium.md §MetricOrdering cross-invariant)
- [ ] **[S6-W12]** Prove `SerializeWireFormatTerminates`: function is total (always returns a value, never loops)
- [ ] **[S6-W13]** Prove `SerializeWireFormatEndsWithNewline`: last byte is `\n` (0x0A)
- [ ] **[S6-W14]** Prove `SerializeRateEmpty`: if rate is None or equals 1.0, rate field is absent from output
- [ ] **[S6-W15]** Prove `SerializeTagsEmpty`: if tags is empty seq, tag field is absent from output
- [ ] **[S6-W16]** Prove `SerializeWireFormatBounded(m: WireMetric, maxSize: nat)`: precondition that metric serializes within maxSize (used in buffer write precondition)
- [x] **[S6-W17]** Verify `src/WireFormat.dfy` with `dafny verify src/WireFormat.dfy`

---

## Phase 4: Buffer (S3)

`src/Buffer.dfy`

- [ ] **[S3-B01]** Define `Buffer` class/record: `data: seq<byte>`, `len: nat`, `maxSize: nat`, `elementCount: nat`, `maxElements: nat` (TLA+: `bufferLen`, `elementCount`)
- [ ] **[S3-B02]** Define `Buffer.Valid()` predicate: `len <= maxSize && elementCount <= maxElements && |data| == maxSize` (TLA+ invariant: `BufferNotOverflow`)
- [ ] **[S3-B03]** Implement `Buffer.New(maxSize: nat, maxElements: nat): Buffer` constructor — returns empty buffer, proves Valid()
- [ ] **[S3-B04]** Implement `Buffer.WriteMetric(metric: seq<byte>): Result<(), DogStatsDError>` — transactional append (S3-R3.1, R3.2)
  - Precondition: `Valid()`
  - If `len + |metric| > maxSize`: return `Err(ErrorSenderChannelFull)`, buffer UNCHANGED (S3-R3.2: rollback)
  - If `elementCount >= maxElements`: return `Err(ErrorSenderChannelFull)`, buffer UNCHANGED
  - Otherwise: append metric bytes, increment `len` and `elementCount`, return `Ok(())`
  - Postcondition: `Valid()`
- [ ] **[S3-B05]** Prove `WriteMetricRollback`: if result is Err, `buf == old(buf)` — buffer fully unchanged (TLA+ `TransactionalWrites`, I3.3)
- [ ] **[S3-B06]** Prove `WriteMetricAppend`: if result is Ok, `buf.len == old(buf.len) + |metric|` and `buf.elementCount == old(buf.elementCount) + 1`
- [ ] **[S3-B07]** Prove `WriteMetricPreservesValid`: WriteMetric preserves `Valid()` in all cases
- [ ] **[S3-B08]** Prove `NoBufferOverflow`: `buf.len <= buf.maxSize` is invariant of all Buffer operations (TLA+ `BufferNotOverflow`)
- [ ] **[S3-B09]** Prove `NoElementOverflow`: `buf.elementCount <= buf.maxElements` is invariant (TLA+ `elementCount <= MaxBufferElements`)
- [ ] **[S3-B10]** Implement `Buffer.Reset()` — sets `len = 0`, `elementCount = 0`, `data = seq of zeros`; postcondition: Valid(), len == 0
- [ ] **[S3-B11]** Prove `ResetProducesEmpty`: after Reset(), `len == 0 && elementCount == 0`
- [ ] **[S3-B12]** Implement `Buffer.IsEmpty(): bool` — returns `len == 0`
- [ ] **[S3-B13]** Implement `Buffer.Bytes(): seq<byte>` — returns `data[..len]` (the live portion)
- [ ] **[S3-B14]** Verify `src/Buffer.dfy` with `dafny verify src/Buffer.dfy`

---

## Phase 5: Buffer Pool (S3)

`src/BufferPool.dfy`

- [ ] **[S3-P01]** Define `BufferPool` class: `pool: seq<Buffer>`, `capacity: nat` (TLA+: `poolSize`, `BufferPoolCapacity`)
- [ ] **[S3-P02]** Define `BufferPool.Valid()` predicate: `|pool| <= capacity`  (TLA+ `poolSize <= BufferPoolCapacity`, I3.4)
- [ ] **[S3-P03]** Implement `BufferPool.New(capacity: nat, bufferMaxSize: nat, bufferMaxElements: nat): BufferPool` — pre-fills pool to capacity with empty buffers
- [ ] **[S3-P04]** Implement `BufferPool.Borrow(): Option<Buffer>` — non-blocking: returns `Some(b)` if pool non-empty, pops it; returns `None` if pool empty (S3-R3.4)
  - Never blocks; never fails
  - Postcondition: `Valid()`, `|result.pool| == old(|result.pool|) - 1` if Some
- [ ] **[S3-P05]** Prove `BorrowNeverBlocks`: Borrow() always returns immediately (total function)
- [ ] **[S3-P06]** Implement `BufferPool.Return(b: Buffer)` — non-blocking: if `|pool| < capacity`, push b to pool; else discard (S3-R3.5)
  - Postcondition: `Valid()`
- [ ] **[S3-P07]** Prove `ReturnRespectsCapacity`: after Return, `|pool| <= capacity` (TLA+ I3.4: pool never exceeds capacity)
- [ ] **[S3-P08]** Prove `ReturnDiscardWhenFull`: if `|old(pool)| == capacity`, Return() leaves pool size unchanged
- [ ] **[S3-P09]** Verify `src/BufferPool.dfy` with `dafny verify src/BufferPool.dfy`

---

## Phase 6: Aggregator (S2)

`src/Aggregator.dfy`

- [ ] **[S2-A01]** Define `AggregatorState` datatype: `Running | Stopped` (TLA+: `aggregatorState`)
- [ ] **[S2-A02]** Define `CountShard` as `map<MetricContext, int>` — maps context to accumulated count (TLA+: `countShards[s][ctx]`)
- [ ] **[S2-A03]** Define `GaugeShard` as `map<MetricContext, real>` — maps context to last-written gauge value (TLA+: `gaugeShards[s][ctx]`)
- [ ] **[S2-A04]** Define `SetShard` as `map<MetricContext, set<string>>` — maps context to deduplicated set (TLA+: `setShards[s][ctx]`)
- [ ] **[S2-A05]** Define `BufferedMetricState` record: `samples: seq<real>`, `totalSamples: nat` — for reservoir sampling (TLA+: `bufferedCount[ctx]`)
- [ ] **[S2-A06]** Define `Aggregator` class: `state: AggregatorState`, `countShards: seq<CountShard>`, `gaugeShards: seq<GaugeShard>`, `setShards: seq<SetShard>`, `buffered: map<MetricContext, BufferedMetricState>`, `shardCount: nat`, `ghost metricsSubmitted: set<MetricContext>`
- [ ] **[S2-A07]** Define `Aggregator.Valid()` predicate: state ∈ {Running, Stopped}, |countShards| == shardCount, etc.
- [ ] **[S2-A08]** Implement FNV-1a shard function `ShardIndex(ctx: MetricContext, shardCount: nat): nat` — deterministic, returns value in `[0, shardCount)` (allium.md §ShardingDeterminism)
- [ ] **[S2-A09]** Prove `ShardIndexDeterministic`: same context always maps to same shard index (allium.md §ShardingDeterminism invariant)
- [ ] **[S2-A10]** Prove `ShardIndexInBounds`: `ShardIndex(ctx, n) < n` for all `n > 0`
- [ ] **[S2-A11]** Implement `Aggregator.SampleCount(ctx: MetricContext, value: nat)` — precondition: `state == Running`; postcondition: count[ctx] increased by value (S2-R2.1, TLA+: SampleCount)
- [ ] **[S2-A12]** Prove `SampleCountPreservesRunning`: SampleCount only allowed when Running (I2.1 contrapositive: Stopped ⟹ no new counts)
- [ ] **[S2-A13]** Prove `CountsNonNegative`: all count values remain ≥ 0 after SampleCount (I2.3)
- [ ] **[S2-A14]** Prove `CountsIncrementOnly`: after SampleCount, `count[ctx] >= old(count[ctx])` (I2.3)
- [ ] **[S2-A15]** Implement `Aggregator.SampleGauge(ctx: MetricContext, value: real)` — precondition: `state == Running`; postcondition: gauge[ctx] == value (last-write-wins) (S2-R2.2, TLA+: implicit SampleGauge)
- [ ] **[S2-A16]** Prove `GaugeLastWriteWins`: after SampleGauge, `gauge[ctx] == value` (not accumulated) (I2.4)
- [ ] **[S2-A17]** Implement `Aggregator.SampleSet(ctx: MetricContext, value: string)` — precondition: `state == Running`; postcondition: value ∈ set[ctx] (S2-R2.3)
- [ ] **[S2-A18]** Prove `SetDeduplication`: after SampleSet, `|set[ctx]|` unchanged if value already present (I2.5)
- [ ] **[S2-A19]** Implement `Aggregator.SampleBuffered(ctx: MetricContext, value: real, maxSamples: int)` — precondition: `state == Running`; apply reservoir sampling (S2-R2.4, I2.6)
- [ ] **[S2-A20]** Prove `BufferedTotalSamplesMonotone`: `totalSamples[ctx]` only increases after SampleBuffered (I2.6)
- [ ] **[S2-A21]** Implement `Aggregator.Flush(): seq<WireMetric>` — precondition: `state == Running`; emit one WireMetric per context with non-zero/non-empty state; reset all shards to zero/empty (S2-R2.5, TLA+: AggregatorFlush)
- [ ] **[S2-A22]** Prove `FlushEmitsOnePerContext`: each context appears at most once in Flush() output (I2.2)
- [ ] **[S2-A23]** Prove `FlushResetsShards`: after Flush(), all count values == 0, all gauge values == 0.0, all sets == {} (TLA+: AggregatorFlush resets state)
- [ ] **[S2-A24]** Implement `Aggregator.Stop()` — sets `state = Stopped`; postcondition: `state == Stopped` (S2-R2.6, TLA+: ClientClose sets aggregatorState = Stopped)
- [ ] **[S2-A25]** Prove `StopPreventsNewSamples`: after Stop(), all Sample* methods are disabled (precondition fails) (I2.1)
- [ ] **[S2-A26]** Prove `StopIsTerminal`: state never transitions from Stopped back to Running
- [ ] **[S2-A27]** Verify `src/Aggregator.dfy` with `dafny verify src/Aggregator.dfy`

---

## Phase 7: Init Singletons (S5)

`src/Singletons.dfy`

- [ ] **[S5-S01]** Define `InitState` datatype: `Unset | Set` (TLA+: `containerIDState`, `externalEnvState`)
- [ ] **[S5-S02]** Define `Singleton<T>` record: `state: InitState`, `value: T`, `ghost initialized: bool`
- [ ] **[S5-S03]** Define `Singleton.Valid()` predicate: `state == Set ⟺ initialized`, value is meaningful only when Set
- [ ] **[S5-S04]** Implement `ContainerID` singleton: `state: InitState`, `value: string`
- [ ] **[S5-S05]** Implement `ContainerID.Init(value: string)` — precondition: `state == Unset`; postcondition: `state == Set && this.value == value` (S5-R5.1, TLA+: InitContainerID)
- [ ] **[S5-S06]** Prove `ContainerIDInitOnce`: `Init()` requires `state == Unset`; after Init, `state == Set` and cannot Init again (I5.1, TLA+ InitContainerID guard)
- [ ] **[S5-S07]** Prove `ContainerIDImmutable`: after `state == Set`, value never changes (I5.1)
- [ ] **[S5-S08]** Implement `ContainerID.Get(): Option<string>` — returns `None` if Unset, `Some(value)` if Set; pure, no side effects (S5-R5.3)
- [ ] **[S5-S09]** Prove `ContainerIDReadConsistent`: `Get()` returns same value on every call once Set (I5.3)
- [ ] **[S5-S10]** Implement `ExternalEnv` singleton: `state: InitState`, `value: string`
- [ ] **[S5-S11]** Implement `SanitizeExternalEnv(raw: string): string` — removes all non-printable characters and `|` characters (S5-R5.2, allium.md §Init External Env)
- [ ] **[S5-S12]** Prove `SanitizeRemovesPipe`: `'|' ∉ SanitizeExternalEnv(s)` for all s (allium.md §Init External Env sanitization)
- [ ] **[S5-S13]** Prove `SanitizePrintableOnly`: all chars in `SanitizeExternalEnv(s)` are printable (allium.md §Init External Env sanitization)
- [ ] **[S5-S14]** Implement `ExternalEnv.Init(raw: string)` — precondition: `state == Unset`; stores `SanitizeExternalEnv(raw)` (S5-R5.2, TLA+: InitExternalEnv)
- [ ] **[S5-S15]** Prove `ExternalEnvInitOnce`: Init() requires Unset; after Init, cannot Init again (I5.2)
- [ ] **[S5-S16]** Prove `ExternalEnvImmutable`: after Set, value never changes (I5.2)
- [ ] **[S5-S17]** Implement `ExternalEnv.Get(): string` — returns `""` if Unset, stored value if Set (S5-R5.4)
- [ ] **[S5-S18]** Prove `ExternalEnvReadConsistency`: once Set, Get() always returns same value (I5.3)
- [ ] **[S5-S19]** Prove `InitStateMonotone`: `state` only transitions `Unset → Set`, never `Set → Unset` (TLA+: NoReversal invariant)
- [ ] **[S5-S20]** Verify `src/Singletons.dfy` with `dafny verify src/Singletons.dfy`

---

## Phase 8: Sender and Transport (S4)

`src/Sender.dfy`

- [ ] **[S4-R01]** Define `SenderState` datatype: `Running | Stopped` (TLA+: `senderState`)
- [ ] **[S4-R02]** Define `Transport` trait/interface: `Write(data: seq<byte>): Result<nat, DogStatsDError>`, `Close(): Result<(), DogStatsDError>` (S4, allium.md §Transport Implementations)
- [ ] **[S4-R03]** Define `Telemetry` record: `payloadsSent: nat`, `payloadsDropped: nat`, `bytesSent: nat`, `bytesDropped: nat` — all nat (monotonic increments only) (S4, allium.md §Telemetry Counters)
- [ ] **[S4-R04]** Define `Sender` class: `state: SenderState`, `queue: seq<Buffer>`, `maxQueueSize: nat`, `telemetry: Telemetry`, `ghost transportClosed: bool`
- [ ] **[S4-R05]** Define `Sender.Valid()` predicate: `|queue| <= maxQueueSize`, `state ∈ {Running, Stopped}`, `(state == Stopped) ==> transportClosed` (TLA+: QueueNotOverflow, I4.4)
- [ ] **[S4-R06]** Implement `Sender.New(maxQueueSize: nat): Sender` — state = Running, empty queue, zero telemetry (TLA+: Init senderState = Running, queueLen = 0)
- [ ] **[S4-R07]** Implement `Sender.Enqueue(b: Buffer): Result<(), DogStatsDError>` — non-blocking: if `|queue| < maxQueueSize`, append; else increment `payloadsDropped` and `bytesDropped` and return `Err(ErrorSenderChannelFull)` (S4-R4.2, TLA+: EnqueueBuffer)
  - Precondition: `state == Running`
  - Postcondition: `Valid()`, `|queue| <= maxQueueSize`
- [ ] **[S4-R08]** Prove `EnqueueNoOverflow`: `|queue| <= maxQueueSize` after Enqueue in all cases (TLA+ `QueueNotOverflow`, I4.1)
- [ ] **[S4-R09]** Prove `EnqueueDropsWhenFull`: if `|queue| == maxQueueSize`, Enqueue returns Err and queue unchanged (TLA+ EnqueueBuffer drop branch)
- [ ] **[S4-R10]** Prove `TelemetryDropMonotone`: `payloadsDropped` and `bytesDropped` only increase (allium.md §Telemetry Counters)
- [ ] **[S4-R11]** Implement `Sender.Send(transport: Transport): Result<(), DogStatsDError>` — dequeue one buffer, call `transport.Write(buffer.Bytes())`; on success increment `payloadsSent` and `bytesSent`; on failure increment `payloadsDropped` and `bytesDropped`; do NOT retry (S4-R4.3, R4.4, TLA+: SendFromQueue)
  - Precondition: `state == Running`, `|queue| > 0`
  - Postcondition: `|queue| == old(|queue|) - 1`
- [ ] **[S4-R12]** Prove `SendNoRetry`: each buffer dequeued and attempted exactly once, regardless of transport result (I4.2, allium.md §I4.2)
- [ ] **[S4-R13]** Prove `TelemetrySentMonotone`: `payloadsSent` and `bytesSent` only increase
- [ ] **[S4-R14]** Implement `Sender.Stop(transport: Transport)` — set `state = Stopped`, drain queue by calling `Send()` for each remaining buffer, then call `transport.Close()` exactly once (S4-R4.6, TLA+: ClientClose sets senderState = Stopped)
  - Postcondition: `state == Stopped`, `|queue| == 0`, `transportClosed == true`
- [ ] **[S4-R15]** Prove `StopTransportClosedOnce`: `transport.Close()` called exactly once during Stop() (I4.4)
- [ ] **[S4-R16]** Prove `StopDrainsQueue`: after Stop(), `|queue| == 0` (allium.md §ClosureFinality: all pending sent)
- [ ] **[S4-R17]** Prove `StopIsTerminal`: state never transitions from Stopped to Running
- [ ] **[S4-R18]** Verify `src/Sender.dfy` with `dafny verify src/Sender.dfy`

---

## Phase 9: Client Lifecycle (S1)

`src/Client.dfy`

- [ ] **[S1-C01]** Define `ClientState` datatype: `Open | Closed` (TLA+: `clientState`)
- [ ] **[S1-C02]** Define `Client` class: `state: ClientState`, `aggregator: Aggregator`, `sender: Sender`, `config: DogStatsDConfig`, `containerID: ContainerID`, `externalEnv: ExternalEnv`, `ghost metricsSubmitted: set<MetricContext>`, `ghost metricsInFlight: set<MetricContext>`
- [ ] **[S1-C03]** Define `Client.Valid()` predicate:
  - `state == Closed ==> metricsSubmitted == {}`  (TLA+: ClosedClientNoPendingMetrics)
  - `state == Closed ==> aggregator.state == Stopped`  (TLA+: ClosedClientStoppedAggregator)
  - `state == Closed ==> sender.state == Stopped`  (TLA+: ClosedClientStoppedSender)
  - `aggregator.Valid() && sender.Valid()`
- [ ] **[S1-C04]** Implement `Client.New(config: DogStatsDConfig): Client` — creates client in Open state, initializes aggregator (Running), sender (Running), initializes ExternalEnv singleton (S1-R1.1, TLA+: Init)
  - Postcondition: `state == Open`, `aggregator.state == Running`, `sender.state == Running`, `Valid()`
- [ ] **[S1-C05]** Implement `Client.SubmitGauge(ctx: MetricContext, value: real, rate: real)` — precondition: `state == Open`; returns `Err(ErrNoClient)` if Closed (S1-R1.2, R1.5, TLA+: SubmitMetric)
- [ ] **[S1-C06]** Implement `Client.SubmitCount(ctx: MetricContext, value: nat, rate: real)` — same guards as SubmitGauge (S1-R1.2, R1.5)
- [ ] **[S1-C07]** Implement `Client.SubmitSet(ctx: MetricContext, value: string, rate: real)` — same guards (S1-R1.2, R1.5)
- [ ] **[S1-C08]** Implement `Client.SubmitHistogram(ctx: MetricContext, value: real, rate: real)` — same guards; routes to aggregator SampleBuffered if aggregation enabled (S1-R1.2, S2-R2.4)
- [ ] **[S1-C09]** Implement `Client.SubmitDistribution(ctx: MetricContext, value: real, rate: real)` — same guards (S1-R1.2)
- [ ] **[S1-C10]** Implement `Client.SubmitTiming(ctx: MetricContext, value: real, rate: real)` — same guards (S1-R1.2)
- [ ] **[S1-C11]** Prove `SubmitRequiresOpen`: all Submit* methods have precondition `state == Open` — or return `ErrNoClient` if Closed (S1-R1.5)
- [ ] **[S1-C12]** Prove `ClosedClientNoSubmit`: after Close(), all Submit* methods return `Err(ErrNoClient)` (allium.md §R1.5)
- [ ] **[S1-C13]** Implement `Client.Flush(): Result<(), DogStatsDError>` — precondition: `state == Open`; flushes aggregator, flushes buffer, waits for sender to drain (S1-R1.3, TLA+: ClientFlush)
- [ ] **[S1-C14]** Prove `FlushRequiresOpen`: Flush returns `Err(ErrNoClient)` if `state == Closed`
- [ ] **[S1-C15]** Implement `Client.Close(): Result<(), DogStatsDError>` — transitions Open → Closed; flushes all pending metrics; stops aggregator; stops sender (S1-R1.4, TLA+: ClientClose)
  - Postcondition: `state == Closed`, `aggregator.state == Stopped`, `sender.state == Stopped`, `metricsSubmitted == {}`
- [ ] **[S1-C16]** Prove `CloseTransitionsState`: after Close(), `state == Closed` (S1-R1.4)
- [ ] **[S1-C17]** Prove `CloseStopsAggregator`: after Close(), `aggregator.state == Stopped` (TLA+: ClosedClientStoppedAggregator)
- [ ] **[S1-C18]** Prove `CloseStopsSender`: after Close(), `sender.state == Stopped` (TLA+: ClosedClientStoppedSender)
- [ ] **[S1-C19]** Prove `ClosureFinality`: state never transitions from Closed to Open (allium.md §ClosureFinality)
- [ ] **[S1-C20]** Prove `ClosedClientNoPendingMetrics`: `state == Closed ==> metricsSubmitted == {}` (TLA+: ClosedClientNoPendingMetrics)
- [ ] **[S1-C21]** Implement `Client.IsClosed(): bool` — pure function, returns `state == Closed`, no side effects (S1-R1.6)
- [ ] **[S1-C22]** Prove `IsClosedPure`: `IsClosed()` does not modify any state (S1-R1.6)
- [ ] **[S1-C23]** Prove `ClientOpenInvariant`: while `state == Open`, submitted metrics are either in pipeline or dropped (never silently lost without telemetry update) — ghost proof using metricsSubmitted/metricsInFlight (allium.md §ClientOpenInvariant)
- [ ] **[S1-C24]** Verify `src/Client.dfy` with `dafny verify src/Client.dfy`

---

## Phase 10: Cross-Subsystem Integration Proofs

`src/Client.dfy` (additional lemmas) or `src/Invariants.dfy`

- [ ] **[CX-01]** Prove `MetricOrderingGlobal`: every buffer sent through the pipeline contains metrics serialized with fields in exact spec-mandated order (allium.md §MetricOrdering) — links WireFormat.dfy to Buffer.dfy to Sender.dfy
- [ ] **[CX-02]** Prove `BufferTransactionalityGlobal`: no partial metric write ever reaches the transport (allium.md §BufferTransactionality) — uses WriteMetricRollback + EnqueueBuffer + Send chain
- [ ] **[CX-03]** Prove `AggregationSemanticsGlobal`: counts accumulate, gauges are last-write-wins, sets are deduplicated in all reachable states (allium.md §AggregationSemantics)
- [ ] **[CX-04]** Prove `OnceInitializationGlobal`: ContainerID and ExternalEnv are never re-initialized after first Set (allium.md §OnceInitialization)
- [ ] **[CX-05]** Prove `ClosureFinalityGlobal`: after Close(), no metric submission, aggregation, buffering, or sending can occur (allium.md §ClosureFinality)
- [ ] **[CX-06]** Prove `ShardingDeterminismGlobal`: FNV-1a shard assignment is deterministic — same context maps to same shard on every call (allium.md §ShardingDeterminism)
- [ ] **[CX-07]** Verify `src/Invariants.dfy` (or integrated proofs in Client.dfy) with `dafny verify`

---

## Phase 11: Tests

`test/TestS1.dfy` — Client Lifecycle

- [ ] **[T-S1-01]** `{:test} TestNewClientIsOpen()`: `Client.New()` returns client with `state == Open` (rust-contract.md §S1 test_new_client_is_open)
- [ ] **[T-S1-02]** `{:test} TestGaugeOnOpenSucceeds()`: SubmitGauge returns Ok when state == Open
- [ ] **[T-S1-03]** `{:test} TestGaugeOnClosedReturnsError()`: SubmitGauge returns Err(ErrNoClient) after Close() (rust-contract.md §test_gauge_on_closed_client_returns_error)
- [ ] **[T-S1-04]** `{:test} TestCloseIdempotent()`: second Close() call succeeds or is no-op (rust-contract.md §test_close_idempotent)
- [ ] **[T-S1-05]** `{:test} TestIsClosedReflectsState()`: IsClosed() returns false before Close(), true after
- [ ] **[T-S1-06]** `{:test} TestFlushOnOpenSendsPending()`: Flush() succeeds when Open
- [ ] **[T-S1-07]** `{:test} TestFlushOnClosedReturnsError()`: Flush() returns error when Closed
- [ ] **[T-S1-08]** `{:test} TestAllMetricTypesOnClosed()`: all six Submit* methods return ErrNoClient when Closed

`test/TestS2.dfy` — Aggregator

- [ ] **[T-S2-01]** `{:test} TestCountAccumulates()`: SampleCount twice on same context = sum of both values
- [ ] **[T-S2-02]** `{:test} TestGaugeOverwrites()`: SampleGauge twice = second value wins (rust-contract.md §test_gauge_overwrites)
- [ ] **[T-S2-03]** `{:test} TestSetDeduplicates()`: SampleSet same value twice = set size unchanged
- [ ] **[T-S2-04]** `{:test} TestFlushEmitsOnePerContext()`: Flush() output has at most one entry per MetricContext (I2.2)
- [ ] **[T-S2-05]** `{:test} TestStopPreventsFurtherSamples()`: SampleCount after Stop() fails precondition / returns error
- [ ] **[T-S2-06]** `{:test} TestShardingIsDeterministic()`: ShardIndex(ctx, n) returns same value on repeated calls

`test/TestS3.dfy` — Buffer and Pool

- [ ] **[T-S3-01]** `{:test} TestWriteWithinCapacity()`: WriteMetric succeeds and len increases by metric size
- [ ] **[T-S3-02]** `{:test} TestWriteOverflowRollsBack()`: WriteMetric returns error when len + size > maxSize; buffer len unchanged (I3.3)
- [ ] **[T-S3-03]** `{:test} TestElementCountOverflowRollsBack()`: WriteMetric returns error when elementCount == maxElements; buffer unchanged
- [ ] **[T-S3-04]** `{:test} TestFlushBufferResetsToEmpty()`: Reset() produces empty buffer (len == 0, elementCount == 0)
- [ ] **[T-S3-05]** `{:test} TestPoolBorrowNeverBlocks()`: Borrow() returns None on empty pool (no hang)
- [ ] **[T-S3-06]** `{:test} TestPoolReturnRespectsCapacity()`: Return() to full pool leaves pool size unchanged (I3.4)
- [ ] **[T-S3-07]** `{:test} TestTransactionalWritesAllOrNothing()`: two writes where second overflows — first write survives in buffer, second rolled back

`test/TestS4.dfy` — Sender

- [ ] **[T-S4-01]** `{:test} TestEnqueueSucceedsIfQueueOpen()`: Enqueue on Running sender with space succeeds
- [ ] **[T-S4-02]** `{:test} TestEnqueueDropsIfQueueFull()`: Enqueue when `|queue| == maxQueueSize` returns Err, telemetry incremented (I4.1)
- [ ] **[T-S4-03]** `{:test} TestTelemetryIncrementsOnDrop()`: payloadsDropped increases by 1 per dropped buffer
- [ ] **[T-S4-04]** `{:test} TestSendNoRetry()`: Send calls transport.Write exactly once per buffer regardless of result (I4.2)
- [ ] **[T-S4-05]** `{:test} TestStopDrainsQueue()`: after Stop(), queue is empty
- [ ] **[T-S4-06]** `{:test} TestTransportCloseCalledOnStop()`: transport.Close() called exactly once during Stop() (I4.4)
- [ ] **[T-S4-07]** `{:test} TestQueueNeverOverflows()`: repeated Enqueue calls never push queueLen above maxQueueSize

`test/TestS5.dfy` — Init Singletons

- [ ] **[T-S5-01]** `{:test} TestContainerIDInitializedOnce()`: second Init() call fails precondition (I5.1)
- [ ] **[T-S5-02]** `{:test} TestContainerIDImmutableAfterSet()`: Get() returns same value on every call after Init
- [ ] **[T-S5-03]** `{:test} TestExternalEnvInitializedOnce()`: second Init() call fails precondition (I5.2)
- [ ] **[T-S5-04]** `{:test} TestExternalEnvReadConsistency()`: Get() consistent after Init
- [ ] **[T-S5-05]** `{:test} TestSanitizeRemovesPipe()`: SanitizeExternalEnv strips `|` from raw value
- [ ] **[T-S5-06]** `{:test} TestSanitizeRemovesNonPrintable()`: SanitizeExternalEnv strips control chars
- [ ] **[T-S5-07]** `{:test} TestExternalEnvUnsetReturnsEmpty()`: Get() on Unset ExternalEnv returns `""`

`test/TestS6.dfy` — Wire Format

- [ ] **[T-S6-01]** `{:test} TestSerializeGauge()`: output matches `"name:1.5|g\n"` for gauge with no rate/tags/extras
- [ ] **[T-S6-02]** `{:test} TestSerializeCount()`: output matches `"name:42|c\n"`
- [ ] **[T-S6-03]** `{:test} TestSerializeWithRate()`: rate 0.5 appends `|@0.5` before tags field
- [ ] **[T-S6-04]** `{:test} TestSerializeWithTags()`: tags `["env:prod","host:foo"]` appends `|#env:prod,host:foo`
- [ ] **[T-S6-05]** `{:test} TestSerializeWithContainerID()`: containerID `"abc123"` appends `|c:abc123`
- [ ] **[T-S6-06]** `{:test} TestSerializeWithExternalEnv()`: externalEnv `"k8s"` appends `|e:k8s`
- [ ] **[T-S6-07]** `{:test} TestSerializeWithCardinality()`: cardinality Low appends `|card:low`
- [ ] **[T-S6-08]** `{:test} TestSerializeFieldOrder()`: all fields present in exact spec-mandated order
- [ ] **[T-S6-09]** `{:test} TestSerializeRateOneOmitted()`: rate == 1.0 produces no `|@` field
- [ ] **[T-S6-10]** `{:test} TestSerializeEmptyTagsOmitted()`: empty tags seq produces no `|#` field
- [ ] **[T-S6-11]** `{:test} TestSerializeEndsWithNewline()`: every serialized metric ends with `\n`
- [ ] **[T-S6-12]** Run all tests with `dafny test test/TestS6.dfy`

---

## Phase 12: Final Verification Pass

- [x] **[FV-01]** `dafny verify src/Types.dfy` — zero errors (7 verified)
- [ ] **[FV-02]** `dafny verify src/Errors.dfy` — zero errors
- [ ] **[FV-03]** `dafny verify src/WireFormat.dfy` — zero errors
- [ ] **[FV-04]** `dafny verify src/Buffer.dfy` — zero errors
- [ ] **[FV-05]** `dafny verify src/BufferPool.dfy` — zero errors
- [ ] **[FV-06]** `dafny verify src/Aggregator.dfy` — zero errors
- [ ] **[FV-07]** `dafny verify src/Singletons.dfy` — zero errors
- [ ] **[FV-08]** `dafny verify src/Sender.dfy` — zero errors
- [ ] **[FV-09]** `dafny verify src/Client.dfy` — zero errors
- [ ] **[FV-10]** `dafny verify src/*.dfy` — whole-project verification, zero errors
- [ ] **[FV-11]** `dafny test test/TestS1.dfy` through `test/TestS6.dfy` — all tests pass
- [ ] **[FV-12]** Audit each Dafny `assume` statement — all must be eliminated or justified with a spec citation
- [ ] **[FV-13]** Cross-check every TLA+ invariant from `spec/model.tla` (`Inv` conjunction) has a corresponding Dafny lemma or predicate

---

## Spec Invariant Coverage Matrix

| TLA+ Invariant | Dafny Proof | Status |
|---|---|---|
| `ClosedClientNoPendingMetrics` | `Client.Valid()` + S1-C20 | [ ] |
| `ClosedClientStoppedAggregator` | `Client.Valid()` + S1-C17 | [ ] |
| `ClosedClientStoppedSender` | `Client.Valid()` + S1-C18 | [ ] |
| `BufferNotOverflow` (bufferLen <= maxSize) | S3-B08 | [ ] |
| `elementCount <= MaxBufferElements` | S3-B09 | [ ] |
| `poolSize <= BufferPoolCapacity` | S3-P07 | [ ] |
| `QueueNotOverflow` (queueLen <= senderQueueSize) | S4-R08 | [ ] |
| `InitStateConsistent` | S5-S03 + S5-S19 | [ ] |
| `NoContainerIDChange` (I5.1) | S5-S07 | [ ] |
| `NoExternalEnvChange` (I5.2) | S5-S16 | [ ] |
| `TransactionalWrites` (I3.3) | S3-B05 | [ ] |
| `MetricOrdering` (S6) | S6-W11 + CX-01 | [ ] |
| `AggregationSemantics` | S2-A16 + S2-A18 + S2-A14 | [ ] |
| `ClosureFinality` | S1-C19 + CX-05 | [ ] |
| `ShardingDeterminism` | S2-A09 | [ ] |
| `OnceInitialization` | S5-S06 + S5-S15 + CX-04 | [ ] |
