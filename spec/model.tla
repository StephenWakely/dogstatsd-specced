--------------------------- MODULE Model ---------------------------
\* Composite TLA+ model for datadog-go DogStatsD client.
\* This model orchestrates five subsystems:
\* S1: Client lifecycle
\* S2: Aggregator
\* S3: Worker and buffer
\* S4: Sender and transport
\* S5: Init singletons (container ID and external env)

EXTENDS Naturals, FiniteSets, Sequences

\* Import individual subsystem modules logically
\* (In a real TLA+ Toolbox, these would use EXTENDS or instance imports)

CONSTANTS
  MetricContexts,
  MetricTypes,
  AggregatorShards,
  MaxBufferSize,
  MaxBufferElements,
  BufferPoolCapacity,
  SenderQueueSize,
  MaxCountValue,
  ContainerIDValues,
  ExternalEnvValues,
  MetricSizes,
  MaxPayloads

\* Composite variables: union of all subsystems

\* S1: Client lifecycle
VARIABLES clientState, metricsSubmitted, metricsInFlight

\* S2: Aggregator
VARIABLES aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred

\* S3: Worker and buffer
VARIABLES bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed

\* S4: Sender and transport
VARIABLES senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped

\* S5: Init singletons
VARIABLES containerIDState, containerIDValue, externalEnvState, externalEnvValue

vars == <<
  clientState, metricsSubmitted, metricsInFlight,
  aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
  bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
  senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
  containerIDState, containerIDValue, externalEnvState, externalEnvValue
>>

\* Initialization

Init ==
  /\ clientState = "Open"
  /\ metricsSubmitted = {}
  /\ metricsInFlight = {}
  /\ aggregatorState = "Running"
  /\ countShards = [s \in 1..AggregatorShards |-> [ctx \in MetricContexts |-> 0]]
  /\ gaugeShards = [s \in 1..AggregatorShards |-> [ctx \in MetricContexts |-> 0]]
  /\ setShards = [s \in 1..AggregatorShards |-> [ctx \in MetricContexts |-> {}]]
  /\ bufferedCount = [ctx \in MetricContexts |-> 0]
  /\ flushOccurred = FALSE
  /\ bufferLen = 0
  /\ elementCount = 0
  /\ poolSize = BufferPoolCapacity
  /\ lastRollbackLen = 0
  /\ transactionFailed = FALSE
  /\ senderState = "Running"
  /\ queueLen = 0
  /\ transportOpen = TRUE
  /\ payloadsSent = 0
  /\ payloadsDropped = 0
  /\ bytesSent = 0
  /\ bytesDropped = 0
  /\ containerIDState = "Unset"
  /\ containerIDValue = ""
  /\ externalEnvState = "Unset"
  /\ externalEnvValue = ""

\* Actions: Subsystem 1 (Client Lifecycle)

SubmitMetric(m) ==
  /\ clientState = "Open"
  /\ m \in MetricContexts
  /\ metricsSubmitted' = metricsSubmitted \cup {m}
  /\ UNCHANGED <<
    clientState, metricsInFlight,
    aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

ClientFlush ==
  /\ clientState = "Open"
  /\ metricsInFlight' = metricsInFlight \cup metricsSubmitted
  /\ metricsSubmitted' = {}
  /\ UNCHANGED <<
    clientState,
    aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

ClientClose ==
  /\ clientState = "Open"
  /\ clientState' = "Closed"
  /\ metricsInFlight' = metricsInFlight \cup metricsSubmitted
  /\ metricsSubmitted' = {}
  /\ aggregatorState' = "Stopped"
  /\ senderState' = "Stopped"
  /\ UNCHANGED <<
    countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

\* Actions: Subsystem 2 (Aggregator)

SampleCount(ctx, value) ==
  /\ aggregatorState = "Running"
  /\ 0 < value /\ value <= MaxCountValue
  /\ LET s == (CHOOSE s \in 1..AggregatorShards: TRUE)
     IN countShards' = [countShards EXCEPT ![s][ctx] = @ + value]
  /\ UNCHANGED <<
    clientState, metricsSubmitted, metricsInFlight,
    aggregatorState, gaugeShards, setShards, bufferedCount, flushOccurred,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

AggregatorFlush ==
  /\ aggregatorState = "Running"
  /\ flushOccurred' = TRUE
  /\ countShards' = [s \in 1..AggregatorShards |-> [ctx \in MetricContexts |-> 0]]
  /\ gaugeShards' = [s \in 1..AggregatorShards |-> [ctx \in MetricContexts |-> 0]]
  /\ setShards' = [s \in 1..AggregatorShards |-> [ctx \in MetricContexts |-> {}]]
  /\ bufferedCount' = [ctx \in MetricContexts |-> 0]
  /\ UNCHANGED <<
    clientState, metricsSubmitted, metricsInFlight,
    aggregatorState,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

\* Actions: Subsystem 3 (Worker and Buffer)

WriteMetric(metricSize) ==
  /\ metricSize \in MetricSizes
  /\ bufferLen + metricSize <= MaxBufferSize
  /\ elementCount < MaxBufferElements
  /\ bufferLen' = bufferLen + metricSize
  /\ elementCount' = elementCount + 1
  /\ lastRollbackLen' = bufferLen'
  /\ transactionFailed' = FALSE
  /\ UNCHANGED <<
    clientState, metricsSubmitted, metricsInFlight,
    aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    poolSize,
    senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

