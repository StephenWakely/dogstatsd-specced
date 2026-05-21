# dogstatsd-specced

A formally verified DogStatsD client written in Dafny.

## What This Is

Port of the [datadog-go](https://github.com/DataDog/datadog-go) DogStatsD client to Dafny, with formal proofs of all behavioral invariants derived from:

- **Allium behavioral spec** (`spec/allium.md`) — intent and rules for all six subsystems
- **TLA+ formal model** (`spec/model.tla`) — state machine with checked invariants
- **TLC model checking results** (`spec/check-results.md`) — verified against finite bounds

Every method in this codebase is backed by a Dafny proof. Spec traceability annotations link each function to its TLA+ action and Allium rule.

## Subsystems

| Module | Spec | Description |
|---|---|---|
| `src/Types.dfy` | S6 | Metric types, transport modes, cardinality levels, constants |
| `src/Errors.dfy` | S6 | Error datatype (ErrNoClient, MessageTooLong, etc.) |
| `src/WireFormat.dfy` | S6 | Serialization: exact wire format field ordering, proofs |
| `src/Buffer.dfy` | S3 | Transactional byte buffer with capacity invariants |
| `src/BufferPool.dfy` | S3 | Non-blocking buffer pool with capacity bound |
| `src/Aggregator.dfy` | S2 | Count/Gauge/Set/Buffered metric aggregation with sharding |
| `src/Singletons.dfy` | S5 | Once-initialized ContainerID and ExternalEnv |
| `src/Sender.dfy` | S4 | Bounded sender queue, fire-and-forget transport, telemetry |
| `src/Client.dfy` | S1 | Client lifecycle: Open/Closed state machine, cross-system invariants |

## Invariants Proved

All invariants from the TLA+ model are formally proved in Dafny:

- **Buffer never overflows** (`bufferLen <= MaxBufferSize` always)
- **Queue never overflows** (`queueLen <= SenderQueueSize` always)
- **Transactional writes** (each metric fully written or fully rolled back)
- **Closure finality** (Closed state is terminal; no metrics sent after close)
- **Once initialization** (ContainerID and ExternalEnv set at most once)
- **Aggregation semantics** (counts accumulate, gauges last-write-wins, sets deduplicate)
- **Wire format ordering** (fields appear in exact spec-mandated order)

## Wire Format

```
name:value|type[|@rate][|#tag1,tag2,...][|c:containerID][|e:externalEnv][|card:cardinality]\n
```

Field order is mandated by spec and proved correct in `src/WireFormat.dfy`.

## Prerequisites

- Dafny 4.11+

```bash
dafny --version
# 4.11.0
```

## Usage

```bash
# Verify all source
dafny verify src/*.dfy

# Run tests
dafny test test/TestS1.dfy
dafny test test/TestS2.dfy
dafny test test/TestS3.dfy
dafny test test/TestS4.dfy
dafny test test/TestS5.dfy
dafny test test/TestS6.dfy

# Verify everything
dafny verify src/*.dfy test/*.dfy
```

## Code Generation

A `Makefile` generates target-language source from the verified Dafny:

```bash
make go      # → out/dogstatsd-go/
make python  # → out/dogstatsd-py/
make rust    # → out/dogstatsd-rs/  (requires --enforce-determinism)
make verify  # run full Dafny proof verification
make clean   # remove out/
```

### Determinism and Rust

Rust compilation requires `--enforce-determinism`, which forbids the Dafny
assign-such-that operator (`:|`). This codebase is fully determinism-clean:

- **`Sender.dfy`** — ghost proof body replaced with a pure `FirstIndexOf`
  function that finds a sequence index by linear scan.
- **`Aggregator.dfy`** — set-key iteration replaced with `PickContextFromSet`,
  declared `{:extern} {:axiom}`. Dafny's type theory has no built-in
  deterministic enumeration for mathematical sets; the extern contract
  (`ensures PickContextFromSet(s) in s`) is trusted by the verifier and must
  be satisfied by the target-language implementation.

**Extern implementations required for compiled Rust:** the generated
`out/dogstatsd-rs/` source calls `PickContextFromSet` as an external Rust
function. A correct, deterministic implementation sorts keys
lexicographically by `(name, tags)` and returns the first element.
Equivalent stubs are needed for `IntToString` and `RealToString` (already
declared extern in `Aggregator.dfy`).

## Spec Traceability

Every Dafny method carries a comment linking it to its spec origin:

```dafny
// S1-R1.4: Close Client: state = Open → Closed, flush pending, stop goroutines
method Close() returns (r: Result<(), DogStatsDError>)
  requires state == Open
  ensures state == Closed
  ensures aggregator.state == Stopped
  ensures sender.state == Stopped
```

See `AGENTS.md` for the full compliance checklist and contribution rules.

## Specs

- `spec/allium.md` — Allium behavioral spec (6 subsystems)
- `spec/model.tla` — TLA+ composite model
- `spec/model.cfg` — TLA+ model constants
- `spec/check-results.md` — TLC model checking results
- `spec/rust-contract.md` — State/action mapping table (reference for Dafny mapping)
- `spec/counterexamples.md` — Known TLC counterexamples (regression targets)
- `spec/model-summary.md` — Variables, actions, invariants summary
