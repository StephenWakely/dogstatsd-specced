// Package WireFormat
// Dafny module WireFormat compiled into Go

package WireFormat

import (
	m_Buffer "Buffer"
	m__Errors "Errors_"
	m__System "System_"
	m_Types "Types"
	_dafny "dafny"
	os "os"
)

var _ = os.Args
var _ _dafny.Dummy__
var _ m__System.Dummy__
var _ m_Types.Dummy__
var _ m__Errors.Dummy__
var _ m_Buffer.Dummy__

type Dummy__ struct{}

// Definition of class Default__
type Default__ struct {
	dummy byte
}

func New_Default___() *Default__ {
	_this := Default__{}

	return &_this
}

type CompanionStruct_Default___ struct {
}

var Companion_Default___ = CompanionStruct_Default___{}

func (_this *Default__) Equals(other *Default__) bool {
	return _this == other
}

func (_this *Default__) EqualsGeneric(x interface{}) bool {
	other, ok := x.(*Default__)
	return ok && _this.Equals(other)
}

func (*Default__) String() string {
	return "WireFormat.Default__"
}
func (_this *Default__) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Default__{}

func (_static *CompanionStruct_Default___) StringToBytes(s _dafny.Sequence) _dafny.Sequence {
	var _0___accumulator _dafny.Sequence = _dafny.SeqOf()
	_ = _0___accumulator
	goto TAIL_CALL_START
TAIL_CALL_START:
	if (_dafny.IntOfUint32((s).Cardinality())).Sign() == 0 {
		return _dafny.Companion_Sequence_.Concatenate(_0___accumulator, _dafny.SeqOf())
	} else {
		var _1_code _dafny.Int = _dafny.IntOfInt32(rune((s).Select(0).(_dafny.CodePoint)))
		_ = _1_code
		var _2_bval _dafny.Int = (func() _dafny.Int {
			if ((_1_code).Sign() != -1) && ((_1_code).Cmp(_dafny.IntOfInt64(256)) < 0) {
				return _1_code
			}
			return _dafny.Zero
		})()
		_ = _2_bval
		_0___accumulator = _dafny.Companion_Sequence_.Concatenate(_0___accumulator, _dafny.SeqOf((_2_bval).Uint8()))
		var _in0 _dafny.Sequence = (s).Drop(1)
		_ = _in0
		s = _in0
		goto TAIL_CALL_START
	}
}
func (_static *CompanionStruct_Default___) RealToDecimalBytes(r _dafny.Real) _dafny.Sequence {
	return _dafny.SeqOf()
}
func (_static *CompanionStruct_Default___) SerializeName(name _dafny.Sequence) _dafny.Sequence {
	return Companion_Default___.StringToBytes(name)
}
func (_static *CompanionStruct_Default___) SerializeValue(value _dafny.Sequence) _dafny.Sequence {
	return Companion_Default___.StringToBytes(value)
}
func (_static *CompanionStruct_Default___) SerializeType(t m_Types.MetricType) _dafny.Sequence {
	return Companion_Default___.StringToBytes(m_Types.Companion_Default___.MetricTypeSymbol(t))
}
func (_static *CompanionStruct_Default___) SerializeRate(rate m_Types.Option) _dafny.Sequence {
	if ((rate).Is_None()) || (((rate).Dtor_value().(_dafny.Real)).Cmp(_dafny.RealOfString("1")) >= 0) {
		return _dafny.SeqOf()
	} else {
		return _dafny.Companion_Sequence_.Concatenate(Companion_Default___.StringToBytes(_dafny.UnicodeSeqOfUtf8Bytes("|@")), Companion_Default___.RealToDecimalBytes((rate).Dtor_value().(_dafny.Real)))
	}
}
func (_static *CompanionStruct_Default___) JoinTags(tags _dafny.Sequence) _dafny.Sequence {
	var _0___accumulator _dafny.Sequence = _dafny.SeqOf()
	_ = _0___accumulator
	goto TAIL_CALL_START
TAIL_CALL_START:
	if (_dafny.IntOfUint32((tags).Cardinality())).Sign() == 0 {
		return _dafny.Companion_Sequence_.Concatenate(_0___accumulator, _dafny.SeqOf())
	} else if (_dafny.IntOfUint32((tags).Cardinality())).Cmp(_dafny.One) == 0 {
		return _dafny.Companion_Sequence_.Concatenate(_0___accumulator, Companion_Default___.StringToBytes((tags).Select(0).(_dafny.Sequence)))
	} else {
		_0___accumulator = _dafny.Companion_Sequence_.Concatenate(_0___accumulator, _dafny.Companion_Sequence_.Concatenate(Companion_Default___.StringToBytes((tags).Select(0).(_dafny.Sequence)), Companion_Default___.StringToBytes(_dafny.UnicodeSeqOfUtf8Bytes(","))))
		var _in0 _dafny.Sequence = (tags).Drop(1)
		_ = _in0
		tags = _in0
		goto TAIL_CALL_START
	}
}
func (_static *CompanionStruct_Default___) SerializeTags(tags _dafny.Sequence) _dafny.Sequence {
	if (_dafny.IntOfUint32((tags).Cardinality())).Sign() == 0 {
		return _dafny.SeqOf()
	} else {
		return _dafny.Companion_Sequence_.Concatenate(Companion_Default___.StringToBytes(_dafny.UnicodeSeqOfUtf8Bytes("|#")), Companion_Default___.JoinTags(tags))
	}
}
func (_static *CompanionStruct_Default___) SerializeContainerID(cid m_Types.Option) _dafny.Sequence {
	var _source0 m_Types.Option = cid
	_ = _source0
	{
		if _source0.Is_None() {
			return _dafny.SeqOf()
		}
	}
	{
		var _0_id _dafny.Sequence = _source0.Get_().(m_Types.Option_Some).Value.(_dafny.Sequence)
		_ = _0_id
		return _dafny.Companion_Sequence_.Concatenate(Companion_Default___.StringToBytes(_dafny.UnicodeSeqOfUtf8Bytes("|c:")), Companion_Default___.StringToBytes(_0_id))
	}
}
func (_static *CompanionStruct_Default___) SerializeExternalEnv(env m_Types.Option) _dafny.Sequence {
	var _source0 m_Types.Option = env
	_ = _source0
	{
		if _source0.Is_None() {
			return _dafny.SeqOf()
		}
	}
	{
		var _0_e _dafny.Sequence = _source0.Get_().(m_Types.Option_Some).Value.(_dafny.Sequence)
		_ = _0_e
		if (_dafny.IntOfUint32((_0_e).Cardinality())).Sign() == 0 {
			return _dafny.SeqOf()
		} else {
			return _dafny.Companion_Sequence_.Concatenate(Companion_Default___.StringToBytes(_dafny.UnicodeSeqOfUtf8Bytes("|e:")), Companion_Default___.StringToBytes(_0_e))
		}
	}
}
func (_static *CompanionStruct_Default___) SerializeCardinality(c m_Types.TagCardinality) _dafny.Sequence {
	var _source0 m_Types.Option = m_Types.Companion_Default___.CardinalityString(c)
	_ = _source0
	{
		if _source0.Is_None() {
			return _dafny.SeqOf()
		}
	}
	{
		var _0_s _dafny.Sequence = _source0.Get_().(m_Types.Option_Some).Value.(_dafny.Sequence)
		_ = _0_s
		return _dafny.Companion_Sequence_.Concatenate(Companion_Default___.StringToBytes(_dafny.UnicodeSeqOfUtf8Bytes("|card:")), Companion_Default___.StringToBytes(_0_s))
	}
}
func (_static *CompanionStruct_Default___) SerializeWireFormat(m WireMetric) _dafny.Sequence {
	return _dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate(Companion_Default___.SerializeName((m).Dtor_name()), Companion_Default___.StringToBytes(_dafny.UnicodeSeqOfUtf8Bytes(":"))), Companion_Default___.SerializeValue((m).Dtor_value())), Companion_Default___.StringToBytes(_dafny.UnicodeSeqOfUtf8Bytes("|"))), Companion_Default___.SerializeType((m).Dtor_metricType())), Companion_Default___.SerializeRate((m).Dtor_rate())), Companion_Default___.SerializeTags((m).Dtor_tags())), Companion_Default___.SerializeContainerID((m).Dtor_containerID())), Companion_Default___.SerializeExternalEnv((m).Dtor_externalEnv())), Companion_Default___.SerializeCardinality((m).Dtor_cardinality())), _dafny.SeqOf((_dafny.IntOfInt32(rune(_dafny.CodePoint('\n')))).Uint8()))
}

