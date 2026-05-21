// Package Sender
// Dafny module Sender compiled into Go

package Sender

import (
	m_Aggregator "Aggregator"
	m_Buffer "Buffer"
	m__Errors "Errors_"
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
	return "Sender.Default__"
}
func (_this *Default__) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Default__{}

func (_static *CompanionStruct_Default___) FirstIndexOf(s _dafny.Sequence, x interface{}) _dafny.Int {
	var _0___accumulator _dafny.Int = _dafny.Zero
	_ = _0___accumulator
	goto TAIL_CALL_START
TAIL_CALL_START:
	if _dafny.AreEqual((s).Select(0).(interface{}), x) {
		return (_dafny.Zero).Plus(_0___accumulator)
	} else {
		_0___accumulator = (_0___accumulator).Plus(_dafny.One)
		var _in0 _dafny.Sequence = (s).Drop(1)
		_ = _in0
		var _in1 interface{} = x
		_ = _in1
		s = _in0
		x = _in1
		goto TAIL_CALL_START
	}
}

// End of class Default__

// Definition of datatype SenderState
type SenderState struct {
	Data_SenderState_
}

func (_this SenderState) Get_() Data_SenderState_ {
	return _this.Data_SenderState_
}

type Data_SenderState_ interface {
	isSenderState()
}

type CompanionStruct_SenderState_ struct {
}

var Companion_SenderState_ = CompanionStruct_SenderState_{}

type SenderState_Running struct {
}

func (SenderState_Running) isSenderState() {}

func (CompanionStruct_SenderState_) Create_Running_() SenderState {
	return SenderState{SenderState_Running{}}
}

func (_this SenderState) Is_Running() bool {
	_, ok := _this.Get_().(SenderState_Running)
	return ok
}

type SenderState_Stopped struct {
}

func (SenderState_Stopped) isSenderState() {}

func (CompanionStruct_SenderState_) Create_Stopped_() SenderState {
	return SenderState{SenderState_Stopped{}}
}

func (_this SenderState) Is_Stopped() bool {
	_, ok := _this.Get_().(SenderState_Stopped)
	return ok
}

func (CompanionStruct_SenderState_) Default() SenderState {
	return Companion_SenderState_.Create_Running_()
}

func (_ CompanionStruct_SenderState_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_SenderState_.Create_Running_(), true
		case 1:
			return Companion_SenderState_.Create_Stopped_(), true
		default:
			return SenderState{}, false
		}
	}
}

