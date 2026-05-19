# Model Summary: DogStatsD Go Client

Extracted constants, variables, actions, and invariants for TLA+ translation across all subsystems.

---

## Constants (Finite for Model Checking)

| Name | Meaning | Example finite value |
|---|---|---|
| MetricContexts | Set of (name, tags) pairs | {c1, c2, c3} |
| MetricTypes | Supported metric types | {count, gauge, set, histogram, distribution, timing} |
| MaxBufferSize | Maximum bytes per buffer | 1432 (UDP) |
| MaxBufferElements | Maximum metrics per buffer | 100 |
| BufferPoolCapacity | Maximum buffers in pool | 2048 |
| SenderQueueSize | Maximum buffers in sender queue | 512 |
| AggregatorShardCount | Number of aggregator shards | 1 or 2 |
| MaxFailureCount | Maximum consecutive failures (test only) | 3 |
| TransportTypes | Available transports | {UDP, UDS, Pipe} |

---

## Variables (Mutable State)

### Client Lifecycle (S1)
| Name | Type | Initial | Meaning |
|---|---|---|---|
| clientState | Open \| Closed | Open | Client is open or closed |
| metricsSubmitted | Set of Metric | {} | Metrics submitted but not yet sent |
| metricsInFlight | Set of Metric | {} | Metrics in buffer or being sent |

### Aggregator (S2)
| Name | Type | Initial | Meaning |
|---|---|---|---|
| aggregatorState | Running \| Stopped | Running | Aggregator is running or stopped |
| countShards[shard][context] | Int64 | 0 | Accumulated count per context per shard |
| gaugeShards[shard][context] | Float64 | 0.0 | Last-write-wins gauge per context per shard |
| setShards[shard][context] | Set<String> | {} | Unique set values per context per shard |
| bufferedMetrics[context].samples | Seq<Float64> | [] | Reservoir of buffered samples (histogram/distribution/timing) |
| bufferedMetrics[context].totalSamples | Int64 | 0 | Total samples submitted (for sampling rate calculation) |
| lastFlushTime | Timestamp | 0 | Time of last flush (for periodic flush trigger) |

### Worker and Buffer (S3)
| Name | Type | Initial | Meaning |
|---|---|---|---|
| bufferState.len | 0..MaxBufferSize | 0 | Bytes written to buffer |
| bufferState.elementCount | 0..MaxBufferElements | 0 | Number of complete metrics in buffer |
| poolSize | 0..BufferPoolCapacity | BufferPoolCapacity | Available buffers in pool |
| workerMode | Mutex \| Channel | Mutex | Worker receiving mode |

### Sender (S4)
| Name | Type | Initial | Meaning |
|---|---|---|---|
| senderState | Running \| Stopped | Running | Sender is running or stopped |
| queueLen | 0..SenderQueueSize | 0 | Buffers queued for transmission |
| transportOpen | Boolean | True | Transport is open |
| telemetry.payloadsSent | Int64 | 0 | Payloads sent to transport |
| telemetry.payloadsDropped | Int64 | 0 | Payloads dropped (queue or write failure) |
| telemetry.bytesSent | Int64 | 0 | Total bytes sent |
| telemetry.bytesDropped | Int64 | 0 | Total bytes dropped |

### Init Singletons (S5)
| Name | Type | Initial | Meaning |
|---|---|---|---|
| containerIDState | Unset \| Set | Unset | Container ID initialization state |
| containerIDValue | String | "" | Detected container ID (if Set) |
| externalEnvState | Unset \| Set | Unset | External env initialization state |
| externalEnvValue | String | "" | Sanitized external environment (if Set) |

---

## Actions (Transitions)

### Client Lifecycle (S1)
| Action | Parameters | Guard | State update | Postcondition |
|---|---|---|---|---|
| CreateClient | addr, options | addr valid | clientState' = Open, initialize subsystems | Client ready for metrics |
| SubmitMetric | metric | clientState = Open | metricsSubmitted' += metric | Metric queued for aggregation or direct send |
| FlushClient | none | clientState = Open | flush all buffers to transport | All pending metrics sent |
| CloseClient | none | clientState = Open | clientState' = Closed, drain queue, stop goroutines | All resources released, no further operations allowed |
| QueryIsClosed | none | any | return (clientState = Closed) | No state change |

### Aggregator (S2)
| Action | Parameters | Guard | State update | Postcondition |
|---|---|---|---|---|
| SampleCount | context, value, rate | aggregatorState = Running, rate sampling | countShards[shard(context)][context]' += value | Value added to accumulator |
| SampleGauge | context, value, rate | aggregatorState = Running, rate sampling | gaugeShards[shard(context)][context]' = value | Latest value stored (last-write-wins) |
| SampleSet | context, value, rate | aggregatorState = Running, rate sampling | setShards[shard(context)][context]' += value | Value added to set |
| SampleBuffered | context, value, rate | aggregatorState = Running, rate sampling | apply reservoir sampling to bufferedMetrics[context].samples' | Sample kept or dropped per reservoir algorithm |
| FlushAggregator | none | aggregatorState = Running, timer fires | for each context: emit metric, reset state | All accumulated metrics queued to worker |
| StopAggregator | none | aggregatorState = Running | aggregatorState' = Stopped, clear all shards | No further samples accepted |

