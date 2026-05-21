// Package _Errors
// Dafny module _Errors compiled into Go

package _Errors

import (
	m__System "System_"
	m_Types "Types"
	_dafny "dafny"
	os "os"
)

var _ = os.Args
var _ _dafny.Dummy__
var _ m__System.Dummy__
var _ m_Types.Dummy__

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
	return "_Errors.Default__"
}
func (_this *Default__) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Default__{}

func (_static *CompanionStruct_Default___) ErrorMessage(e DogStatsDError) _dafny.Sequence {
	var _source0 DogStatsDError = e
	_ = _source0
	{
		if _source0.Is_ErrNoClient() {
			return _dafny.UnicodeSeqOfUtf8Bytes("operation on nil or closed client")
		}
	}
	{
		if _source0.Is_ErrorInputChannelFull() {
			return _dafny.UnicodeSeqOfUtf8Bytes("worker input channel full")
		}
	}
	{
		if _source0.Is_ErrorSenderChannelFull() {
			return _dafny.UnicodeSeqOfUtf8Bytes("sender channel full")
		}
	}
	{
		return _dafny.UnicodeSeqOfUtf8Bytes("metric exceeds max bytes per payload")
	}
}

// End of class Default__

// Definition of datatype DogStatsDError
type DogStatsDError struct {
	Data_DogStatsDError_
}

func (_this DogStatsDError) Get_() Data_DogStatsDError_ {
	return _this.Data_DogStatsDError_
}

type Data_DogStatsDError_ interface {
	isDogStatsDError()
}

type CompanionStruct_DogStatsDError_ struct {
}

var Companion_DogStatsDError_ = CompanionStruct_DogStatsDError_{}

type DogStatsDError_ErrNoClient struct {
}

func (DogStatsDError_ErrNoClient) isDogStatsDError() {}

func (CompanionStruct_DogStatsDError_) Create_ErrNoClient_() DogStatsDError {
	return DogStatsDError{DogStatsDError_ErrNoClient{}}
}

func (_this DogStatsDError) Is_ErrNoClient() bool {
	_, ok := _this.Get_().(DogStatsDError_ErrNoClient)
	return ok
}

type DogStatsDError_ErrorInputChannelFull struct {
}

func (DogStatsDError_ErrorInputChannelFull) isDogStatsDError() {}

func (CompanionStruct_DogStatsDError_) Create_ErrorInputChannelFull_() DogStatsDError {
	return DogStatsDError{DogStatsDError_ErrorInputChannelFull{}}
}

func (_this DogStatsDError) Is_ErrorInputChannelFull() bool {
	_, ok := _this.Get_().(DogStatsDError_ErrorInputChannelFull)
	return ok
}

type DogStatsDError_ErrorSenderChannelFull struct {
}

func (DogStatsDError_ErrorSenderChannelFull) isDogStatsDError() {}

func (CompanionStruct_DogStatsDError_) Create_ErrorSenderChannelFull_() DogStatsDError {
	return DogStatsDError{DogStatsDError_ErrorSenderChannelFull{}}
}

func (_this DogStatsDError) Is_ErrorSenderChannelFull() bool {
	_, ok := _this.Get_().(DogStatsDError_ErrorSenderChannelFull)
	return ok
}

type DogStatsDError_MessageTooLongError struct {
}

func (DogStatsDError_MessageTooLongError) isDogStatsDError() {}

func (CompanionStruct_DogStatsDError_) Create_MessageTooLongError_() DogStatsDError {
	return DogStatsDError{DogStatsDError_MessageTooLongError{}}
}

func (_this DogStatsDError) Is_MessageTooLongError() bool {
	_, ok := _this.Get_().(DogStatsDError_MessageTooLongError)
	return ok
}

func (CompanionStruct_DogStatsDError_) Default() DogStatsDError {
	return Companion_DogStatsDError_.Create_ErrNoClient_()
}

func (_ CompanionStruct_DogStatsDError_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_DogStatsDError_.Create_ErrNoClient_(), true
		case 1:
			return Companion_DogStatsDError_.Create_ErrorInputChannelFull_(), true
		case 2:
			return Companion_DogStatsDError_.Create_ErrorSenderChannelFull_(), true
		case 3:
			return Companion_DogStatsDError_.Create_MessageTooLongError_(), true
		default:
			return DogStatsDError{}, false
		}
	}
}

