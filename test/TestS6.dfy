// Tests for S6: Wire format serialization (T-S6-01 through T-S6-11).
include "../src/WireFormat.dfy"

module TestS6 {
  import opened WireFormat
  import opened Types

  // Substring check: true iff needle appears contiguously in haystack.
  function HasSubseq(haystack: seq<byte>, needle: seq<byte>): bool
    decreases |haystack|
  {
    if |needle| == 0 then true
    else if |haystack| < |needle| then false
    else if haystack[..|needle|] == needle then true
    else HasSubseq(haystack[1..], needle)
  }

  // T-S6-01: gauge, name="name", value="1.5", no optional fields → "name:1.5|g\n"
  method {:test} TestSerializeGauge() {
    var m := WireMetric(
      name := "name", value := "1.5", metricType := Gauge,
      rate := None, tags := [],
      containerID := None, externalEnv := None,
      cardinality := CardinalityNotSet
    );
    var result := SerializeWireFormat(m);
    expect result == StringToBytes("name:1.5|g\n");
  }

  // T-S6-02: count, name="name", value="42", no optional fields → "name:42|c\n"
  method {:test} TestSerializeCount() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Count,
      rate := None, tags := [],
      containerID := None, externalEnv := None,
      cardinality := CardinalityNotSet
    );
    var result := SerializeWireFormat(m);
    expect result == StringToBytes("name:42|c\n");
  }

  // T-S6-03: rate=0.5 → rate field has |@ prefix (structural proof; extern RealToDecimalBytes not executed).
  method {:test} TestSerializeWithRate() {
    ghost var r := 0.5 as real;
    // 0.5 < 1.0 so SerializeRate takes else branch: StringToBytes("|@") + RealToDecimalBytes(r)
    assert SerializeRate(Some(r)) == StringToBytes("|@") + RealToDecimalBytes(r);
    // StringToBytes("|@") has exactly 2 bytes
    StringToBytesLength("|@");
    assert |StringToBytes("|@")| == 2;
    // Rate field is at least 2 bytes long and its first 2 bytes are "|@"
    assert |SerializeRate(Some(r))| >= 2;
    assert SerializeRate(Some(r))[..2] == StringToBytes("|@");
  }

  // T-S6-04: tags=["env:prod","host:foo"] → output contains |#env:prod,host:foo
  method {:test} TestSerializeWithTags() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Count,
      rate := None, tags := ["env:prod", "host:foo"],
      containerID := None, externalEnv := None,
      cardinality := CardinalityNotSet
    );
    var result := SerializeWireFormat(m);
    expect HasSubseq(result, StringToBytes("|#env:prod,host:foo"));
  }

  // T-S6-05: containerID="abc123" → output contains |c:abc123
  method {:test} TestSerializeWithContainerID() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Count,
      rate := None, tags := [],
      containerID := Some("abc123"), externalEnv := None,
      cardinality := CardinalityNotSet
    );
    var result := SerializeWireFormat(m);
    expect HasSubseq(result, StringToBytes("|c:abc123"));
  }

  // T-S6-06: externalEnv="k8s" → output contains |e:k8s
  method {:test} TestSerializeWithExternalEnv() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Count,
      rate := None, tags := [],
      containerID := None, externalEnv := Some("k8s"),
      cardinality := CardinalityNotSet
    );
    var result := SerializeWireFormat(m);
    expect HasSubseq(result, StringToBytes("|e:k8s"));
  }

  // T-S6-07: cardinality=CardinalityLow → output contains |card:low
  method {:test} TestSerializeWithCardinality() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Count,
      rate := None, tags := [],
      containerID := None, externalEnv := None,
      cardinality := CardinalityLow
    );
    var result := SerializeWireFormat(m);
    expect HasSubseq(result, StringToBytes("|card:low"));
  }

  // T-S6-08: all optional fields (rate=None to avoid extern); verify exact spec field order
  // name:value|type[|#tags][|c:cid][|e:env][|card:x]\n
  method {:test} TestSerializeFieldOrder() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Gauge,
      rate := None, tags := ["env:prod"],
      containerID := Some("abc"), externalEnv := Some("k8s"),
      cardinality := CardinalityLow
    );
    var result := SerializeWireFormat(m);
    expect result == StringToBytes("name:42|g|#env:prod|c:abc|e:k8s|card:low\n");
  }

  // T-S6-09: rate=1.0 (>= 1.0) → rate field omitted, no |@ in output
  method {:test} TestSerializeRateOneOmitted() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Count,
      rate := Some(1.0), tags := [],
      containerID := None, externalEnv := None,
      cardinality := CardinalityNotSet
    );
    var result := SerializeWireFormat(m);
    expect !HasSubseq(result, StringToBytes("|@"));
  }

  // T-S6-10: tags=[] → tag field omitted, no |# in output
  method {:test} TestSerializeEmptyTagsOmitted() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Count,
      rate := None, tags := [],
      containerID := None, externalEnv := None,
      cardinality := CardinalityNotSet
    );
    var result := SerializeWireFormat(m);
    expect !HasSubseq(result, StringToBytes("|#"));
  }

  // T-S6-11: every serialized metric ends with byte 0x0A ('\n')
  method {:test} TestSerializeEndsWithNewline() {
    var m := WireMetric(
      name := "name", value := "42", metricType := Count,
      rate := None, tags := [],
      containerID := None, externalEnv := None,
      cardinality := CardinalityNotSet
    );
    var result := SerializeWireFormat(m);
    expect |result| >= 1;
    expect result[|result| - 1] == (0x0A as bv8);
  }

}