### Worker and Buffer (S3)
| Action | Parameters | Guard | State update | Postcondition |
|---|---|---|---|---|
| WriteMetric | buffer, metric | buffer has active buffer | serialize metric, append to buffer, validate | Metric in buffer OR rolled back on overflow |
| ValidateNewElement | buffer | buffer.len + metric.len > maxSize | restore buffer to original len | errBufferFull returned |
| FlushBuffer | buffer | buffer not empty | send buffer to sender, borrow fresh buffer | Buffer transmitted, new buffer ready |
| BorrowBuffer | none | always enabled (non-blocking) | poolSize'-- (or allocate new) | Buffer acquired, never blocks |
| ReturnBuffer | buffer | always enabled (non-blocking) | reset buffer, try send to pool | Buffer available for reuse OR discarded if pool full |

### Sender (S4)
| Action | Parameters | Guard | State update | Postcondition |
|---|---|---|---|---|
| EnqueueBuffer | buffer | senderState = Running | queueLen' <+= buffer, OR drop if queue full | Buffer queued for transmission OR telemetry incremented |
| SendFromQueue | none | senderState = Running, queue not empty | send buffer to transport, telemetry updated | Buffer removed from queue, bytes counted |
| HandleWriteError | error | transport.Write() fails | telemetry.payloadsDropped'++, telemetry.bytesDropped' += buffer.len | Error logged, buffer discarded, continue |
| FlushSignal | none | user calls Flush() | wake sendLoop, wait for all queued buffers sent | All pending buffers sent before returning |
| StopSender | none | senderState = Running | senderState' = Stopped, sendLoop exits, transport.Close() | All resources released |

### Init Singletons (S5)
| Action | Parameters | Guard | State update | Postcondition |
|---|---|---|---|---|
| InitContainerID | none | containerIDState = Unset | run detection, containerIDState' = Set | Value never changes again |
| InitExternalEnv | none | externalEnvState = Unset | read env var, sanitize, externalEnvState' = Set | Value never changes again |
| ReadContainerID | none | any | if Unset, trigger InitContainerID; return value | Read consistent with initialization |
| ReadExternalEnv | none | any | if Unset, return ""; if Set, return value | Read consistent with initialization |
| AttemptDoubleInit | none | already Set | no-op guard fails | Action is disabled; TLC should catch if this is removed |

---

## Safety Invariants

### Invariants derived from Allium forbidden behaviors:

| Invariant | Meaning | Source |
|---|---|---|
| NoMetricAfterClose | If clientState = Closed, no new metrics submitted | S1-F1 |
| NoPanicOnClosed | Operations on closed client return error, never panic | S1-F2 |
| IdempotentClose | Closing already-closed client succeeds (error or no-op) | S1-F3 |
| NoNewSamplesAfterStop | If aggregatorState = Stopped, no new samples added | S2-F2 |
| GaugeLWW | Gauge values never accumulate (last-write-wins only) | S2-F3 |
| NoBufferOverflow | buffer.len <= MaxBufferSize always | S3-F1 |
| TransactionalWrites | Each metric fully written or fully rolled back (no partial) | S3-F2 |
| NoPoolBlocking | Pool borrow/return never blocks | S3-F3 |
| NoQueueOverflow | queueLen <= SenderQueueSize always | S4-F2 |
| NoRetries | Each buffer sent at most once (fire-and-forget) | S4-F1 |
| OneTimeInit | containerIDValue and externalEnvValue never change after Set | S5-F1, S5-F2 |
| ReadConsistency | Reads always return same value once initialized | S5-F3 |

---

## Liveness / Progress Properties

| Property | Meaning | Notes |
|---|---|---|
| EventuallyFlushed | Every submitted metric eventually reaches transport or is explicitly dropped | May require fairness |
| EventuallyClosed | Close() eventually transitions state and stops goroutines | Assumes no deadlocks |
| EventuallyAggregated | Aggregator flush interval ensures periodic flush even if no new metrics | Timer-based, abstract in model |
| EventuallyDrained | On Close(), all pending buffers are sent before goroutines exit | Fairness on sendLoop |

---

## Assumptions

- **Finite domains**: MetricContexts, MetricTypes are finite sets for TLC
- **Bounded queues**: SenderQueueSize, BufferPoolCapacity, MaxBufferElements are fixed bounds
- **Nondeterministic user**: Order and timing of user calls are not constrained (free choice in Next)
- **Atomic init**: sync.Once guarantees exactly-one execution (modeled as once-initialization actions)
- **Lock-free reads**: S5 reads use atomic.Value (modeled as read-only after initialization)
- **No network timing**: Transport Write() is abstract (either succeeds or fails, not time-based)
- **No persistence model**: Client state is lost on exit (no crash recovery)
- **Sharding is deterministic**: FNV-1a hash always produces same shard for same context

---

## Open Translation Questions

- Should buffered metric contexts be fully modeled, or abstracted as a single aggregate counter?
- Should telemetry counters be modeled, or considered observational (not affecting behavior)?
- Should transport Write() failures be nondeterministic (may fail or succeed), or deterministic (always succeed in model)?
- How to model periodic timeouts (buffer flush interval, aggregator flush interval, telemetry send interval) in TLA+?