func (_this SenderState) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case SenderState_Running:
		{
			return "Sender.SenderState.Running"
		}
	case SenderState_Stopped:
		{
			return "Sender.SenderState.Stopped"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this SenderState) Equals(other SenderState) bool {
	switch _this.Get_().(type) {
	case SenderState_Running:
		{
			_, ok := other.Get_().(SenderState_Running)
			return ok
		}
	case SenderState_Stopped:
		{
			_, ok := other.Get_().(SenderState_Stopped)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this SenderState) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(SenderState)
	return ok && _this.Equals(typed)
}

func Type_SenderState_() _dafny.TypeDescriptor {
	return type_SenderState_{}
}

type type_SenderState_ struct {
}

func (_this type_SenderState_) Default() interface{} {
	return Companion_SenderState_.Default()
}

func (_this type_SenderState_) String() string {
	return "Sender.SenderState"
}
func (_this SenderState) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = SenderState{}

// End of datatype SenderState

// Definition of datatype Telemetry
type Telemetry struct {
	Data_Telemetry_
}

func (_this Telemetry) Get_() Data_Telemetry_ {
	return _this.Data_Telemetry_
}

type Data_Telemetry_ interface {
	isTelemetry()
}

type CompanionStruct_Telemetry_ struct {
}

var Companion_Telemetry_ = CompanionStruct_Telemetry_{}

type Telemetry_Telemetry struct {
	PayloadsSent             _dafny.Int
	PayloadsDroppedQueueFull _dafny.Int
	PayloadsDroppedWriter    _dafny.Int
	BytesSent                _dafny.Int
	BytesDroppedQueueFull    _dafny.Int
	BytesDroppedWriter       _dafny.Int
}

func (Telemetry_Telemetry) isTelemetry() {}

func (CompanionStruct_Telemetry_) Create_Telemetry_(PayloadsSent _dafny.Int, PayloadsDroppedQueueFull _dafny.Int, PayloadsDroppedWriter _dafny.Int, BytesSent _dafny.Int, BytesDroppedQueueFull _dafny.Int, BytesDroppedWriter _dafny.Int) Telemetry {
	return Telemetry{Telemetry_Telemetry{PayloadsSent, PayloadsDroppedQueueFull, PayloadsDroppedWriter, BytesSent, BytesDroppedQueueFull, BytesDroppedWriter}}
}

func (_this Telemetry) Is_Telemetry() bool {
	_, ok := _this.Get_().(Telemetry_Telemetry)
	return ok
}

func (CompanionStruct_Telemetry_) Default() Telemetry {
	return Companion_Telemetry_.Create_Telemetry_(_dafny.Zero, _dafny.Zero, _dafny.Zero, _dafny.Zero, _dafny.Zero, _dafny.Zero)
}

func (_this Telemetry) Dtor_payloadsSent() _dafny.Int {
	return _this.Get_().(Telemetry_Telemetry).PayloadsSent
}

func (_this Telemetry) Dtor_payloadsDroppedQueueFull() _dafny.Int {
	return _this.Get_().(Telemetry_Telemetry).PayloadsDroppedQueueFull
}

func (_this Telemetry) Dtor_payloadsDroppedWriter() _dafny.Int {
	return _this.Get_().(Telemetry_Telemetry).PayloadsDroppedWriter
}

func (_this Telemetry) Dtor_bytesSent() _dafny.Int {
	return _this.Get_().(Telemetry_Telemetry).BytesSent
}

func (_this Telemetry) Dtor_bytesDroppedQueueFull() _dafny.Int {
	return _this.Get_().(Telemetry_Telemetry).BytesDroppedQueueFull
}

func (_this Telemetry) Dtor_bytesDroppedWriter() _dafny.Int {
	return _this.Get_().(Telemetry_Telemetry).BytesDroppedWriter
}

func (_this Telemetry) String() string {
	switch data := _this.Get_().(type) {
	case nil:
		return "null"
	case Telemetry_Telemetry:
		{
			return "Sender.Telemetry.Telemetry" + "(" + _dafny.String(data.PayloadsSent) + ", " + _dafny.String(data.PayloadsDroppedQueueFull) + ", " + _dafny.String(data.PayloadsDroppedWriter) + ", " + _dafny.String(data.BytesSent) + ", " + _dafny.String(data.BytesDroppedQueueFull) + ", " + _dafny.String(data.BytesDroppedWriter) + ")"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this Telemetry) Equals(other Telemetry) bool {
	switch data1 := _this.Get_().(type) {
	case Telemetry_Telemetry:
		{
			data2, ok := other.Get_().(Telemetry_Telemetry)
			return ok && data1.PayloadsSent.Cmp(data2.PayloadsSent) == 0 && data1.PayloadsDroppedQueueFull.Cmp(data2.PayloadsDroppedQueueFull) == 0 && data1.PayloadsDroppedWriter.Cmp(data2.PayloadsDroppedWriter) == 0 && data1.BytesSent.Cmp(data2.BytesSent) == 0 && data1.BytesDroppedQueueFull.Cmp(data2.BytesDroppedQueueFull) == 0 && data1.BytesDroppedWriter.Cmp(data2.BytesDroppedWriter) == 0
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this Telemetry) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(Telemetry)
	return ok && _this.Equals(typed)
}

func Type_Telemetry_() _dafny.TypeDescriptor {
	return type_Telemetry_{}
}

type type_Telemetry_ struct {
}

func (_this type_Telemetry_) Default() interface{} {
	return Companion_Telemetry_.Default()
}

func (_this type_Telemetry_) String() string {
	return "Sender.Telemetry"
}
func (_this Telemetry) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = Telemetry{}

// End of datatype Telemetry

// Definition of trait Transport
type Transport interface {
	String() string
	Write(data _dafny.Sequence) m__Errors.Result
	Close()
}
type CompanionStruct_Transport_ struct {
	TraitID_ *_dafny.TraitID
}

var Companion_Transport_ = CompanionStruct_Transport_{
	TraitID_: &_dafny.TraitID{},
}

func (CompanionStruct_Transport_) CastTo_(x interface{}) Transport {
	var t Transport
	t, _ = x.(Transport)
	return t
}

// End of trait Transport

// Definition of class Sender
type Sender struct {
	State        SenderState
	Queue        _dafny.Sequence
	MaxQueueSize _dafny.Int
	Telemetry    Telemetry
}

func New_Sender_() *Sender {
	_this := Sender{}

	_this.State = Companion_SenderState_.Default()
	_this.Queue = _dafny.EmptySeq
	_this.MaxQueueSize = _dafny.Zero
	_this.Telemetry = Companion_Telemetry_.Default()
	return &_this
}

type CompanionStruct_Sender_ struct {
}

var Companion_Sender_ = CompanionStruct_Sender_{}

func (_this *Sender) Equals(other *Sender) bool {
	return _this == other
}

func (_this *Sender) EqualsGeneric(x interface{}) bool {
	other, ok := x.(*Sender)
	return ok && _this.Equals(other)
}

func (*Sender) String() string {
	return "Sender.Sender"
}

func Type_Sender_() _dafny.TypeDescriptor {
	return type_Sender_{}
}

type type_Sender_ struct {
}

func (_this type_Sender_) Default() interface{} {
	return (*Sender)(nil)
}

func (_this type_Sender_) String() string {
	return "Sender.Sender"
}
func (_this *Sender) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Sender{}

func (_this *Sender) New(mqs _dafny.Int) {
	{
		(_this).State = Companion_SenderState_.Create_Running_()
		(_this).Queue = _dafny.SeqOf()
		(_this).MaxQueueSize = mqs
		(_this).Telemetry = Companion_Telemetry_.Create_Telemetry_(_dafny.Zero, _dafny.Zero, _dafny.Zero, _dafny.Zero, _dafny.Zero, _dafny.Zero)
	}
}
func (_this *Sender) Enqueue(b *m_Buffer.Buffer) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_dafny.IntOfUint32((_this.Queue).Cardinality())).Cmp(_this.MaxQueueSize) < 0 {
			(_this).Queue = _dafny.Companion_Sequence_.Concatenate(_this.Queue, _dafny.SeqOf(b))
			r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		} else {
			var _0_dropped _dafny.Int
			_ = _0_dropped
			_0_dropped = b.Len
			var _1_dt__update__tmp_h0 Telemetry = _this.Telemetry
			_ = _1_dt__update__tmp_h0
			var _2_dt__update_hbytesDroppedQueueFull_h0 _dafny.Int = ((_this.Telemetry).Dtor_bytesDroppedQueueFull()).Plus(_0_dropped)
			_ = _2_dt__update_hbytesDroppedQueueFull_h0
			var _3_dt__update_hpayloadsDroppedQueueFull_h0 _dafny.Int = ((_this.Telemetry).Dtor_payloadsDroppedQueueFull()).Plus(_dafny.One)
			_ = _3_dt__update_hpayloadsDroppedQueueFull_h0
			(_this).Telemetry = Companion_Telemetry_.Create_Telemetry_((_1_dt__update__tmp_h0).Dtor_payloadsSent(), _3_dt__update_hpayloadsDroppedQueueFull_h0, (_1_dt__update__tmp_h0).Dtor_payloadsDroppedWriter(), (_1_dt__update__tmp_h0).Dtor_bytesSent(), _2_dt__update_hbytesDroppedQueueFull_h0, (_1_dt__update__tmp_h0).Dtor_bytesDroppedWriter())
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrorSenderChannelFull_())
		}
		return r
	}
}
func (_this *Sender) Send(transport Transport) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		var _0_buf *m_Buffer.Buffer
		_ = _0_buf
		_0_buf = (_this.Queue).Select(0).(*m_Buffer.Buffer)
		(_this).Queue = (_this.Queue).Drop(1)
		var _1_bytes _dafny.Sequence
		_ = _1_bytes
		_1_bytes = (_0_buf).Bytes()
		var _2_wr m__Errors.Result
		_ = _2_wr
		var _out0 m__Errors.Result
		_ = _out0
		_out0 = (transport).Write(_1_bytes)
		_2_wr = _out0
		var _source0 m__Errors.Result = _2_wr
		_ = _source0
		{
			{
				if _source0.Is_Ok() {
					var _3_dt__update__tmp_h0 Telemetry = _this.Telemetry
					_ = _3_dt__update__tmp_h0
					var _4_dt__update_hbytesSent_h0 _dafny.Int = ((_this.Telemetry).Dtor_bytesSent()).Plus(_dafny.IntOfUint32((_1_bytes).Cardinality()))
					_ = _4_dt__update_hbytesSent_h0
					var _5_dt__update_hpayloadsSent_h0 _dafny.Int = ((_this.Telemetry).Dtor_payloadsSent()).Plus(_dafny.One)
					_ = _5_dt__update_hpayloadsSent_h0
					(_this).Telemetry = Companion_Telemetry_.Create_Telemetry_(_5_dt__update_hpayloadsSent_h0, (_3_dt__update__tmp_h0).Dtor_payloadsDroppedQueueFull(), (_3_dt__update__tmp_h0).Dtor_payloadsDroppedWriter(), _4_dt__update_hbytesSent_h0, (_3_dt__update__tmp_h0).Dtor_bytesDroppedQueueFull(), (_3_dt__update__tmp_h0).Dtor_bytesDroppedWriter())
					r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
					goto Lmatch0
				}
			}
			{
				var _6_e m__Errors.DogStatsDError = _source0.Get_().(m__Errors.Result_Err).Error
				_ = _6_e
				var _7_dt__update__tmp_h1 Telemetry = _this.Telemetry
				_ = _7_dt__update__tmp_h1
				var _8_dt__update_hbytesDroppedWriter_h0 _dafny.Int = ((_this.Telemetry).Dtor_bytesDroppedWriter()).Plus(_dafny.IntOfUint32((_1_bytes).Cardinality()))
				_ = _8_dt__update_hbytesDroppedWriter_h0
				var _9_dt__update_hpayloadsDroppedWriter_h0 _dafny.Int = ((_this.Telemetry).Dtor_payloadsDroppedWriter()).Plus(_dafny.One)
				_ = _9_dt__update_hpayloadsDroppedWriter_h0
				(_this).Telemetry = Companion_Telemetry_.Create_Telemetry_((_7_dt__update__tmp_h1).Dtor_payloadsSent(), (_7_dt__update__tmp_h1).Dtor_payloadsDroppedQueueFull(), _9_dt__update_hpayloadsDroppedWriter_h0, (_7_dt__update__tmp_h1).Dtor_bytesSent(), (_7_dt__update__tmp_h1).Dtor_bytesDroppedQueueFull(), _8_dt__update_hbytesDroppedWriter_h0)
				r = m__Errors.Companion_Result_.Create_Err_(_6_e)
			}
			goto Lmatch0
		}
	Lmatch0:
		return r
	}
}
func (_this *Sender) Stop(transport Transport) {
	{
		for (_dafny.IntOfUint32((_this.Queue).Cardinality())).Sign() == 1 {
			var _0_prevQueue _dafny.Sequence
			_ = _0_prevQueue
			_0_prevQueue = _this.Queue
			var _1_buf *m_Buffer.Buffer
			_ = _1_buf
			_1_buf = (_0_prevQueue).Select(0).(*m_Buffer.Buffer)
			(_this).Queue = (_0_prevQueue).Drop(1)
			var _2_bytes _dafny.Sequence
			_ = _2_bytes
			_2_bytes = (_1_buf).Bytes()
			var _3_wr m__Errors.Result
			_ = _3_wr
			var _out0 m__Errors.Result
			_ = _out0
			_out0 = (transport).Write(_2_bytes)
			_3_wr = _out0
			var _source0 m__Errors.Result = _3_wr
			_ = _source0
			{
				{
					if _source0.Is_Ok() {
						var _4_dt__update__tmp_h0 Telemetry = _this.Telemetry
						_ = _4_dt__update__tmp_h0
						var _5_dt__update_hbytesSent_h0 _dafny.Int = ((_this.Telemetry).Dtor_bytesSent()).Plus(_dafny.IntOfUint32((_2_bytes).Cardinality()))
						_ = _5_dt__update_hbytesSent_h0
						var _6_dt__update_hpayloadsSent_h0 _dafny.Int = ((_this.Telemetry).Dtor_payloadsSent()).Plus(_dafny.One)
						_ = _6_dt__update_hpayloadsSent_h0
						(_this).Telemetry = Companion_Telemetry_.Create_Telemetry_(_6_dt__update_hpayloadsSent_h0, (_4_dt__update__tmp_h0).Dtor_payloadsDroppedQueueFull(), (_4_dt__update__tmp_h0).Dtor_payloadsDroppedWriter(), _5_dt__update_hbytesSent_h0, (_4_dt__update__tmp_h0).Dtor_bytesDroppedQueueFull(), (_4_dt__update__tmp_h0).Dtor_bytesDroppedWriter())
						goto Lmatch0
					}
				}
				{
					var _7_dt__update__tmp_h1 Telemetry = _this.Telemetry
					_ = _7_dt__update__tmp_h1
					var _8_dt__update_hbytesDroppedWriter_h0 _dafny.Int = ((_this.Telemetry).Dtor_bytesDroppedWriter()).Plus(_dafny.IntOfUint32((_2_bytes).Cardinality()))
					_ = _8_dt__update_hbytesDroppedWriter_h0
					var _9_dt__update_hpayloadsDroppedWriter_h0 _dafny.Int = ((_this.Telemetry).Dtor_payloadsDroppedWriter()).Plus(_dafny.One)
					_ = _9_dt__update_hpayloadsDroppedWriter_h0
					(_this).Telemetry = Companion_Telemetry_.Create_Telemetry_((_7_dt__update__tmp_h1).Dtor_payloadsSent(), (_7_dt__update__tmp_h1).Dtor_payloadsDroppedQueueFull(), _9_dt__update_hpayloadsDroppedWriter_h0, (_7_dt__update__tmp_h1).Dtor_bytesSent(), (_7_dt__update__tmp_h1).Dtor_bytesDroppedQueueFull(), _8_dt__update_hbytesDroppedWriter_h0)
				}
				goto Lmatch0
			}
		Lmatch0:
		}
		(transport).Close()
		(_this).State = Companion_SenderState_.Create_Stopped_()
	}
}

// End of class Sender
