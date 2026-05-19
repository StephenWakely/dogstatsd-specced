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

  // Convert string to byte sequence; non-ASCII chars (> 255) map to 0
  function StringToBytes(s: string): seq<byte>
    decreases |s|
  {
    if |s| == 0 then []
    else
      var code: int := s[0] as int;
      var bval: int := if 0 <= code < 256 then code else 0;
      [bval as byte] + StringToBytes(s[1..])
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

  // Extern: byte encoding of a real number — concrete implementation outside Dafny
  function {:extern} RealToDecimalBytes(r: real): seq<byte>

  // S6-W02: name as ASCII bytes (spec S6-W02)
  function SerializeName(name: string): seq<byte>
  {
    StringToBytes(name)
  }

  // S6-W03: value as ASCII bytes (spec S6-W03)
  function SerializeValue(value: string): seq<byte>
  {
    StringToBytes(value)
  }

  // S6-W04: type symbol bytes — g/c/h/d/s/ms (spec S6-W04)
  function SerializeType(t: MetricType): seq<byte>
  {
    StringToBytes(MetricTypeSymbol(t))
  }

  // S6-W05: rate field — omit if None or >= 1.0; prefix |@ otherwise (spec S3 §Wire Format Ordering R3)
  function SerializeRate(rate: Option<real>): seq<byte>
  {
    if rate.None? || rate.value >= 1.0 then []
    else StringToBytes("|@") + RealToDecimalBytes(rate.value)
  }

  // Join tag strings with comma separator
  function JoinTags(tags: seq<string>): seq<byte>
    decreases |tags|
  {
    if |tags| == 0 then []
    else if |tags| == 1 then StringToBytes(tags[0])
    else StringToBytes(tags[0]) + StringToBytes(",") + JoinTags(tags[1..])
  }

  // S6-W06: tags field — omit if empty; |#tag1,tag2,... if present (spec S3 §Wire Format Ordering R4)
  function SerializeTags(tags: seq<string>): seq<byte>
  {
    if |tags| == 0 then []
    else StringToBytes("|#") + JoinTags(tags)
  }

  // S6-W07: container ID field — |c:<id> if Some (spec S3 §Wire Format Ordering R5)
  function SerializeContainerID(cid: Option<string>): seq<byte>
  {
    match cid
    case None     => []
    case Some(id) => StringToBytes("|c:") + StringToBytes(id)
  }

  // S6-W08: external env field — |e:<env> if Some and non-empty (spec S3 §Wire Format Ordering R6)
  function SerializeExternalEnv(env: Option<string>): seq<byte>
  {
    match env
    case None    => []
    case Some(e) =>
      if |e| == 0 then []
      else StringToBytes("|e:") + StringToBytes(e)
  }

  // S6-W09: cardinality field — |card:<level> if not NotSet (spec S3 §Wire Format Ordering R7)
  function SerializeCardinality(c: TagCardinality): seq<byte>
  {
    match CardinalityString(c)
    case None    => []
    case Some(s) => StringToBytes("|card:") + StringToBytes(s)
  }

  // S6-W10: compose full wire metric — name:value|type[|@rate][|#tags][|c:cid][|e:env][|card:x]\n
  // Field order per spec S3-R3.1
  function SerializeWireFormat(m: WireMetric): seq<byte>
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
    [('\n' as int) as byte]
  }

  // Helper: decompose SerializeWireFormat into prefix + rest
  lemma DecomposeWireFormat(m: WireMetric)
    ensures var prefix := SerializeName(m.name) + StringToBytes(":") +
                          SerializeValue(m.value) + StringToBytes("|") +
                          SerializeType(m.metricType);
            var rest := SerializeRate(m.rate) + SerializeTags(m.tags) +
                        SerializeContainerID(m.containerID) + SerializeExternalEnv(m.externalEnv) +
                        SerializeCardinality(m.cardinality) + [('\n' as int) as byte];
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
                SerializeCardinality(m.cardinality) + [('\n' as int) as byte];
    assert SerializeWireFormat(m) == prefix + rest;
    assert (prefix + rest)[..|prefix|] == prefix;
  }

  // S6-W12: function is total — trivially true for all functions in Dafny
  lemma SerializeWireFormatTerminates(m: WireMetric)
    ensures SerializeWireFormat(m) == SerializeWireFormat(m)
  {
  }

  // S6-W13: last byte is '\n' (0x0A) (spec S3 §Wire Format Ordering step 7)
  lemma SerializeWireFormatEndsWithNewline(m: WireMetric)
    ensures var result := SerializeWireFormat(m);
            |result| >= 1 && result[|result| - 1] == ('\n' as int) as byte
  {
    var body := SerializeName(m.name) + StringToBytes(":") +
                SerializeValue(m.value) + StringToBytes("|") +
                SerializeType(m.metricType) + SerializeRate(m.rate) +
                SerializeTags(m.tags) + SerializeContainerID(m.containerID) +
                SerializeExternalEnv(m.externalEnv) + SerializeCardinality(m.cardinality);
    assert SerializeWireFormat(m) == body + [('\n' as int) as byte];
    assert |body + [('\n' as int) as byte]| == |body| + 1;
    assert (body + [('\n' as int) as byte])[|body|] == ('\n' as int) as byte;
  }

  // S6-W14: None or >= 1.0 rate → rate field absent from output (spec S3 §Wire Format Ordering R3)
  lemma SerializeRateEmpty(rate: Option<real>)
    requires rate.None? || rate.value >= 1.0
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
    var nl   := [('\n' as int) as byte];
    assert SerializeWireFormat(m) == n + col + v + pipe + t + r + tgs + cid + env + card + nl;
    assert |col|  == 1;
    assert |pipe| == 1;
    assert |nl|   == 1;
  }

}