// End of class Default__

// Definition of datatype WireMetric
type WireMetric struct {
	Data_WireMetric_
}

func (_this WireMetric) Get_() Data_WireMetric_ {
	return _this.Data_WireMetric_
}

type Data_WireMetric_ interface {
	isWireMetric()
}

type CompanionStruct_WireMetric_ struct {
}

var Companion_WireMetric_ = CompanionStruct_WireMetric_{}

type WireMetric_WireMetric struct {
	Name        _dafny.Sequence
	Value       _dafny.Sequence
	MetricType  m_Types.MetricType
	Rate        m_Types.Option
	Tags        _dafny.Sequence
	ContainerID m_Types.Option
	ExternalEnv m_Types.Option
	Cardinality m_Types.TagCardinality
}

func (WireMetric_WireMetric) isWireMetric() {}

func (CompanionStruct_WireMetric_) Create_WireMetric_(Name _dafny.Sequence, Value _dafny.Sequence, MetricType m_Types.MetricType, Rate m_Types.Option, Tags _dafny.Sequence, ContainerID m_Types.Option, ExternalEnv m_Types.Option, Cardinality m_Types.TagCardinality) WireMetric {
	return WireMetric{WireMetric_WireMetric{Name, Value, MetricType, Rate, Tags, ContainerID, ExternalEnv, Cardinality}}
}