FlushBuffer ==
  /\ bufferLen > 0
  /\ bufferLen' = 0
  /\ elementCount' = 0
  /\ transactionFailed' = FALSE
  /\ UNCHANGED <<
    clientState, metricsSubmitted, metricsInFlight,
    aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    poolSize, lastRollbackLen,
    senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

\* Actions: Subsystem 4 (Sender)

EnqueueBuffer(bytes) ==
  /\ senderState = "Running"
  /\ bytes > 0 /\ bytes <= 1000
  /\ IF queueLen < SenderQueueSize
    THEN /\ queueLen' = queueLen + 1
         /\ payloadsDropped' = payloadsDropped
         /\ bytesDropped' = bytesDropped
    ELSE /\ queueLen' = queueLen
         /\ payloadsDropped' = payloadsDropped + 1
         /\ bytesDropped' = bytesDropped + bytes
  /\ UNCHANGED <<
    clientState, metricsSubmitted, metricsInFlight,
    aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    senderState, transportOpen, payloadsSent, bytesSent,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

SendFromQueue(bytes) ==
  /\ senderState = "Running"
  /\ queueLen > 0
  /\ bytes > 0 /\ bytes <= 1000
  /\ IF transportOpen
    THEN /\ queueLen' = queueLen - 1
         /\ payloadsSent' = payloadsSent + 1
         /\ bytesSent' = bytesSent + bytes
         /\ payloadsDropped' = payloadsDropped
         /\ bytesDropped' = bytesDropped
    ELSE /\ queueLen' = queueLen - 1
         /\ payloadsDropped' = payloadsDropped + 1
         /\ bytesDropped' = bytesDropped + bytes
         /\ payloadsSent' = payloadsSent
         /\ bytesSent' = bytesSent
  /\ UNCHANGED <<
    clientState, metricsSubmitted, metricsInFlight,
    aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    senderState, transportOpen,
    containerIDState, containerIDValue, externalEnvState, externalEnvValue
  >>

\* Actions: Subsystem 5 (Init Singletons)

InitContainerID(cid) ==
  /\ containerIDState = "Unset"
  /\ cid \in ContainerIDValues
  /\ containerIDState' = "Set"
  /\ containerIDValue' = cid
  /\ UNCHANGED <<
    clientState, metricsSubmitted, metricsInFlight,
    aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    externalEnvState, externalEnvValue
  >>

InitExternalEnv(env) ==
  /\ externalEnvState = "Unset"
  /\ env \in ExternalEnvValues
  /\ externalEnvState' = "Set"
  /\ externalEnvValue' = env
  /\ UNCHANGED <<
    clientState, metricsSubmitted, metricsInFlight,
    aggregatorState, countShards, gaugeShards, setShards, bufferedCount, flushOccurred,
    bufferLen, elementCount, poolSize, lastRollbackLen, transactionFailed,
    senderState, queueLen, transportOpen, payloadsSent, payloadsDropped, bytesSent, bytesDropped,
    containerIDState, containerIDValue
  >>

\* Next state: nondeterministic choice of any enabled action

Next ==
  \/ \E m \in MetricContexts: SubmitMetric(m)
  \/ ClientFlush
  \/ ClientClose
  \/ \E ctx \in MetricContexts: \E v \in 1..MaxCountValue: SampleCount(ctx, v)
  \/ AggregatorFlush
  \/ \E size \in MetricSizes: WriteMetric(size)
  \/ FlushBuffer
  \/ \E bytes \in 1..1000: EnqueueBuffer(bytes)
  \/ \E bytes \in 1..1000: SendFromQueue(bytes)
  \/ \E cid \in ContainerIDValues: InitContainerID(cid)
  \/ \E env \in ExternalEnvValues: InitExternalEnv(env)

Spec == Init /\ [][Next]_vars

\* Cross-subsystem invariants (state predicates)

\* If client is closed, no pending metrics
ClosedClientNoPendingMetrics ==
  (clientState = "Closed") => (metricsSubmitted = {})

\* If client is closed, aggregator is stopped
ClosedClientStoppedAggregator ==
  (clientState = "Closed") => (aggregatorState = "Stopped")

\* If client is closed, sender is stopped
ClosedClientStoppedSender ==
  (clientState = "Closed") => (senderState = "Stopped")

\* BufferInvariants from S3
BufferNotOverflow ==
  /\ bufferLen <= MaxBufferSize
  /\ elementCount <= MaxBufferElements
  /\ poolSize <= BufferPoolCapacity

\* QueueNotOverflow from S4
QueueNotOverflow ==
  queueLen <= SenderQueueSize

\* Init state consistency
InitStateConsistent ==
  (containerIDState \in {"Unset", "Set"}) /\ (externalEnvState \in {"Unset", "Set"})

Inv ==
  /\ ClosedClientNoPendingMetrics
  /\ ClosedClientStoppedAggregator
  /\ ClosedClientStoppedSender
  /\ BufferNotOverflow
  /\ QueueNotOverflow
  /\ InitStateConsistent

=============================================================================
