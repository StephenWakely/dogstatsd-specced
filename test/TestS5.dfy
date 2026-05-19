// Tests for S5: ContainerID and ExternalEnv singletons (T-S5-01 through T-S5-07).
include "../src/Singletons.dfy"

module TestS5 {
  import opened Singletons
  import opened Types

  // T-S5-01: After Init, state == Set; second Init would violate `requires s.state == Unset` (I5.1).
  method {:test} TestContainerIDInitializedOnce() {
    var c := new ContainerID();
    expect c.s.state == InitState.Unset;
    c.Init("abc123");
    expect c.s.state == InitState.Set;
    // c.Init("def") here would fail verification: requires s.state == InitState.Unset not met.
  }

  // T-S5-02: Get() returns same value on every call after Init (spec S5-R5.3, I5.1).
  method {:test} TestContainerIDImmutableAfterSet() {
    var c := new ContainerID();
    c.Init("mycontainer");
    var v1 := c.Get();
    var v2 := c.Get();
    expect v1 == v2;
    expect v1 == Some("mycontainer");
  }

  // T-S5-03: After ExternalEnv Init, state == Set; second Init violates precondition (I5.2).
  method {:test} TestExternalEnvInitializedOnce() {
    var e := new ExternalEnv();
    expect e.s.state == InitState.Unset;
    e.Init("prod");
    expect e.s.state == InitState.Set;
    // e.Init("other") here would fail verification: requires s.state == InitState.Unset not met.
  }

  // T-S5-04: ExternalEnv Get() returns same value on repeated calls once Set (I5.3).
  method {:test} TestExternalEnvReadConsistency() {
    var e := new ExternalEnv();
    e.Init("prod");
    var v1 := e.Get();
    var v2 := e.Get();
    expect v1 == v2;
    expect v1 == "prod";
  }

  // T-S5-05: SanitizeExternalEnv strips '|' from raw value (spec S5-R5.2).
  method {:test} TestSanitizeRemovesPipe() {
    var result := SanitizeExternalEnv("hello|world");
    expect '|' !in result;
    expect result == "helloworld";
  }

  // T-S5-06: SanitizeExternalEnv strips control characters (NUL=\x00, SOH=\x01, DEL=\x7f).
  method {:test} TestSanitizeRemovesNonPrintable() {
    var nul := ['\0', 'a', '', 'b', '', 'c'];
    var result := SanitizeExternalEnv(nul);
    expect '\0' !in result;
    expect '' !in result;
    expect '' !in result;
    expect result == "abc";
  }

  // T-S5-07: ExternalEnv Get() returns "" when Unset (spec S5-R5.4).
  method {:test} TestExternalEnvUnsetReturnsEmpty() {
    var e := new ExternalEnv();
    expect e.Get() == "";
  }
}
