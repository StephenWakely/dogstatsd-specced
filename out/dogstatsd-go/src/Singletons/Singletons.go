// Package Singletons
// Dafny module Singletons compiled into Go

package Singletons

import (
	m_Aggregator "Aggregator"
	m_Buffer "Buffer"
	m__Errors "Errors_"
	m_Sender "Sender"
	m__System "System_"
	m_Types "Types"
	m_WireFormat "WireFormat"
	_dafny "dafny"
	os "os"
)

var _ = os.Args
var _ _dafny.Dummy__
var _ m__System.Dummy__
var _ m_Types.Dummy__
var _ m__Errors.Dummy__
var _ m_Buffer.Dummy__
var _ m_WireFormat.Dummy__
var _ m_Aggregator.Dummy__
var _ m_Sender.Dummy__

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
	return "Singletons.Default__"
}
func (_this *Default__) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Default__{}

func (_static *CompanionStruct_Default___) IsPrintableNonPipe(c _dafny.CodePoint) bool {
	return (((_dafny.IntOfInt64(32)).Cmp(_dafny.IntOfInt32(rune(c))) <= 0) && ((_dafny.IntOfInt32(rune(c))).Cmp(_dafny.IntOfInt64(126)) <= 0)) && ((c) != (_dafny.CodePoint('|')) /* dircomp */)
}
func (_static *CompanionStruct_Default___) SanitizeExternalEnv(raw _dafny.Sequence) _dafny.Sequence {
	var _0___accumulator _dafny.Sequence = _dafny.SeqOf()
	_ = _0___accumulator
	goto TAIL_CALL_START
TAIL_CALL_START:
	if (_dafny.IntOfUint32((raw).Cardinality())).Sign() == 0 {
		return _dafny.Companion_Sequence_.Concatenate(_0___accumulator, _dafny.SeqOf())
	} else {
		_0___accumulator = _dafny.Companion_Sequence_.Concatenate(_0___accumulator, (func() _dafny.Sequence {
			if Companion_Default___.IsPrintableNonPipe((raw).Select(0).(_dafny.CodePoint)) {
				return _dafny.SeqOf((raw).Select(0).(_dafny.CodePoint))
			}
			return _dafny.SeqOf()
		})())
		var _in0 _dafny.Sequence = (raw).Drop(1)
		_ = _in0
		raw = _in0
		goto TAIL_CALL_START
	}
}

// End of class Default__

// Definition of datatype InitState
type InitState struct {
	Data_InitState_
}

func (_this InitState) Get_() Data_InitState_ {
	return _this.Data_InitState_
}

type Data_InitState_ interface {
	isInitState()
}

type CompanionStruct_InitState_ struct {
}

var Companion_InitState_ = CompanionStruct_InitState_{}

type InitState_Unset struct {
}

func (InitState_Unset) isInitState() {}

func (CompanionStruct_InitState_) Create_Unset_() InitState {
	return InitState{InitState_Unset{}}
}

func (_this InitState) Is_Unset() bool {
	_, ok := _this.Get_().(InitState_Unset)
	return ok
}

type InitState_Set struct {
}

func (InitState_Set) isInitState() {}

func (CompanionStruct_InitState_) Create_Set_() InitState {
	return InitState{InitState_Set{}}
}

func (_this InitState) Is_Set() bool {
	_, ok := _this.Get_().(InitState_Set)
	return ok
}

func (CompanionStruct_InitState_) Default() InitState {
	return Companion_InitState_.Create_Unset_()
}

func (_ CompanionStruct_InitState_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_InitState_.Create_Unset_(), true
		case 1:
			return Companion_InitState_.Create_Set_(), true
		default:
			return InitState{}, false
		}
	}
}

