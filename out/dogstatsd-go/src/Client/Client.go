// Package Client
// Dafny module Client compiled into Go

package Client

import (
	m_Aggregator "Aggregator"
	m_Buffer "Buffer"
	m__Errors "Errors_"
	m_Sender "Sender"
	m_Singletons "Singletons"
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
var _ m_Singletons.Dummy__

type Dummy__ struct{}

// Definition of datatype ClientState
type ClientState struct {
	Data_ClientState_
}

func (_this ClientState) Get_() Data_ClientState_ {
	return _this.Data_ClientState_
}

type Data_ClientState_ interface {
	isClientState()
}

type CompanionStruct_ClientState_ struct {
}

var Companion_ClientState_ = CompanionStruct_ClientState_{}

type ClientState_Open struct {
}

func (ClientState_Open) isClientState() {}

func (CompanionStruct_ClientState_) Create_Open_() ClientState {
	return ClientState{ClientState_Open{}}
}

func (_this ClientState) Is_Open() bool {
	_, ok := _this.Get_().(ClientState_Open)
	return ok
}

type ClientState_Closed struct {
}

func (ClientState_Closed) isClientState() {}

func (CompanionStruct_ClientState_) Create_Closed_() ClientState {
	return ClientState{ClientState_Closed{}}
}

func (_this ClientState) Is_Closed() bool {
	_, ok := _this.Get_().(ClientState_Closed)
	return ok
}

func (CompanionStruct_ClientState_) Default() ClientState {
	return Companion_ClientState_.Create_Open_()
}

func (_ CompanionStruct_ClientState_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_ClientState_.Create_Open_(), true
		case 1:
			return Companion_ClientState_.Create_Closed_(), true
		default:
			return ClientState{}, false
		}
	}
}

func (_this ClientState) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case ClientState_Open:
		{
			return "Client.ClientState.Open"
		}
	case ClientState_Closed:
		{
			return "Client.ClientState.Closed"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this ClientState) Equals(other ClientState) bool {
	switch _this.Get_().(type) {
	case ClientState_Open:
		{
			_, ok := other.Get_().(ClientState_Open)
			return ok
		}
	case ClientState_Closed:
		{
			_, ok := other.Get_().(ClientState_Closed)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this ClientState) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(ClientState)
	return ok && _this.Equals(typed)
}

func Type_ClientState_() _dafny.TypeDescriptor {
	return type_ClientState_{}
}

type type_ClientState_ struct {
}

func (_this type_ClientState_) Default() interface{} {
	return Companion_ClientState_.Default()
}

func (_this type_ClientState_) String() string {
	return "Client.ClientState"
}
func (_this ClientState) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = ClientState{}

// End of datatype ClientState

// Definition of class NullTransport
type NullTransport struct {
	dummy byte
}

func New_NullTransport_() *NullTransport {
	_this := NullTransport{}

	return &_this
}

type CompanionStruct_NullTransport_ struct {
}

var Companion_NullTransport_ = CompanionStruct_NullTransport_{}

func (_this *NullTransport) Equals(other *NullTransport) bool {
	return _this == other
}

func (_this *NullTransport) EqualsGeneric(x interface{}) bool {
	other, ok := x.(*NullTransport)
	return ok && _this.Equals(other)
}

func (*NullTransport) String() string {
	return "_module.NullTransport"
}

func Type_NullTransport_() _dafny.TypeDescriptor {
	return type_NullTransport_{}
}

type type_NullTransport_ struct {
}

func (_this type_NullTransport_) Default() interface{} {
	return (*NullTransport)(nil)
}

func (_this type_NullTransport_) String() string {
	return "Client.NullTransport"
}
func (_this *NullTransport) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){m_Sender.Companion_Transport_.TraitID_}
}

var _ m_Sender.Transport = &NullTransport{}
var _ _dafny.TraitOffspring = &NullTransport{}

func (_this *NullTransport) Ctor__() {
	{
	}
}
func (_this *NullTransport) Write(data _dafny.Sequence) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		r = m__Errors.Companion_Result_.Create_Ok_(_dafny.Zero)
		return r
	}
}
func (_this *NullTransport) Close() {
	{
	}
}

// End of class NullTransport

// Definition of class Client
type Client struct {
	State       ClientState
	Aggregator  *m_Aggregator.Aggregator
	Sender      *m_Sender.Sender
	Config      m_Types.DogStatsDConfig
	ContainerID *m_Singletons.ContainerID
	ExternalEnv *m_Singletons.ExternalEnv
}

func New_Client_() *Client {
	_this := Client{}

	_this.State = Companion_ClientState_.Default()
	_this.Aggregator = (*m_Aggregator.Aggregator)(nil)
	_this.Sender = (*m_Sender.Sender)(nil)
	_this.Config = m_Types.Companion_DogStatsDConfig_.Default()
	_this.ContainerID = (*m_Singletons.ContainerID)(nil)
	_this.ExternalEnv = (*m_Singletons.ExternalEnv)(nil)
	return &_this
}

type CompanionStruct_Client_ struct {
}

var Companion_Client_ = CompanionStruct_Client_{}

func (_this *Client) Equals(other *Client) bool {
	return _this == other
}

func (_this *Client) EqualsGeneric(x interface{}) bool {
	other, ok := x.(*Client)
	return ok && _this.Equals(other)
}

func (*Client) String() string {
	return "_module.Client"
}

func Type_Client_() _dafny.TypeDescriptor {
	return type_Client_{}
}

type type_Client_ struct {
}

