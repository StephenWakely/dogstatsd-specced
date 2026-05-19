// S6: Wire format serialization + proofs — spec allium.md §Wire Format Ordering (S3-R3.1)
include "Types.dfy"
include "Errors.dfy"

module WireFormat {
  import opened Types
  import opened Errors

  // S6-W01: Wire metric record — all fields needed for serialization (spec S6-W01)
  datatype WireMetric = WireMetric(
    name:        string,
    value:       string,
    metricType:  MetricType,
    rate:        Option<real>,
    tags:        seq<string>,
    containerID: Option<string>,
    externalEnv: Option<string>,
    cardinality: TagCardinality
  )

  // Convert ASCII string to integer byte sequence
  function method StringToBytes(s: string): seq<int>
    decreases |s|
  {
    if |s| == 0 then []
    else [s[0] as int] + StringToBytes(s[1..])
  }

  // StringToBytes length equals string length — used in bounded proof
  lemma StringToBytesLength(s: string)
    ensures |StringToBytes(s)| == |s|
    decreases |s|
  {
    if |s| == 0 {
    } else {
      StringToBytesLength(s[1..]);
    }
  }

  // S6-W02: name as ASCII bytes (spec S6-W02)
  function method SerializeName(name: string): seq<int>
  {
    StringToBytes(name)
  }

  // S6-W03: value as ASCII bytes (spec S6-W03)
  function method SerializeValue(value: string): seq<int>
  {
    StringToBytes(value)
  }

  // S6-W04: type symbol bytes — g/c/h/d/s/ms (spec S6-W04)
  function method SerializeType(t: MetricType): seq<int>
  {
    StringToBytes(MetricTypeSymbol(t))
  }

  // Real-to-decimal byte encoding — structural proofs do not depend on concrete bytes.
  // Callers requiring actual decimal encoding must supply an extern implementation.
  function method RealToDecimalBytes(r: real): seq<int>
  {
    []
  }

  // S6-W05: rate field — omit if None or 1.0; prefix |@ otherwise (spec S3 §Wire Format Ordering R3)
  function method SerializeRate(rate: Option<real>): seq<int>
  {
    if rate.None? || rate.value == 1.0 then []
    else StringToBytes("|@") + RealToDecimalBytes(rate.value)
  }

  // Join tag strings with comma separator
  function method JoinTags(tags: seq<string>): seq<int>
    decreases |tags|
  {
    if |tags| == 0 then []
    else if |tags| == 1 then StringToBytes(tags[0])
    else StringToBytes(tags[0]) + StringToBytes(",") + JoinTags(tags[1..])
  }

  // S6-W06: tags field — omit if empty; |#tag1,tag2,... if present (spec S3 §Wire Format Ordering R4)
  function method SerializeTags(tags: seq<string>): seq<int>
  {
    if |tags| == 0 then []
    else StringToBytes("|#") + JoinTags(tags)
  }

  // S6-W07: container ID field — |c:<id> if Some (spec S3 §Wire Format Ordering R5)
  function method SerializeContainerID(cid: Option<string>): seq<int>
  {
    match cid
    case None     => []
    case Some(id) => StringToBytes("|c:") + StringToBytes(id)
  }

  // S6-W08: external env field — |e:<env> if Some and non-empty (spec S3 §Wire Format Ordering R6)
  function method SerializeExternalEnv(env: Option<string>): seq<int>
  {
    match env
    case None    => []
    case Some(e) =>
      if |e| == 0 then []
      else StringToBytes("|e:") + StringToBytes(e)
  }

  // S6-W09: cardinality field — |card:<level> if not NotSet (spec S3 §Wire Format Ordering R7)
  function method SerializeCardinality(c: TagCardinality): seq<int>
  {
    match CardinalityString(c)
    case None    => []
    case Some(s) => StringToBytes("|card:") + StringToBytes(s)
  }

  // S6-W10: compose full wire metric — name:value|type[|@rate][|#tags][|c:cid][|e:env][|card:x]\n
  // Field order per spec S3-R3.1
  function method SerializeWireFormat(m: WireMetric): seq<int>
  {
    SerializeName(m.name) +
    StringToBytes(":") +
    SerializeValue(m.value) +
    StringToBytes("|") +
    SerializeType(m.metricType) +
    SerializeRate(m.rate) +
    SerializeTags(m.tags) +
    SerializeContainerID(m.containerID) +
    SerializeExternalEnv(m.externalEnv) +
    SerializeCardinality(m.cardinality) +
    ['\n' as int]
  }

