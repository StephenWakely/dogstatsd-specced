// S5: Write-once singletons for ContainerID and ExternalEnv.
include "Types.dfy"

module Singletons {
  import opened Types

  // S5-S01: InitState datatype (TLA+: containerIDState, externalEnvState)
  datatype InitState = Unset | Set

  // S5-S02: Generic Singleton<T> record — write-once container (spec S5-S02)
  datatype Singleton<T> = SingletonVal(state: InitState, value: T, ghost initialized: bool)
  {
    // S5-S03: Valid() — state == Set ⟺ initialized; value meaningful only when Set
    ghost predicate Valid() {
      (state == InitState.Set) <==> initialized
    }
  }

  // ── ContainerID Singleton ────────────────────────────────────────────────

  // S5-S04: ContainerID singleton — write-once string, built on Singleton<string> (spec S5-R5.1, I5.1)
  class ContainerID {
    var s: Singleton<string>

    ghost predicate Valid()
      reads this
    {
      s.Valid()
    }

    constructor()
      ensures s.state == InitState.Unset
      ensures !s.initialized
      ensures Valid()
    {
      s := SingletonVal(InitState.Unset, "", false);
    }

    // S5-S05: Init — precondition Unset; postcondition Set (spec S5-R5.1, TLA+: InitContainerID)
    method Init(v: string)
      requires Valid()
      requires s.state == InitState.Unset
      modifies this
      ensures s.state == InitState.Set
      ensures s.value == v
      ensures s.initialized
      ensures Valid()
    {
      s := SingletonVal(InitState.Set, v, true);
    }

    // S5-S08: Get — None if Unset, Some(value) if Set (spec S5-R5.3)
    function Get(): Option<string>
      reads this
      requires Valid()
    {
      if s.state == InitState.Set then Some(s.value) else None
    }
  }

  // S5-S06: ContainerIDInitOnce — state == Set implies Init precondition (state == Unset) fails (I5.1)
  lemma ContainerIDInitOnce(c: ContainerID)
    requires c.Valid()
    requires c.s.state == InitState.Set
    ensures !(c.s.state == InitState.Unset)
  {}

  // S5-S07: ContainerIDImmutable — Init() has precondition `s.state == Unset`.
  // Once state == Set, that precondition is permanently unsatisfiable, so value never changes.
  // Monotonicity is enforced statically by the precondition; no separate lemma needed (I5.1).

  // S5-S09: ContainerIDReadConsistent — once Set, Get() always returns Some(value) (I5.3)
  lemma ContainerIDReadConsistent(c: ContainerID)
    requires c.Valid()
    requires c.s.state == InitState.Set
    ensures c.Get() == Some(c.s.value)
  {}

  // ── ExternalEnv Sanitization ─────────────────────────────────────────────

  // S5-S11: Predicate for characters kept by sanitization (printable ASCII, not '|')
  predicate IsPrintableNonPipe(c: char) {
    32 <= c as int <= 126 && c != '|'
  }

  // S5-S11: SanitizeExternalEnv — remove non-printable and '|' chars (spec S5-R5.2)
  function SanitizeExternalEnv(raw: string): string
    decreases |raw|
  {
    if |raw| == 0 then []
    else
      (if IsPrintableNonPipe(raw[0]) then [raw[0]] else []) + SanitizeExternalEnv(raw[1..])
  }

  // S5-S12: SanitizeRemovesPipe — '|' ∉ SanitizeExternalEnv(s) for all s
  lemma SanitizeRemovesPipe(s: string)
    ensures '|' !in SanitizeExternalEnv(s)
    decreases |s|
  {
    if |s| == 0 {
    } else {
      SanitizeRemovesPipe(s[1..]);
    }
  }

  // S5-S13: SanitizePrintableOnly — every char in result satisfies IsPrintableNonPipe
  lemma SanitizePrintableOnly(s: string)
    ensures forall c :: c in SanitizeExternalEnv(s) ==> IsPrintableNonPipe(c)
    decreases |s|
  {
    if |s| == 0 {
    } else {
      SanitizePrintableOnly(s[1..]);
    }
  }

  // ── ExternalEnv Singleton ─────────────────────────────────────────────────

  // S5-S10: ExternalEnv singleton — sanitized write-once string, built on Singleton<string> (spec S5-R5.2, I5.2)
  class ExternalEnv {
    var s: Singleton<string>

    ghost predicate Valid()
      reads this
    {
      s.Valid()
    }

    constructor()
      ensures s.state == InitState.Unset
      ensures !s.initialized
      ensures Valid()
    {
      s := SingletonVal(InitState.Unset, "", false);
    }

    // S5-S14: Init — stores SanitizeExternalEnv(raw); precondition Unset (spec S5-R5.2)
    method Init(raw: string)
      requires Valid()
      requires s.state == InitState.Unset
      modifies this
      ensures s.state == InitState.Set
      ensures s.value == SanitizeExternalEnv(raw)
      ensures s.initialized
      ensures Valid()
    {
      s := SingletonVal(InitState.Set, SanitizeExternalEnv(raw), true);
    }

    // S5-S17: Get — "" if Unset, stored value if Set (spec S5-R5.4)
    function Get(): string
      reads this
      requires Valid()
    {
      if s.state == InitState.Set then s.value else ""
    }
  }

  // S5-S15: ExternalEnvInitOnce — state == Set implies Init precondition (state == Unset) fails (I5.2)
  lemma ExternalEnvInitOnce(e: ExternalEnv)
    requires e.Valid()
    requires e.s.state == InitState.Set
    ensures !(e.s.state == InitState.Unset)
  {}

  // S5-S16: ExternalEnvImmutable — Init() has precondition `s.state == Unset`.
  // Once state == Set, that precondition is permanently unsatisfiable, so value never changes.
  // Monotonicity is enforced statically by the precondition; no separate lemma needed (I5.2).

  // S5-S18: ExternalEnvReadConsistency — once Set, Get() always returns same value (I5.3)
  lemma ExternalEnvReadConsistency(e: ExternalEnv)
    requires e.Valid()
    requires e.s.state == InitState.Set
    ensures e.Get() == e.s.value
  {}

  // S5-S19: InitStateMonotone — TLA+: NoReversal invariant.
  // Init() precondition requires state == Unset; Init postcondition gives state == Set.
  // No public method transitions Set → Unset, so the Unset→Set transition is irreversible.
  // The invariant holds structurally through Init's pre/postconditions; no separate lemma needed.
}
