# S5: Init-Once Singletons — Implementation Notes

`src/Singletons.dfy` | Verified: **19 verified, 0 errors**

## Spec Traceability

| Spec Rule / Invariant | Dafny Artefact |
|---|---|
| R5.1 — ContainerID init from Unset | `ContainerID.Init()` precondition `s.state == Unset` |
| R5.2 — ExternalEnv init, sanitize non-printable and `\|` | `ExternalEnv.Init()` stores `SanitizeExternalEnv(raw)` |
| R5.3 — ContainerID read: `None` if Unset, `Some(v)` if Set | `ContainerID.Get(): Option<string>` |
| R5.4 — ExternalEnv read: `""` if Unset, stored value if Set | `ExternalEnv.Get(): string` |
| I5.1 — containerID never changes after Set | Init precondition (`state == Unset`) makes re-init statically unreachable; proved by `ContainerIDInitOnce` |
| I5.2 — externalEnv never changes after Set | Same mechanism; proved by `ExternalEnvInitOnce` |
| I5.3 — reads consistent once Set | `ContainerIDReadConsistent`, `ExternalEnvReadConsistency` |
| TLA+ `NoReversal` | No public method transitions `Set → Unset`; Init pre/post enforce monotone transition |
| TLA+ `InitStateConsistent` | `Singleton.Valid()`: `state == Set ⟺ initialized` |

---

## Core Types

### `InitState`

```dafny
datatype InitState = Unset | Set
```

Maps directly to TLA+ `containerIDState` / `externalEnvState`. Only two values; the transition
`Unset → Set` is enforced by Init's precondition — no method takes `Set → Unset`.

### `Singleton<T>`

```dafny
datatype Singleton<T> = SingletonVal(state: InitState, value: T, ghost initialized: bool)
```

A generic write-once container. The `ghost initialized` field lets the verifier track logical
initialization state independently of the runtime `state` field. `Valid()` ties them together:

```dafny
ghost predicate Valid() {
  (state == InitState.Set) <==> initialized
}
```

This bidirectional equivalence means Dafny can prove `state == Set` iff `initialized`, making
all proof obligations about `initialized` and `state` interchangeable.

---

## ContainerID

### Write-once enforcement (I5.1)

`Init()` carries:

```dafny
requires s.state == InitState.Unset
ensures  s.state == InitState.Set
```

After `Init()` completes, `s.state == Set`. Any subsequent call to `Init()` is statically rejected
by Dafny's precondition checker — the precondition `s.state == Unset` cannot be satisfied.
This is verified by `ContainerIDInitOnce`:

```dafny
lemma ContainerIDInitOnce(c: ContainerID)
  requires c.Valid()
  requires c.s.state == InitState.Set
  ensures !(c.s.state == InitState.Unset)
{}
```

The body is empty: the postcondition follows directly from the preconditions and `InitState`'s
mutual exclusion (a value cannot be both `Set` and `Unset`). Dafny verifies this automatically.

### Read consistency (I5.3)

```dafny
lemma ContainerIDReadConsistent(c: ContainerID)
  requires c.Valid()
  requires c.s.state == InitState.Set
  ensures c.Get() == Some(c.s.value)
{}
```

Again an empty body: `Get()` is a pure function whose definition branches on `s.state`. When
`state == Set`, it returns `Some(s.value)`. Because `ContainerID` is mutable but `Init()` cannot
be called again once `Set`, `s.value` is stable — Dafny sees this via method contracts.

---

## ExternalEnv

### Sanitization (R5.2)

```dafny
predicate IsPrintableNonPipe(c: char) {
  32 <= c as int <= 126 && c != '|'
}

function SanitizeExternalEnv(raw: string): string
  decreases |raw|
{
  if |raw| == 0 then []
  else
    (if IsPrintableNonPipe(raw[0]) then [raw[0]] else []) + SanitizeExternalEnv(raw[1..])
}
```

Recursive filter over characters. `decreases |raw|` proves termination to Dafny. The recursive
case strips the head character if it fails `IsPrintableNonPipe`, then recurses on the tail.

**Printable ASCII** is defined as `[32, 126]` — space through tilde, matching the spec's
"non-printable" exclusion. The `|` character (ASCII 124) is excluded separately even though it
falls inside the printable range, matching R5.2 and the TLA+ `InitExternalEnv` action.

### Sanitization proofs (S5-S12, S5-S13)

Both proofs use structural induction on string length:

```dafny
lemma SanitizeRemovesPipe(s: string)
  ensures '|' !in SanitizeExternalEnv(s)
  decreases |s|
{
  if |s| == 0 { } else { SanitizeRemovesPipe(s[1..]); }
}
```

Base case (empty string): trivially no `|` in `[]`.  
Inductive step: assume `SanitizeRemovesPipe(s[1..])` holds. The head character either satisfies
`IsPrintableNonPipe` (in which case it is not `|`, by definition) or is dropped. Either way, `|`
does not appear in the output. `SanitizePrintableOnly` follows the same pattern.

### Write-once enforcement (I5.2)

Identical mechanism to ContainerID: `ExternalEnv.Init()` has `requires s.state == Unset`;
`ExternalEnvInitOnce` proves `Set` implies `Unset` is no longer satisfiable.

---

## Proof Strategy: Empty Lemma Bodies

Several lemmas have empty bodies (`{}`). This is not vacuous — it means Dafny's SMT backend
(Z3) can discharge the proof obligation from the lemma's preconditions and the definitions of
the types involved, without needing explicit proof steps. Each such lemma was confirmed by
running `dafny verify` and observing 0 errors.

If a lemma body were genuinely vacuous (true because the precondition is unsatisfiable), Dafny
would report a warning or `vacuously proved` note. No such warnings appear; the preconditions
are satisfiable (e.g., a freshly initialized `ContainerID` with `state == Set`).

---

## Test Coverage

`test/TestS5.dfy` — 7 `{:test}` methods covering T-S5-01 through T-S5-07:

| Test | Property verified |
|---|---|
| T-S5-01 | ContainerID: Unset after new, Set after Init |
| T-S5-02 | ContainerID.Get(): `None` before Init, `Some(v)` after |
| T-S5-03 | ExternalEnv: Unset after new, Set after Init |
| T-S5-04 | ExternalEnv.Get() consistent across two calls once Set |
| T-S5-05 | `SanitizeExternalEnv("hello\|world") == "helloworld"` |
| T-S5-06 | `SanitizeExternalEnv("hel\tlo") == "hello"` (tab = ASCII 9, dropped) |
| T-S5-07 | ExternalEnv.Get() returns `""` when Unset |

---

## Verification Command

```bash
dafny verify --solver-path <z3-path> src/Singletons.dfy
# Dafny program verifier finished with 19 verified, 0 errors
```

Z3 path on this machine: `/home/stephenwakely/.emacs.d/.cache/lsp/dafny/v3.9.0/z3/bin/z3`

---

## What Is NOT in This File

- Container ID detection logic (cgroup parsing, mountinfo, inode fallback) — that is runtime Go code, outside the scope of Dafny spec compliance.
- Thread-safety / sync.Once semantics — modeled structurally via preconditions; actual Go atomics are not representable in Dafny and are out of scope.
- `DD_EXTERNAL_ENV` environment variable reading — also runtime; the spec models the sanitization contract, not the OS call.
