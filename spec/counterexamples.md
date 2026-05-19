# Counterexample Analysis

## Overview

This document records all counterexamples found by TLC or Apalache during model checking of the datadog-go DogStatsD client. Each counterexample is analyzed, classified, and resolved.

**Current status:** TLC checking in progress. Three models passed without errors (S1, S3, S5). S2 running; S4 deferred due to state explosion. No real counterexamples discovered yet.

---

## Counterexample Template

For each counterexample found, use this structure:

```markdown
### Counterexample N: <short-title>

**Violated property:** <Invariant or temporal property name>

**Trace summary:**
1. <InitState or relevant initial condition>
2. <Action with parameters>
3. <Action with parameters>
...
N. <Final state violating invariant>

**Final bad state:**
<Variables and values at failure point>

**Plain-English interpretation:**
<What happened behaviorally; why this is wrong or right>

**Root cause:**
[ ] Allium spec allows this behavior (bad behavior permitted by intent)
[ ] TLA+ translation is wrong (good behavior forbade as bad)
[ ] Invariant is too strong (property is overly restrictive)
[ ] Invariant is correct but missing rule/precondition (good catch; fix code)
[ ] Model bound is wrong (trace requires larger constant)
[ ] Behavior is correct; property should change (expected; update spec)

**Resolution:**
<Describe the fix: Allium rule change, TLA+ guard addition, invariant weakening, bound increase, etc.>

**Changes made:**
- [ ] Allium spec updated
- [ ] TLA+ model updated
- [ ] Config bounds increased
- [ ] Invariant modified
- [ ] Committed and verified

**Regression test:**
<If this is a bug, add a unit test in Rust to prevent recurrence.>
```

---

## Intentional Fault Injections

These counterexamples are **expected**; they verify that TLC is working correctly.

### Fault 1: Client accepts metrics after close (S1)

**Test:** Remove guard `clientState = "Open"` from SubmitMetric action.

**Expected violation:** `NoMetricAfterClose` invariant fails.

**Expected trace:**
```
1. Init: clientState = Open
2. ClientClose: clientState' = Closed
3. SubmitMetric(m): metricsSubmitted' = {m}  [WITHOUT guard check]
Final: clientState = Closed, metricsSubmitted = {m} ✗ Violates NoMetricAfterClose
```

**Status:** [ ] TLC catches this (expected)

---

### Fault 2: Aggregator samples after stop (S2)

**Test:** Remove guard `aggregatorState = "Running"` from SampleCount action.

**Expected violation:** `NoNewSamplesAfterStop` or `CountsNonNegative` fails.

**Expected trace:**
```
1. Init: aggregatorState = Running
2. StopAggregator: aggregatorState' = Stopped
3. SampleCount(ctx, 5): countShards'[s][ctx] = 0 + 5 = 5  [WITHOUT guard check]
Final: aggregatorState = Stopped, countShards has count > 0 ✗ Violates NoNewSamplesAfterStop
```

**Status:** [ ] TLC catches this (expected)

---

### Fault 3: Buffer overflows (S3)

**Test:** Remove guard `bufferLen + metricSize <= MaxBufferSize` from WriteMetric action.

**Expected violation:** `NoBufferOverflow` invariant fails.

**Expected trace:**
```
1. Init: bufferLen = 0, MaxBufferSize = 100
2. WriteMetric(size=60): bufferLen' = 60
3. WriteMetric(size=60): bufferLen' = 120  [WITHOUT size check]
Final: bufferLen = 120 > MaxBufferSize = 100 ✗ Violates NoBufferOverflow
```

**Status:** [ ] TLC catches this (expected)

---

### Fault 4: Queue overflows (S4)

**Test:** Remove queue size check in EnqueueBuffer action.

**Expected violation:** `NoQueueOverflow` invariant fails.

**Expected trace:**
```
1. Init: queueLen = 0, SenderQueueSize = 5
2. EnqueueBuffer(...) × 6: queueLen' = 6  [WITHOUT size check on 6th]
Final: queueLen = 6 > SenderQueueSize = 5 ✗ Violates NoQueueOverflow
```

**Status:** [ ] TLC catches this (expected)

---

### Fault 5: Container ID re-initialization (S5)

**Test:** Remove guard `containerIDState = "Unset"` from InitContainerID action.

**Expected violation:** `NoContainerIDChange` or `NoDoubleInit` fails.

**Expected trace:**
```
1. Init: containerIDState = Unset
2. InitContainerID(cid1): containerIDState' = Set, containerIDValue' = cid1
3. InitContainerID(cid2): containerIDState' = Set, containerIDValue' = cid2  [WITHOUT Unset check]
Final: containerIDState = Set, containerIDValue = cid2 (changed from cid1) ✗ Violates NoContainerIDChange
```

**Status:** [ ] TLC catches this (expected)

---

## Discovered Counterexamples

### Real Issue 1: <title> (if any)

*To be filled in after TLC runs.*

---

## Summary Table

| Fault/Issue | Property | Status | Resolved | Resolution Type | Notes |
|-------------|----------|--------|----------|-----------------|-------|
| S1 no-guard | NoMetricAfterClose | Not Tested | N/A | Intentional | S1 passed cleanly; fault injection recommended for robustness |
| S2 no-guard | NoNewSamplesAfterStop | Not Tested | N/A | Intentional | S2 model running; fault injection TBD |
| S3 no-guard | NoBufferOverflow | Not Tested | N/A | Intentional | S3 passed; fault injection could strengthen confidence |
| S4 no-guard | NoQueueOverflow | Not Tested | N/A | Intentional | S4 deferred; bounds adjustment needed first |
| S5 no-guard | NoContainerIDChange | Not Tested | N/A | Intentional | S5 passed; fault injection recommended |

## Real Counterexamples Found

**None so far.** All models that completed checking (S1, S3, S5) passed their invariants. This is a positive sign indicating that the Allium specs and TLA+ models are well-formed and correctly capture the intended constraints.

---

## Notes

- Intentional faults verify that the TLC configuration and invariants are correctly expressed.
- If TLC does not catch an intentional fault, the invariant or guard may be wrong.
- Real counterexamples from TLC should be analyzed for semantic meaning before the model is changed.
- Always update both the Allium spec and the TLA+ model if a semantic issue is discovered.

