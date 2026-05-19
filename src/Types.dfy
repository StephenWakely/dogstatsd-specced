// S6: Core types, constants, and configuration for DogStatsD Dafny client.
module Types {

  // Generic option type (no stdlib in Dafny 3.x)
  datatype Option<T> = None | Some(value: T)

  // S6-T01: Metric types (spec S6, §Wire Format Summary)
  datatype MetricType = Gauge | Count | Histogram | Distribution | Set | Timing

  // S6-T02: Wire format type symbols (spec S6, §Wire Format Summary)
  function method MetricTypeSymbol(t: MetricType): string {
    match t
    case Gauge        => "g"
    case Count        => "c"
    case Histogram    => "h"
    case Distribution => "d"
    case Set          => "s"
    case Timing       => "ms"
  }

  // S6-T03: Transport modes (spec S1, §Entities)
  datatype TransportMode = UDP | UDS | Pipe

  // S6-T04: Tag cardinality levels (spec S6, §Tag Cardinality Levels)
  datatype TagCardinality =
    | CardinalityNotSet
    | CardinalityNone
    | CardinalityLow
    | CardinalityOrchestrator
    | CardinalityHigh

  // S6-T05: Cardinality wire string; None means omit field (spec S6, §Tag Cardinality Levels)
  function method CardinalityString(c: TagCardinality): Option<string> {
    match c
    case CardinalityNotSet      => None
    case CardinalityNone        => Some("none")
    case CardinalityLow         => Some("low")
    case CardinalityOrchestrator => Some("orchestrator")
    case CardinalityHigh        => Some("high")
  }

  // S6-T06: Aggregation key — metric name + tag set (spec S2, §Entities)
  datatype MetricContext = MetricContext(name: string, tags: seq<string>)

  // S6-T07: Size and timing constants (spec S6, §Key Configuration Options)
  const UDP_MAX_BYTES: nat                        := 1432
  const UDS_MAX_BYTES: nat                        := 8192
  const DEFAULT_BUFFER_FLUSH_INTERVAL_MS: nat     := 100
  const DEFAULT_AGGREGATION_FLUSH_INTERVAL_MS: nat := 2000
  const DEFAULT_SENDER_QUEUE_SIZE: nat            := 512
  const DEFAULT_BUFFER_POOL_CAPACITY: nat         := 2048

  // S6-T08: Full client configuration record (spec S6, §Key Configuration Options)
  datatype DogStatsDConfig = DogStatsDConfig(
    maxBytesPerPayload:           nat,
    bufferFlushIntervalMs:        nat,
    aggregationFlushIntervalMs:   nat,
    senderQueueSize:              nat,
    bufferPoolCapacity:           nat,
    aggregationEnabled:           bool,
    extendedAggregation:          bool,
    maxSamplesPerContext:         int,
    originDetection:              bool,
    cardinality:                  TagCardinality
  )

  // S6-T09: Default configuration (spec S6, §Key Configuration Options)
  function method DefaultConfig(): DogStatsDConfig {
    DogStatsDConfig(
      maxBytesPerPayload          := UDP_MAX_BYTES,
      bufferFlushIntervalMs       := DEFAULT_BUFFER_FLUSH_INTERVAL_MS,
      aggregationFlushIntervalMs  := DEFAULT_AGGREGATION_FLUSH_INTERVAL_MS,
      senderQueueSize             := DEFAULT_SENDER_QUEUE_SIZE,
      bufferPoolCapacity          := DEFAULT_BUFFER_POOL_CAPACITY,
      aggregationEnabled          := true,
      extendedAggregation         := false,
      maxSamplesPerContext        := -1,
      originDetection             := true,
      cardinality                 := CardinalityNotSet
    )
  }

  // S6-T10: Prove default payload size equals UDP constant (spec S6, §Key Configuration Options)
  lemma DefaultConfigMaxBytes()
    ensures DefaultConfig().maxBytesPerPayload == UDP_MAX_BYTES
  {}

}