func (_this WireMetric) Is_WireMetric() bool {
	_, ok := _this.Get_().(WireMetric_WireMetric)
	return ok
}

func (CompanionStruct_WireMetric_) Default() WireMetric {
	return Companion_WireMetric_.Create_WireMetric_(_dafny.EmptySeq, _dafny.EmptySeq, m_Types.Companion_MetricType_.Default(), m_Types.Companion_Option_.Default(), _dafny.EmptySeq, m_Types.Companion_Option_.Default(), m_Types.Companion_Option_.Default(), m_Types.Companion_TagCardinality_.Default())
}

func (_this WireMetric) Dtor_name() _dafny.Sequence {
	return _this.Get_().(WireMetric_WireMetric).Name
}

func (_this WireMetric) Dtor_value() _dafny.Sequence {
	return _this.Get_().(WireMetric_WireMetric).Value
}

func (_this WireMetric) Dtor_metricType() m_Types.MetricType {
	return _this.Get_().(WireMetric_WireMetric).MetricType
}

func (_this WireMetric) Dtor_rate() m_Types.Option {
	return _this.Get_().(WireMetric_WireMetric).Rate
}

func (_this WireMetric) Dtor_tags() _dafny.Sequence {
	return _this.Get_().(WireMetric_WireMetric).Tags
}

func (_this WireMetric) Dtor_containerID() m_Types.Option {
	return _this.Get_().(WireMetric_WireMetric).ContainerID
}

func (_this WireMetric) Dtor_externalEnv() m_Types.Option {
	return _this.Get_().(WireMetric_WireMetric).ExternalEnv
}

func (_this WireMetric) Dtor_cardinality() m_Types.TagCardinality {
	return _this.Get_().(WireMetric_WireMetric).Cardinality
}

func (_this WireMetric) String() string {
	switch data := _this.Get_().(type) {
	case nil:
		return "null"
	case WireMetric_WireMetric:
		{
			return "WireFormat.WireMetric.WireMetric" + "(" + data.Name.VerbatimString(true) + ", " + data.Value.VerbatimString(true) + ", " + _dafny.String(data.MetricType) + ", " + _dafny.String(data.Rate) + ", " + _dafny.String(data.Tags) + ", " + _dafny.String(data.ContainerID) + ", " + _dafny.String(data.ExternalEnv) + ", " + _dafny.String(data.Cardinality) + ")"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this WireMetric) Equals(other WireMetric) bool {
	switch data1 := _this.Get_().(type) {
	case WireMetric_WireMetric:
		{
			data2, ok := other.Get_().(WireMetric_WireMetric)
			return ok && data1.Name.Equals(data2.Name) && data1.Value.Equals(data2.Value) && data1.MetricType.Equals(data2.MetricType) && data1.Rate.Equals(data2.Rate) && data1.Tags.Equals(data2.Tags) && data1.ContainerID.Equals(data2.ContainerID) && data1.ExternalEnv.Equals(data2.ExternalEnv) && data1.Cardinality.Equals(data2.Cardinality)
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this WireMetric) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(WireMetric)
	return ok && _this.Equals(typed)
}

func Type_WireMetric_() _dafny.TypeDescriptor {
	return type_WireMetric_{}
}

type type_WireMetric_ struct {
}

func (_this type_WireMetric_) Default() interface{} {
	return Companion_WireMetric_.Default()
}

func (_this type_WireMetric_) String() string {
	return "WireFormat.WireMetric"
}
func (_this WireMetric) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = WireMetric{}

// End of datatype WireMetric