func (_this DogStatsDError) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case DogStatsDError_ErrNoClient:
		{
			return "Errors.DogStatsDError.ErrNoClient"
		}
	case DogStatsDError_ErrorInputChannelFull:
		{
			return "Errors.DogStatsDError.ErrorInputChannelFull"
		}
	case DogStatsDError_ErrorSenderChannelFull:
		{
			return "Errors.DogStatsDError.ErrorSenderChannelFull"
		}
	case DogStatsDError_MessageTooLongError:
		{
			return "Errors.DogStatsDError.MessageTooLongError"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this DogStatsDError) Equals(other DogStatsDError) bool {
	switch _this.Get_().(type) {
	case DogStatsDError_ErrNoClient:
		{
			_, ok := other.Get_().(DogStatsDError_ErrNoClient)
			return ok
		}
	case DogStatsDError_ErrorInputChannelFull:
		{
			_, ok := other.Get_().(DogStatsDError_ErrorInputChannelFull)
			return ok
		}
	case DogStatsDError_ErrorSenderChannelFull:
		{
			_, ok := other.Get_().(DogStatsDError_ErrorSenderChannelFull)
			return ok
		}
	case DogStatsDError_MessageTooLongError:
		{
			_, ok := other.Get_().(DogStatsDError_MessageTooLongError)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this DogStatsDError) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(DogStatsDError)
	return ok && _this.Equals(typed)
}

func Type_DogStatsDError_() _dafny.TypeDescriptor {
	return type_DogStatsDError_{}
}

type type_DogStatsDError_ struct {
}

func (_this type_DogStatsDError_) Default() interface{} {
	return Companion_DogStatsDError_.Default()
}

func (_this type_DogStatsDError_) String() string {
	return "_Errors.DogStatsDError"
}
func (_this DogStatsDError) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = DogStatsDError{}

// End of datatype DogStatsDError

// Definition of datatype Result
type Result struct {
	Data_Result_
}

func (_this Result) Get_() Data_Result_ {
	return _this.Data_Result_
}

type Data_Result_ interface {
	isResult()
}

type CompanionStruct_Result_ struct {
}

var Companion_Result_ = CompanionStruct_Result_{}

type Result_Ok struct {
	Value interface{}
}

func (Result_Ok) isResult() {}

func (CompanionStruct_Result_) Create_Ok_(Value interface{}) Result {
	return Result{Result_Ok{Value}}
}

func (_this Result) Is_Ok() bool {
	_, ok := _this.Get_().(Result_Ok)
	return ok
}

type Result_Err struct {
	Error DogStatsDError
}

func (Result_Err) isResult() {}

func (CompanionStruct_Result_) Create_Err_(Error DogStatsDError) Result {
	return Result{Result_Err{Error}}
}

func (_this Result) Is_Err() bool {
	_, ok := _this.Get_().(Result_Err)
	return ok
}

func (CompanionStruct_Result_) Default() Result {
	return Companion_Result_.Create_Err_(Companion_DogStatsDError_.Default())
}

func (_this Result) Dtor_value() interface{} {
	return _this.Get_().(Result_Ok).Value
}

func (_this Result) Dtor_error() DogStatsDError {
	return _this.Get_().(Result_Err).Error
}

func (_this Result) String() string {
	switch data := _this.Get_().(type) {
	case nil:
		return "null"
	case Result_Ok:
		{
			return "Errors.Result.Ok" + "(" + _dafny.String(data.Value) + ")"
		}
	case Result_Err:
		{
			return "Errors.Result.Err" + "(" + _dafny.String(data.Error) + ")"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this Result) Equals(other Result) bool {
	switch data1 := _this.Get_().(type) {
	case Result_Ok:
		{
			data2, ok := other.Get_().(Result_Ok)
			return ok && _dafny.AreEqual(data1.Value, data2.Value)
		}
	case Result_Err:
		{
			data2, ok := other.Get_().(Result_Err)
			return ok && data1.Error.Equals(data2.Error)
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this Result) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(Result)
	return ok && _this.Equals(typed)
}

func Type_Result_() _dafny.TypeDescriptor {
	return type_Result_{}
}

type type_Result_ struct {
}

func (_this type_Result_) Default() interface{} {
	return Companion_Result_.Default()
}

func (_this type_Result_) String() string {
	return "_Errors.Result"
}
func (_this Result) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = Result{}

// End of datatype Result
