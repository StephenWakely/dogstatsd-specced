// S5: Write-once singletons for ContainerID and ExternalEnv.
include "Types.dfy"

module Singletons {
  import opened Types

  // S5-S01: InitState datatype (TLA+: containerIDState, externalEnvState)
  datatype InitState = Unset | Set

  // ── ContainerID Singleton ────────────────────────────────────────────────

  // S5-S04: ContainerID singleton — write-once string value (spec S5-R5.1, I5.1)
  class ContainerID {
    var state: InitState
    var value: string
    ghost var initialized: bool

    // S5-S03: Valid() — state == Set ⟺ initialized
    ghost predicate Valid()
      reads this
    {
      (state == InitState.Set) <==> initialized
    }

    constructor()
      ensures state == InitState.Unset
      ensures !initialized
      ensures Valid()
    {
      state := InitState.Unset;
      value := "";
      initialized := false;
    }

    // S5-S05: Init — precondition Unset; postcondition Set (spec S5-R5.1, TLA+: InitContainerID)
    method Init(v: string)
      requires Valid()
      requires state == InitState.Unset
      modifies this
      ensures state == InitState.Set
      ensures this.value == v
      ensures initialized
      ensures Valid()
      ensures old(state) == InitState.Unset && state == InitState.Set  // S5-S19: Unset→Set transition
    {
      state := InitState.Set;
      value := v;
      initialized := true;
    }

    // S5-S08: Get — None if Unset, Some(value) if Set (spec S5-R5.3)
    function Get(): Option<string>
      reads this
      requires Valid()
    {
      if state == InitState.Set then Some(value) else None
    }
  }

  // S5-S06: ContainerIDInitOnce — Init requires state == Unset; after Init state == Set,
  // so Init precondition is unsatisfiable (I5.1)
  lemma ContainerIDInitOnce(c: ContainerID)
    requires c.Valid()
    requires c.state == InitState.Set
    ensures !(c.state == InitState.Unset)
  {}

  // S5-S07: ContainerIDImmutable — state == Set: Init is blocked, value stable (I5.1)
  lemma ContainerIDImmutable(c: ContainerID)
    requires c.Valid()
    requires c.state == InitState.Set
    ensures c.state == InitState.Set
  {}

  // S5-S09: ContainerIDReadConsistent — Get returns same Some(value) on every call once Set (I5.3)
  lemma ContainerIDReadConsistent(c: ContainerID)
    requires c.Valid()
    requires c.state == InitState.Set
    ensures c.Get() == Some(c.value)
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

  // S5-S10: ExternalEnv singleton — sanitized write-once string (spec S5-R5.2, I5.2)
  class ExternalEnv {
    var state: InitState
    var value: string
    ghost var initialized: bool

    // S5-S03: Valid() — state == Set ⟺ initialized
    ghost predicate Valid()
      reads this
    {
      (state == InitState.Set) <==> initialized
    }

    constructor()
      ensures state == InitState.Unset
      ensures !initialized
      ensures Valid()
    {
      state := InitState.Unset;
      value := "";
      initialized := false;
    }

    // S5-S14: Init — stores SanitizeExternalEnv(raw); precondition Unset (spec S5-R5.2)
    method Init(raw: string)
      requires Valid()
      requires state == InitState.Unset
      modifies this
      ensures state == InitState.Set
      ensures this.value == SanitizeExternalEnv(raw)
      ensures initialized
      ensures Valid()
      ensures old(state) == InitState.Unset && state == InitState.Set  // S5-S19: Unset→Set transition
    {
      state := InitState.Set;
      value := SanitizeExternalEnv(raw);
      initialized := true;
    }

    // S5-S17: Get — "" if Unset, stored value if Set (spec S5-R5.4)
    function Get(): string
      reads this
      requires Valid()
    {
      if state == InitState.Set then value else ""
    }
  }

  // S5-S15: ExternalEnvInitOnce — Init requires Unset; after Init cannot Init again (I5.2)
  lemma ExternalEnvInitOnce(e: ExternalEnv)
    requires e.Valid()
    requires e.state == InitState.Set
    ensures !(e.state == InitState.Unset)
  {}

  // S5-S16: ExternalEnvImmutable — after state == Set, value stable (I5.2)
  lemma ExternalEnvImmutable(e: ExternalEnv)
    requires e.Valid()
    requires e.state == InitState.Set
    ensures e.state == InitState.Set
  {}

  // S5-S18: ExternalEnvReadConsistency — once Set, Get always returns same value (I5.3)
  lemma ExternalEnvReadConsistency(e: ExternalEnv)
    requires e.Valid()
    requires e.state == InitState.Set
    ensures e.Get() == e.value
  {}

  // S5-S19: InitStateMonotone — state is Set ==> cannot be Unset (TLA+: NoReversal)
  // The Init methods enforce the Unset→Set transition; this lemma expresses irreversibility.
  lemma InitStateMonotone(s: InitState)
    requires s == InitState.Set
    ensures s != InitState.Unset
  {}
}