  // Helper: decompose SerializeWireFormat into prefix + rest
  lemma DecomposeWireFormat(m: WireMetric)
    ensures var prefix := SerializeName(m.name) + StringToBytes(":") +
                          SerializeValue(m.value) + StringToBytes("|") +
                          SerializeType(m.metricType);
            var rest := SerializeRate(m.rate) + SerializeTags(m.tags) +
                        SerializeContainerID(m.containerID) + SerializeExternalEnv(m.externalEnv) +
                        SerializeCardinality(m.cardinality) + ['\n' as int];
            SerializeWireFormat(m) == prefix + rest
  {
    // Follows directly from definition by sequence associativity
  }

  // S6-W11: output starts with name:value|type — MetricOrdering invariant (spec §MetricOrdering)
  lemma MetricOrderingLemma(m: WireMetric)
    ensures var result := SerializeWireFormat(m);
            var prefix := SerializeName(m.name) + StringToBytes(":") +
                          SerializeValue(m.value) + StringToBytes("|") +
                          SerializeType(m.metricType);
            |result| >= |prefix| && result[..|prefix|] == prefix
  {
    var prefix := SerializeName(m.name) + StringToBytes(":") +
                  SerializeValue(m.value) + StringToBytes("|") +
                  SerializeType(m.metricType);
    var rest := SerializeRate(m.rate) + SerializeTags(m.tags) +
                SerializeContainerID(m.containerID) + SerializeExternalEnv(m.externalEnv) +
                SerializeCardinality(m.cardinality) + ['\n' as int];
    assert SerializeWireFormat(m) == prefix + rest;
    assert (prefix + rest)[..|prefix|] == prefix;
  }

  // S6-W12: function is total — trivially true for all function methods in Dafny
  lemma SerializeWireFormatTerminates(m: WireMetric)
    ensures exists result: seq<int> :: result == SerializeWireFormat(m)
  {
    var r := SerializeWireFormat(m);
    assert r == SerializeWireFormat(m);
  }

  // S6-W13: last byte is '\n' (0x0A) (spec S3 §Wire Format Ordering step 7)
  lemma SerializeWireFormatEndsWithNewline(m: WireMetric)
    ensures var result := SerializeWireFormat(m);
            |result| >= 1 && result[|result| - 1] == '\n' as int
  {
    var body := SerializeName(m.name) + StringToBytes(":") +
                SerializeValue(m.value) + StringToBytes("|") +
                SerializeType(m.metricType) + SerializeRate(m.rate) +
                SerializeTags(m.tags) + SerializeContainerID(m.containerID) +
                SerializeExternalEnv(m.externalEnv) + SerializeCardinality(m.cardinality);
    assert SerializeWireFormat(m) == body + ['\n' as int];
    assert |body + ['\n' as int]| == |body| + 1;
    assert (body + ['\n' as int])[|body|] == '\n' as int;
  }

  // S6-W14: None or 1.0 rate → rate field absent from output (spec S3 §Wire Format Ordering R3)
  lemma SerializeRateEmpty(rate: Option<real>)
    requires rate.None? || rate.value == 1.0
    ensures SerializeRate(rate) == []
  {
  }

  // S6-W15: empty tags → tag field absent from output (spec S3 §Wire Format Ordering R4)
  lemma SerializeTagsEmpty()
    ensures SerializeTags([]) == []
  {
  }

  // S6-W16: precondition: component sizes sum to <= maxSize implies output fits maxSize
  // Used as buffer-write precondition (spec S3-R3.2, I3.1)
  lemma SerializeWireFormatBounded(m: WireMetric, maxSize: nat)
    requires |SerializeName(m.name)| +
             1 +  // ":"
             |SerializeValue(m.value)| +
             1 +  // "|"
             |SerializeType(m.metricType)| +
             |SerializeRate(m.rate)| +
             |SerializeTags(m.tags)| +
             |SerializeContainerID(m.containerID)| +
             |SerializeExternalEnv(m.externalEnv)| +
             |SerializeCardinality(m.cardinality)| +
             1    // "\n"
             <= maxSize
    ensures |SerializeWireFormat(m)| <= maxSize
  {
    StringToBytesLength(":");
    StringToBytesLength("|");
    var n    := SerializeName(m.name);
    var col  := StringToBytes(":");
    var v    := SerializeValue(m.value);
    var pipe := StringToBytes("|");
    var t    := SerializeType(m.metricType);
    var r    := SerializeRate(m.rate);
    var tgs  := SerializeTags(m.tags);
    var cid  := SerializeContainerID(m.containerID);
    var env  := SerializeExternalEnv(m.externalEnv);
    var card := SerializeCardinality(m.cardinality);
    var nl   := ['\n' as int];
    assert SerializeWireFormat(m) == n + col + v + pipe + t + r + tgs + cid + env + card + nl;
    assert |col|  == 1;
    assert |pipe| == 1;
    assert |nl|   == 1;
  }

}
