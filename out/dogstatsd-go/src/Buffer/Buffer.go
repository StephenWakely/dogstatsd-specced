// Package Buffer
// Dafny module Buffer compiled into Go

package Buffer

import (
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

type Dummy__ struct{}

// Definition of datatype Unit
type Unit struct {
	Data_Unit_
}

func (_this Unit) Get_() Data_Unit_ {
	return _this.Data_Unit_
}

type Data_Unit_ interface {
	isUnit()
}

type CompanionStruct_Unit_ struct {
}

var Companion_Unit_ = CompanionStruct_Unit_{}

type Unit_Unit struct {
}

func (Unit_Unit) isUnit() {}

func (CompanionStruct_Unit_) Create_Unit_() Unit {
	return Unit{Unit_Unit{}}
}

func (_this Unit) Is_Unit() bool {
	_, ok := _this.Get_().(Unit_Unit)
	return ok
}

func (CompanionStruct_Unit_) Default() Unit {
	return Companion_Unit_.Create_Unit_()
}

func (_ CompanionStruct_Unit_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_Unit_.Create_Unit_(), true
		default:
			return Unit{}, false
		}
	}
}

func (_this Unit) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case Unit_Unit:
		{
			return "Buffer.Unit.Unit"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this Unit) Equals(other Unit) bool {
	switch _this.Get_().(type) {
	case Unit_Unit:
		{
			_, ok := other.Get_().(Unit_Unit)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this Unit) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(Unit)
	return ok && _this.Equals(typed)
}

func Type_Unit_() _dafny.TypeDescriptor {
	return type_Unit_{}
}

type type_Unit_ struct {
}

func (_this type_Unit_) Default() interface{} {
	return Companion_Unit_.Default()
}

func (_this type_Unit_) String() string {
	return "Buffer.Unit"
}
func (_this Unit) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = Unit{}

// End of datatype Unit

// Definition of class Buffer
type Buffer struct {
	Data         _dafny.Sequence
	Len          _dafny.Int
	MaxSize      _dafny.Int
	ElementCount _dafny.Int
	MaxElements  _dafny.Int
}

func New_Buffer_() *Buffer {
	_this := Buffer{}

	_this.Data = _dafny.EmptySeq
	_this.Len = _dafny.Zero
	_this.MaxSize = _dafny.Zero
	_this.ElementCount = _dafny.Zero
	_this.MaxElements = _dafny.Zero
	return &_this
}

type CompanionStruct_Buffer_ struct {
}

var Companion_Buffer_ = CompanionStruct_Buffer_{}

func (_this *Buffer) Equals(other *Buffer) bool {
	return _this == other
}

func (_this *Buffer) EqualsGeneric(x interface{}) bool {
	other, ok := x.(*Buffer)
	return ok && _this.Equals(other)
}

func (*Buffer) String() string {
	return "Buffer.Buffer"
}

func Type_Buffer_() _dafny.TypeDescriptor {
	return type_Buffer_{}
}

type type_Buffer_ struct {
}

func (_this type_Buffer_) Default() interface{} {
	return (*Buffer)(nil)
}

func (_this type_Buffer_) String() string {
	return "Buffer.Buffer"
}
func (_this *Buffer) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Buffer{}

func (_this *Buffer) Valid() bool {
	{
		return (((_this.Len).Cmp(_this.MaxSize) <= 0) && ((_this.ElementCount).Cmp(_this.MaxElements) <= 0)) && ((_dafny.IntOfUint32((_this.Data).Cardinality())).Cmp(_this.MaxSize) == 0)
	}
}
func (_this *Buffer) New(ms _dafny.Int, me _dafny.Int) {
	{
		(_this).MaxSize = ms
		(_this).MaxElements = me
		(_this).Data = _dafny.SeqCreate((ms).Uint32(), func(coer0 func(_dafny.Int) uint8) func(_dafny.Int) interface{} {
			return func(arg0 _dafny.Int) interface{} {
				return coer0(arg0)
			}
		}(func(_0___v0 _dafny.Int) uint8 {
			return uint8(0)
		}))
		(_this).Len = _dafny.Zero
		(_this).ElementCount = _dafny.Zero
	}
}
func (_this *Buffer) WriteMetric(metric _dafny.Sequence) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		var _0_metricLen _dafny.Int
		_ = _0_metricLen
		_0_metricLen = _dafny.IntOfUint32((metric).Cardinality())
		if (((_this.Len).Plus(_0_metricLen)).Cmp(_this.MaxSize) > 0) || ((_this.ElementCount).Cmp(_this.MaxElements) >= 0) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrorSenderChannelFull_())
			return r
		}
		var _1_newLen _dafny.Int
		_ = _1_newLen
		_1_newLen = (_this.Len).Plus(_0_metricLen)
		var _2_remaining _dafny.Int
		_ = _2_remaining
		_2_remaining = (_this.MaxSize).Minus(_1_newLen)
		(_this).Data = _dafny.Companion_Sequence_.Concatenate(_dafny.Companion_Sequence_.Concatenate((_this.Data).Take((_this.Len).Uint32()), metric), _dafny.SeqCreate((_2_remaining).Uint32(), func(coer1 func(_dafny.Int) uint8) func(_dafny.Int) interface{} {
			return func(arg1 _dafny.Int) interface{} {
				return coer1(arg1)
			}
		}(func(_3___v1 _dafny.Int) uint8 {
			return uint8(0)
		})))
		(_this).Len = _1_newLen
		(_this).ElementCount = (_this.ElementCount).Plus(_dafny.One)
		r = m__Errors.Companion_Result_.Create_Ok_(Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Buffer) Reset() {
	{
		(_this).Data = _dafny.SeqCreate((_this.MaxSize).Uint32(), func(coer2 func(_dafny.Int) uint8) func(_dafny.Int) interface{} {
			return func(arg2 _dafny.Int) interface{} {
				return coer2(arg2)
			}
		}(func(_0___v2 _dafny.Int) uint8 {
			return uint8(0)
		}))
		(_this).Len = _dafny.Zero
		(_this).ElementCount = _dafny.Zero
	}
}
func (_this *Buffer) IsEmpty() bool {
	{
		return (_this.Len).Sign() == 0
	}
}
func (_this *Buffer) Bytes() _dafny.Sequence {
	{
		return (_this.Data).Take((_this.Len).Uint32())
	}
}

// End of class Buffer