func (_this type_Client_) Default() interface{} {
	return (*Client)(nil)
}

func (_this type_Client_) String() string {
	return "Client.Client"
}
func (_this *Client) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Client{}

func (_this *Client) New(cfg m_Types.DogStatsDConfig) {
	{
		var _0_agg *m_Aggregator.Aggregator
		_ = _0_agg
		var _nw0 *m_Aggregator.Aggregator = m_Aggregator.New_Aggregator_()
		_ = _nw0
		_nw0.New(_dafny.IntOfInt64(4))
		_0_agg = _nw0
		var _1_snd *m_Sender.Sender
		_ = _1_snd
		var _nw1 *m_Sender.Sender = m_Sender.New_Sender_()
		_ = _nw1
		_nw1.New((cfg).Dtor_senderQueueSize())
		_1_snd = _nw1
		var _2_cid *m_Singletons.ContainerID
		_ = _2_cid
		var _nw2 *m_Singletons.ContainerID = m_Singletons.New_ContainerID_()
		_ = _nw2
		_nw2.Ctor__()
		_2_cid = _nw2
		var _3_env *m_Singletons.ExternalEnv
		_ = _3_env
		var _nw3 *m_Singletons.ExternalEnv = m_Singletons.New_ExternalEnv_()
		_ = _nw3
		_nw3.Ctor__()
		_3_env = _nw3
		(_this).Config = cfg
		(_this).Aggregator = _0_agg
		(_this).Sender = _1_snd
		(_this).ContainerID = _2_cid
		(_this).ExternalEnv = _3_env
		(_this).State = Companion_ClientState_.Create_Open_()
	}
}
func (_this *Client) SubmitGauge(ctx m_Types.MetricContext, value _dafny.Real, rate _dafny.Real) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_this.State).Equals(Companion_ClientState_.Create_Closed_()) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrNoClient_())
			return r
		}
		if (_this.Config).Dtor_aggregationEnabled() {
			(_this.Aggregator).SampleGauge(ctx, value)
		}
		r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Client) SubmitCount(ctx m_Types.MetricContext, value _dafny.Int, rate _dafny.Real) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_this.State).Equals(Companion_ClientState_.Create_Closed_()) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrNoClient_())
			return r
		}
		if (_this.Config).Dtor_aggregationEnabled() {
			(_this.Aggregator).SampleCount(ctx, value)
		}
		r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Client) SubmitSet(ctx m_Types.MetricContext, value _dafny.Sequence, rate _dafny.Real) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_this.State).Equals(Companion_ClientState_.Create_Closed_()) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrNoClient_())
			return r
		}
		if (_this.Config).Dtor_aggregationEnabled() {
			(_this.Aggregator).SampleSet(ctx, value)
		}
		r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Client) SubmitHistogram(ctx m_Types.MetricContext, value _dafny.Real, rate _dafny.Real) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_this.State).Equals(Companion_ClientState_.Create_Closed_()) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrNoClient_())
			return r
		}
		if (_this.Config).Dtor_extendedAggregation() {
			(_this.Aggregator).SampleBuffered(ctx, value, (_this.Config).Dtor_maxSamplesPerContext())
		}
		r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Client) SubmitDistribution(ctx m_Types.MetricContext, value _dafny.Real, rate _dafny.Real) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_this.State).Equals(Companion_ClientState_.Create_Closed_()) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrNoClient_())
			return r
		}
		if (_this.Config).Dtor_extendedAggregation() {
			(_this.Aggregator).SampleBuffered(ctx, value, (_this.Config).Dtor_maxSamplesPerContext())
		}
		r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Client) SubmitTiming(ctx m_Types.MetricContext, value _dafny.Real, rate _dafny.Real) m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_this.State).Equals(Companion_ClientState_.Create_Closed_()) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrNoClient_())
			return r
		}
		if (_this.Config).Dtor_extendedAggregation() {
			(_this.Aggregator).SampleBuffered(ctx, value, (_this.Config).Dtor_maxSamplesPerContext())
		}
		r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Client) Flush() m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_this.State).Equals(Companion_ClientState_.Create_Closed_()) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrNoClient_())
			return r
		}
		var _0___v0 _dafny.Sequence
		_ = _0___v0
		var _out0 _dafny.Sequence
		_ = _out0
		_out0 = (_this.Aggregator).Flush()
		_0___v0 = _out0
		r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Client) Close() m__Errors.Result {
	{
		var r m__Errors.Result = m__Errors.Companion_Result_.Default()
		_ = r
		if (_this.State).Equals(Companion_ClientState_.Create_Closed_()) {
			r = m__Errors.Companion_Result_.Create_Err_(m__Errors.Companion_DogStatsDError_.Create_ErrNoClient_())
			return r
		}
		var _0___v1 _dafny.Sequence
		_ = _0___v1
		var _out0 _dafny.Sequence
		_ = _out0
		_out0 = (_this.Aggregator).Flush()
		_0___v1 = _out0
		(_this.Aggregator).Stop()
		var _1_t *NullTransport
		_ = _1_t
		var _nw0 *NullTransport = New_NullTransport_()
		_ = _nw0
		_nw0.Ctor__()
		_1_t = _nw0
		(_this.Sender).Stop(_1_t)
		(_this).State = Companion_ClientState_.Create_Closed_()
		r = m__Errors.Companion_Result_.Create_Ok_(m_Buffer.Companion_Unit_.Create_Unit_())
		return r
	}
}
func (_this *Client) IsClosed() bool {
	{
		return (_this.State).Equals(Companion_ClientState_.Create_Closed_())
	}
}

// End of class Client