func (_this InitState) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case InitState_Unset:
		{
			return "Singletons.InitState.Unset"
		}
	case InitState_Set:
		{
			return "Singletons.InitState.Set"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this InitState) Equals(other InitState) bool {
	switch _this.Get_().(type) {
	case InitState_Unset:
		{
			_, ok := other.Get_().(InitState_Unset)
			return ok
		}
	case InitState_Set:
		{
			_, ok := other.Get_().(InitState_Set)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this InitState) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(InitState)
	return ok && _this.Equals(typed)
}

func Type_InitState_() _dafny.TypeDescriptor {
	return type_InitState_{}
}

type type_InitState_ struct {
}

func (_this type_InitState_) Default() interface{} {
	return Companion_InitState_.Default()
}

func (_this type_InitState_) String() string {
	return "Singletons.InitState"
}
func (_this InitState) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = InitState{}

// End of datatype InitState

// Definition of datatype Singleton
type Singleton struct {
	Data_Singleton_
}

func (_this Singleton) Get_() Data_Singleton_ {
	return _this.Data_Singleton_
}

type Data_Singleton_ interface {
	isSingleton()
}

type CompanionStruct_Singleton_ struct {
}

var Companion_Singleton_ = CompanionStruct_Singleton_{}

type Singleton_SingletonVal struct {
	State InitState
	Value interface{}
}

func (Singleton_SingletonVal) isSingleton() {}

func (CompanionStruct_Singleton_) Create_SingletonVal_(State InitState, Value interface{}) Singleton {
	return Singleton{Singleton_SingletonVal{State, Value}}
}

func (_this Singleton) Is_SingletonVal() bool {
	_, ok := _this.Get_().(Singleton_SingletonVal)
	return ok
}

func (CompanionStruct_Singleton_) Default(_default_T interface{}) Singleton {
	return Companion_Singleton_.Create_SingletonVal_(Companion_InitState_.Default(), _default_T)
}

func (_this Singleton) Dtor_state() InitState {
	return _this.Get_().(Singleton_SingletonVal).State
}

func (_this Singleton) Dtor_value() interface{} {
	return _this.Get_().(Singleton_SingletonVal).Value
}

func (_this Singleton) String() string {
	switch data := _this.Get_().(type) {
	case nil:
		return "null"
	case Singleton_SingletonVal:
		{
			return "Singletons.Singleton.SingletonVal" + "(" + _dafny.String(data.State) + ", " + _dafny.String(data.Value) + ")"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this Singleton) Equals(other Singleton) bool {
	switch data1 := _this.Get_().(type) {
	case Singleton_SingletonVal:
		{
			data2, ok := other.Get_().(Singleton_SingletonVal)
			return ok && data1.State.Equals(data2.State) && _dafny.AreEqual(data1.Value, data2.Value)
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this Singleton) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(Singleton)
	return ok && _this.Equals(typed)
}

func Type_Singleton_(Type_T_ _dafny.TypeDescriptor) _dafny.TypeDescriptor {
	return type_Singleton_{Type_T_}
}

type type_Singleton_ struct {
	Type_T_ _dafny.TypeDescriptor
}

func (_this type_Singleton_) Default() interface{} {
	Type_T_ := _this.Type_T_
	_ = Type_T_
	return Companion_Singleton_.Default(Type_T_.Default())
}

func (_this type_Singleton_) String() string {
	return "Singletons.Singleton"
}
func (_this Singleton) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = Singleton{}

// End of datatype Singleton

// Definition of class ContainerID
type ContainerID struct {
	S Singleton
}

func New_ContainerID_() *ContainerID {
	_this := ContainerID{}

	_this.S = Companion_Singleton_.Default(_dafny.EmptySeq)
	return &_this
}

type CompanionStruct_ContainerID_ struct {
}

var Companion_ContainerID_ = CompanionStruct_ContainerID_{}

func (_this *ContainerID) Equals(other *ContainerID) bool {
	return _this == other
}

func (_this *ContainerID) EqualsGeneric(x interface{}) bool {
	other, ok := x.(*ContainerID)
	return ok && _this.Equals(other)
}

func (*ContainerID) String() string {
	return "Singletons.ContainerID"
}

func Type_ContainerID_() _dafny.TypeDescriptor {
	return type_ContainerID_{}
}

type type_ContainerID_ struct {
}

func (_this type_ContainerID_) Default() interface{} {
	return (*ContainerID)(nil)
}

func (_this type_ContainerID_) String() string {
	return "Singletons.ContainerID"
}
func (_this *ContainerID) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &ContainerID{}

func (_this *ContainerID) Ctor__() {
	{
		(_this).S = Companion_Singleton_.Create_SingletonVal_(Companion_InitState_.Create_Unset_(), _dafny.UnicodeSeqOfUtf8Bytes(""))
	}
}
func (_this *ContainerID) Init(v _dafny.Sequence) {
	{
		(_this).S = Companion_Singleton_.Create_SingletonVal_(Companion_InitState_.Create_Set_(), v)
	}
}
func (_this *ContainerID) Get() m_Types.Option {
	{
		if ((_this.S).Dtor_state()).Equals(Companion_InitState_.Create_Set_()) {
			return m_Types.Companion_Option_.Create_Some_((_this.S).Dtor_value().(_dafny.Sequence))
		} else {
			return m_Types.Companion_Option_.Create_None_()
		}
	}
}

// End of class ContainerID

// Definition of class ExternalEnv
type ExternalEnv struct {
	S Singleton
}

func New_ExternalEnv_() *ExternalEnv {
	_this := ExternalEnv{}

	_this.S = Companion_Singleton_.Default(_dafny.EmptySeq)
	return &_this
}

type CompanionStruct_ExternalEnv_ struct {
}

var Companion_ExternalEnv_ = CompanionStruct_ExternalEnv_{}

func (_this *ExternalEnv) Equals(other *ExternalEnv) bool {
	return _this == other
}

func (_this *ExternalEnv) EqualsGeneric(x interface{}) bool {
	other, ok := x.(*ExternalEnv)
	return ok && _this.Equals(other)
}

func (*ExternalEnv) String() string {
	return "Singletons.ExternalEnv"
}

func Type_ExternalEnv_() _dafny.TypeDescriptor {
	return type_ExternalEnv_{}
}

type type_ExternalEnv_ struct {
}

func (_this type_ExternalEnv_) Default() interface{} {
	return (*ExternalEnv)(nil)
}

func (_this type_ExternalEnv_) String() string {
	return "Singletons.ExternalEnv"
}
func (_this *ExternalEnv) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &ExternalEnv{}

func (_this *ExternalEnv) Ctor__() {
	{
		(_this).S = Companion_Singleton_.Create_SingletonVal_(Companion_InitState_.Create_Unset_(), _dafny.UnicodeSeqOfUtf8Bytes(""))
	}
}
func (_this *ExternalEnv) Init(raw _dafny.Sequence) {
	{
		(_this).S = Companion_Singleton_.Create_SingletonVal_(Companion_InitState_.Create_Set_(), Companion_Default___.SanitizeExternalEnv(raw))
	}
}
func (_this *ExternalEnv) Get() _dafny.Sequence {
	{
		if ((_this.S).Dtor_state()).Equals(Companion_InitState_.Create_Set_()) {
			return (_this.S).Dtor_value().(_dafny.Sequence)
		} else {
			return _dafny.UnicodeSeqOfUtf8Bytes("")
		}
	}
}

// End of class ExternalEnv
