// Package Aggregator
// Dafny module Aggregator compiled into Go

package Aggregator

import (
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
	return "Aggregator.Default__"
}
func (_this *Default__) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Default__{}

func (_static *CompanionStruct_Default___) FNV1aStep(h uint32, c _dafny.CodePoint) uint32 {
	var _0_b uint32 = ((_dafny.IntOfInt32(rune(c))).Modulo(_dafny.IntOfInt64(256))).Uint32()
	_ = _0_b
	return ((h) ^ (_0_b)) * (Companion_Default___.FNV__PRIME__32())
}
func (_static *CompanionStruct_Default___) FNV1aStringAcc(s _dafny.Sequence, h uint32) uint32 {
	goto TAIL_CALL_START
TAIL_CALL_START:
	if (_dafny.IntOfUint32((s).Cardinality())).Sign() == 0 {
		return h
	} else {
		var _in0 _dafny.Sequence = (s).Drop(1)
		_ = _in0
		var _in1 uint32 = Companion_Default___.FNV1aStep(h, (s).Select(0).(_dafny.CodePoint))
		_ = _in1
		s = _in0
		h = _in1
		goto TAIL_CALL_START
	}
}
func (_static *CompanionStruct_Default___) FNV1aTagsAcc(tags _dafny.Sequence, h uint32) uint32 {
	goto TAIL_CALL_START
TAIL_CALL_START:
	if (_dafny.IntOfUint32((tags).Cardinality())).Sign() == 0 {
		return h
	} else {
		var _in0 _dafny.Sequence = (tags).Drop(1)
		_ = _in0
		var _in1 uint32 = Companion_Default___.FNV1aStringAcc((tags).Select(0).(_dafny.Sequence), h)
		_ = _in1
		tags = _in0
		h = _in1
		goto TAIL_CALL_START
	}
}
func (_static *CompanionStruct_Default___) ContextHash(ctx m_Types.MetricContext) uint32 {
	return Companion_Default___.FNV1aTagsAcc((ctx).Dtor_tags(), Companion_Default___.FNV1aStringAcc((ctx).Dtor_name(), Companion_Default___.FNV__OFFSET__32()))
}
func (_static *CompanionStruct_Default___) ShardIndex(ctx m_Types.MetricContext, shardCount _dafny.Int) _dafny.Int {
	return (_dafny.IntOfUint32(Companion_Default___.ContextHash(ctx))).Modulo(shardCount)
}
func (_static *CompanionStruct_Default___) AllType(metrics _dafny.Sequence, t m_Types.MetricType) bool {
	return _dafny.Quantifier(_dafny.IntegerRange(_dafny.Zero, _dafny.IntOfUint32((metrics).Cardinality())), true, func(_forall_var_0 _dafny.Int) bool {
		var _0_k _dafny.Int
		_0_k = interface{}(_forall_var_0).(_dafny.Int)
		return !(((_0_k).Sign() != -1) && ((_0_k).Cmp(_dafny.IntOfUint32((metrics).Cardinality())) < 0)) || ((((metrics).Select((_0_k).Uint32()).(m_WireFormat.WireMetric)).Dtor_metricType()).Equals(t))
	})
}
func (_static *CompanionStruct_Default___) UniqueWireMetrics(metrics _dafny.Sequence) bool {
	return _dafny.Quantifier(_dafny.IntegerRange(_dafny.Zero, _dafny.IntOfUint32((metrics).Cardinality())), true, func(_forall_var_0 _dafny.Int) bool {
		var _0_i _dafny.Int
		_0_i = interface{}(_forall_var_0).(_dafny.Int)
		return _dafny.Quantifier(_dafny.IntegerRange((_0_i).Plus(_dafny.One), _dafny.IntOfUint32((metrics).Cardinality())), true, func(_forall_var_1 _dafny.Int) bool {
			var _1_j _dafny.Int
			_1_j = interface{}(_forall_var_1).(_dafny.Int)
			return !((((_0_i).Sign() != -1) && ((_0_i).Cmp(_1_j) < 0)) && ((_1_j).Cmp(_dafny.IntOfUint32((metrics).Cardinality())) < 0)) || (!(((_dafny.Companion_Sequence_.Equal(((metrics).Select((_0_i).Uint32()).(m_WireFormat.WireMetric)).Dtor_name(), ((metrics).Select((_1_j).Uint32()).(m_WireFormat.WireMetric)).Dtor_name())) && (_dafny.Companion_Sequence_.Equal(((metrics).Select((_0_i).Uint32()).(m_WireFormat.WireMetric)).Dtor_tags(), ((metrics).Select((_1_j).Uint32()).(m_WireFormat.WireMetric)).Dtor_tags()))) && ((((metrics).Select((_0_i).Uint32()).(m_WireFormat.WireMetric)).Dtor_metricType()).Equals(((metrics).Select((_1_j).Uint32()).(m_WireFormat.WireMetric)).Dtor_metricType()))))
		})
	})
}
func (_static *CompanionStruct_Default___) IntToString(n _dafny.Int) _dafny.Sequence {
	return _dafny.UnicodeSeqOfUtf8Bytes("")
}
func (_static *CompanionStruct_Default___) RealToString(r _dafny.Real) _dafny.Sequence {
	return _dafny.UnicodeSeqOfUtf8Bytes("")
}
func (_static *CompanionStruct_Default___) PickContextFromSet(s _dafny.Set) m_Types.MetricContext {
	return m_Types.Companion_MetricContext_.Create_MetricContext_(_dafny.UnicodeSeqOfUtf8Bytes(""), _dafny.SeqOf())
}
func (_static *CompanionStruct_Default___) FNV__PRIME__32() uint32 {
	return uint32(16777619)
}
func (_static *CompanionStruct_Default___) FNV__OFFSET__32() uint32 {
	return uint32(2166136261)
}

// End of class Default__

// Definition of datatype AggregatorState
type AggregatorState struct {
	Data_AggregatorState_
}

func (_this AggregatorState) Get_() Data_AggregatorState_ {
	return _this.Data_AggregatorState_
}

type Data_AggregatorState_ interface {
	isAggregatorState()
}

type CompanionStruct_AggregatorState_ struct {
}

var Companion_AggregatorState_ = CompanionStruct_AggregatorState_{}

type AggregatorState_Running struct {
}

func (AggregatorState_Running) isAggregatorState() {}

func (CompanionStruct_AggregatorState_) Create_Running_() AggregatorState {
	return AggregatorState{AggregatorState_Running{}}
}

func (_this AggregatorState) Is_Running() bool {
	_, ok := _this.Get_().(AggregatorState_Running)
	return ok
}

type AggregatorState_Stopped struct {
}

func (AggregatorState_Stopped) isAggregatorState() {}

func (CompanionStruct_AggregatorState_) Create_Stopped_() AggregatorState {
	return AggregatorState{AggregatorState_Stopped{}}
}

func (_this AggregatorState) Is_Stopped() bool {
	_, ok := _this.Get_().(AggregatorState_Stopped)
	return ok
}

func (CompanionStruct_AggregatorState_) Default() AggregatorState {
	return Companion_AggregatorState_.Create_Running_()
}

func (_ CompanionStruct_AggregatorState_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_AggregatorState_.Create_Running_(), true
		case 1:
			return Companion_AggregatorState_.Create_Stopped_(), true
		default:
			return AggregatorState{}, false
		}
	}
}

func (_this AggregatorState) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case AggregatorState_Running:
		{
			return "Aggregator.AggregatorState.Running"
		}
	case AggregatorState_Stopped:
		{
			return "Aggregator.AggregatorState.Stopped"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this AggregatorState) Equals(other AggregatorState) bool {
	switch _this.Get_().(type) {
	case AggregatorState_Running:
		{
			_, ok := other.Get_().(AggregatorState_Running)
			return ok
		}
	case AggregatorState_Stopped:
		{
			_, ok := other.Get_().(AggregatorState_Stopped)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this AggregatorState) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(AggregatorState)
	return ok && _this.Equals(typed)
}

func Type_AggregatorState_() _dafny.TypeDescriptor {
	return type_AggregatorState_{}
}

type type_AggregatorState_ struct {
}

func (_this type_AggregatorState_) Default() interface{} {
	return Companion_AggregatorState_.Default()
}

func (_this type_AggregatorState_) String() string {
	return "Aggregator.AggregatorState"
}
func (_this AggregatorState) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = AggregatorState{}

// End of datatype AggregatorState

// Definition of datatype BufferedMetricState
type BufferedMetricState struct {
	Data_BufferedMetricState_
}

func (_this BufferedMetricState) Get_() Data_BufferedMetricState_ {
	return _this.Data_BufferedMetricState_
}

type Data_BufferedMetricState_ interface {
	isBufferedMetricState()
}

type CompanionStruct_BufferedMetricState_ struct {
}

var Companion_BufferedMetricState_ = CompanionStruct_BufferedMetricState_{}

type BufferedMetricState_BufferedMetricState struct {
	Samples      _dafny.Sequence
	TotalSamples _dafny.Int
}

func (BufferedMetricState_BufferedMetricState) isBufferedMetricState() {}

func (CompanionStruct_BufferedMetricState_) Create_BufferedMetricState_(Samples _dafny.Sequence, TotalSamples _dafny.Int) BufferedMetricState {
	return BufferedMetricState{BufferedMetricState_BufferedMetricState{Samples, TotalSamples}}
}

func (_this BufferedMetricState) Is_BufferedMetricState() bool {
	_, ok := _this.Get_().(BufferedMetricState_BufferedMetricState)
	return ok
}

func (CompanionStruct_BufferedMetricState_) Default() BufferedMetricState {
	return Companion_BufferedMetricState_.Create_BufferedMetricState_(_dafny.EmptySeq, _dafny.Zero)
}

func (_this BufferedMetricState) Dtor_samples() _dafny.Sequence {
	return _this.Get_().(BufferedMetricState_BufferedMetricState).Samples
}

func (_this BufferedMetricState) Dtor_totalSamples() _dafny.Int {
	return _this.Get_().(BufferedMetricState_BufferedMetricState).TotalSamples
}

func (_this BufferedMetricState) String() string {
	switch data := _this.Get_().(type) {
	case nil:
		return "null"
	case BufferedMetricState_BufferedMetricState:
		{
			return "Aggregator.BufferedMetricState.BufferedMetricState" + "(" + _dafny.String(data.Samples) + ", " + _dafny.String(data.TotalSamples) + ")"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this BufferedMetricState) Equals(other BufferedMetricState) bool {
	switch data1 := _this.Get_().(type) {
	case BufferedMetricState_BufferedMetricState:
		{
			data2, ok := other.Get_().(BufferedMetricState_BufferedMetricState)
			return ok && data1.Samples.Equals(data2.Samples) && data1.TotalSamples.Cmp(data2.TotalSamples) == 0
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this BufferedMetricState) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(BufferedMetricState)
	return ok && _this.Equals(typed)
}

func Type_BufferedMetricState_() _dafny.TypeDescriptor {
	return type_BufferedMetricState_{}
}

type type_BufferedMetricState_ struct {
}

func (_this type_BufferedMetricState_) Default() interface{} {
	return Companion_BufferedMetricState_.Default()
}

func (_this type_BufferedMetricState_) String() string {
	return "Aggregator.BufferedMetricState"
}
func (_this BufferedMetricState) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = BufferedMetricState{}

// End of datatype BufferedMetricState

// Definition of class Aggregator
type Aggregator struct {
	State       AggregatorState
	CountShards _dafny.Sequence
	GaugeShards _dafny.Sequence
	SetShards   _dafny.Sequence
	Buffered    _dafny.Map
	ShardCount  _dafny.Int
}

func New_Aggregator_() *Aggregator {
	_this := Aggregator{}

	_this.State = Companion_AggregatorState_.Default()
	_this.CountShards = _dafny.EmptySeq
	_this.GaugeShards = _dafny.EmptySeq
	_this.SetShards = _dafny.EmptySeq
	_this.Buffered = _dafny.EmptyMap
	_this.ShardCount = _dafny.Zero
	return &_this
}

type CompanionStruct_Aggregator_ struct {
}

var Companion_Aggregator_ = CompanionStruct_Aggregator_{}

func (_this *Aggregator) Equals(other *Aggregator) bool {
	return _this == other
}

func (_this *Aggregator) EqualsGeneric(x interface{}) bool {
	other, ok := x.(*Aggregator)
	return ok && _this.Equals(other)
}

func (*Aggregator) String() string {
	return "Aggregator.Aggregator"
}

func Type_Aggregator_() _dafny.TypeDescriptor {
	return type_Aggregator_{}
}

type type_Aggregator_ struct {
}

func (_this type_Aggregator_) Default() interface{} {
	return (*Aggregator)(nil)
}

func (_this type_Aggregator_) String() string {
	return "Aggregator.Aggregator"
}
func (_this *Aggregator) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Aggregator{}

func (_this *Aggregator) Valid() bool {
	{
		return ((((((((_this.ShardCount).Sign() == 1) && ((_dafny.IntOfUint32((_this.CountShards).Cardinality())).Cmp(_this.ShardCount) == 0)) && ((_dafny.IntOfUint32((_this.GaugeShards).Cardinality())).Cmp(_this.ShardCount) == 0)) && ((_dafny.IntOfUint32((_this.SetShards).Cardinality())).Cmp(_this.ShardCount) == 0)) && (_dafny.Quantifier(_dafny.IntegerRange(_dafny.Zero, _this.ShardCount), true, func(_forall_var_0 _dafny.Int) bool {
			var _0_s _dafny.Int
			_0_s = interface{}(_forall_var_0).(_dafny.Int)
			return !(((_0_s).Sign() != -1) && ((_0_s).Cmp(_this.ShardCount) < 0)) || (_dafny.Quantifier(((_this.CountShards).Select((_0_s).Uint32()).(_dafny.Map)).Keys().Elements(), true, func(_forall_var_1 m_Types.MetricContext) bool {
				var _1_ctx m_Types.MetricContext
				_1_ctx = interface{}(_forall_var_1).(m_Types.MetricContext)
				return !(((_this.CountShards).Select((_0_s).Uint32()).(_dafny.Map)).Contains(_1_ctx)) || ((((_this.CountShards).Select((_0_s).Uint32()).(_dafny.Map)).Get(_1_ctx).(_dafny.Int)).Sign() != -1)
			}))
		}))) && (_dafny.Quantifier(_dafny.IntegerRange(_dafny.Zero, _this.ShardCount), true, func(_forall_var_2 _dafny.Int) bool {
			var _2_s _dafny.Int
			_2_s = interface{}(_forall_var_2).(_dafny.Int)
			return !(((_2_s).Sign() != -1) && ((_2_s).Cmp(_this.ShardCount) < 0)) || (_dafny.Quantifier(((_this.CountShards).Select((_2_s).Uint32()).(_dafny.Map)).Keys().Elements(), true, func(_forall_var_3 m_Types.MetricContext) bool {
				var _3_ctx m_Types.MetricContext
				_3_ctx = interface{}(_forall_var_3).(m_Types.MetricContext)
				return !(((_this.CountShards).Select((_2_s).Uint32()).(_dafny.Map)).Contains(_3_ctx)) || ((Companion_Default___.ShardIndex(_3_ctx, _this.ShardCount)).Cmp(_2_s) == 0)
			}))
		}))) && (_dafny.Quantifier(_dafny.IntegerRange(_dafny.Zero, _this.ShardCount), true, func(_forall_var_4 _dafny.Int) bool {
			var _4_s _dafny.Int
			_4_s = interface{}(_forall_var_4).(_dafny.Int)
			return !(((_4_s).Sign() != -1) && ((_4_s).Cmp(_this.ShardCount) < 0)) || (_dafny.Quantifier(((_this.GaugeShards).Select((_4_s).Uint32()).(_dafny.Map)).Keys().Elements(), true, func(_forall_var_5 m_Types.MetricContext) bool {
				var _5_ctx m_Types.MetricContext
				_5_ctx = interface{}(_forall_var_5).(m_Types.MetricContext)
				return !(((_this.GaugeShards).Select((_4_s).Uint32()).(_dafny.Map)).Contains(_5_ctx)) || ((Companion_Default___.ShardIndex(_5_ctx, _this.ShardCount)).Cmp(_4_s) == 0)
			}))
		}))) && (_dafny.Quantifier(_dafny.IntegerRange(_dafny.Zero, _this.ShardCount), true, func(_forall_var_6 _dafny.Int) bool {
			var _6_s _dafny.Int
			_6_s = interface{}(_forall_var_6).(_dafny.Int)
			return !(((_6_s).Sign() != -1) && ((_6_s).Cmp(_this.ShardCount) < 0)) || (_dafny.Quantifier(((_this.SetShards).Select((_6_s).Uint32()).(_dafny.Map)).Keys().Elements(), true, func(_forall_var_7 m_Types.MetricContext) bool {
				var _7_ctx m_Types.MetricContext
				_7_ctx = interface{}(_forall_var_7).(m_Types.MetricContext)
				return !(((_this.SetShards).Select((_6_s).Uint32()).(_dafny.Map)).Contains(_7_ctx)) || ((Companion_Default___.ShardIndex(_7_ctx, _this.ShardCount)).Cmp(_6_s) == 0)
			}))
		}))
	}
}
func (_this *Aggregator) New(n _dafny.Int) {
	{
		(_this).State = Companion_AggregatorState_.Create_Running_()
		(_this).ShardCount = n
		(_this).CountShards = _dafny.SeqCreate((n).Uint32(), func(coer3 func(_dafny.Int) _dafny.Map) func(_dafny.Int) interface{} {
			return func(arg3 _dafny.Int) interface{} {
				return coer3(arg3)
			}
		}(func(_0___v0 _dafny.Int) _dafny.Map {
			return _dafny.NewMapBuilder().ToMap()
		}))
		(_this).GaugeShards = _dafny.SeqCreate((n).Uint32(), func(coer4 func(_dafny.Int) _dafny.Map) func(_dafny.Int) interface{} {
			return func(arg4 _dafny.Int) interface{} {
				return coer4(arg4)
			}
		}(func(_1___v1 _dafny.Int) _dafny.Map {
			return _dafny.NewMapBuilder().ToMap()
		}))
		(_this).SetShards = _dafny.SeqCreate((n).Uint32(), func(coer5 func(_dafny.Int) _dafny.Map) func(_dafny.Int) interface{} {
			return func(arg5 _dafny.Int) interface{} {
				return coer5(arg5)
			}
		}(func(_2___v2 _dafny.Int) _dafny.Map {
			return _dafny.NewMapBuilder().ToMap()
		}))
		(_this).Buffered = _dafny.NewMapBuilder().ToMap()
	}
}
func (_this *Aggregator) SampleCount(ctx m_Types.MetricContext, value _dafny.Int) {
	{
		var _0_s _dafny.Int
		_ = _0_s
		_0_s = Companion_Default___.ShardIndex(ctx, _this.ShardCount)
		var _1_prev _dafny.Int
		_ = _1_prev
		if ((_this.CountShards).Select((_0_s).Uint32()).(_dafny.Map)).Contains(ctx) {
			_1_prev = ((_this.CountShards).Select((_0_s).Uint32()).(_dafny.Map)).Get(ctx).(_dafny.Int)
		} else {
			_1_prev = _dafny.Zero
		}
		(_this).CountShards = _dafny.Companion_Sequence_.Update(_this.CountShards, (_0_s).Uint32(), ((_this.CountShards).Select((_0_s).Uint32()).(_dafny.Map)).Update(ctx, (_1_prev).Plus(value)))
	}
}
func (_this *Aggregator) SampleGauge(ctx m_Types.MetricContext, value _dafny.Real) {
	{
		var _0_s _dafny.Int
		_ = _0_s
		_0_s = Companion_Default___.ShardIndex(ctx, _this.ShardCount)
		(_this).GaugeShards = _dafny.Companion_Sequence_.Update(_this.GaugeShards, (_0_s).Uint32(), ((_this.GaugeShards).Select((_0_s).Uint32()).(_dafny.Map)).Update(ctx, value))
	}
}
func (_this *Aggregator) SampleSet(ctx m_Types.MetricContext, value _dafny.Sequence) {
	{
		var _0_s _dafny.Int
		_ = _0_s
		_0_s = Companion_Default___.ShardIndex(ctx, _this.ShardCount)
		var _1_oldSet _dafny.Set
		_ = _1_oldSet
		if ((_this.SetShards).Select((_0_s).Uint32()).(_dafny.Map)).Contains(ctx) {
			_1_oldSet = ((_this.SetShards).Select((_0_s).Uint32()).(_dafny.Map)).Get(ctx).(_dafny.Set)
		} else {
			_1_oldSet = _dafny.SetOf()
		}
		(_this).SetShards = _dafny.Companion_Sequence_.Update(_this.SetShards, (_0_s).Uint32(), ((_this.SetShards).Select((_0_s).Uint32()).(_dafny.Map)).Update(ctx, (_1_oldSet).Union(_dafny.SetOf(value))))
	}
}
func (_this *Aggregator) SampleBuffered(ctx m_Types.MetricContext, value _dafny.Real, maxSamples _dafny.Int) {
	{
		var _0_oldState BufferedMetricState
		_ = _0_oldState
		if (_this.Buffered).Contains(ctx) {
			_0_oldState = (_this.Buffered).Get(ctx).(BufferedMetricState)
		} else {
			_0_oldState = Companion_BufferedMetricState_.Create_BufferedMetricState_(_dafny.SeqOf(), _dafny.Zero)
		}
		var _1_newSamples _dafny.Sequence
		_ = _1_newSamples
		if ((maxSamples).Sign() == 1) && ((_dafny.IntOfUint32(((_0_oldState).Dtor_samples()).Cardinality())).Cmp(maxSamples) < 0) {
			_1_newSamples = _dafny.Companion_Sequence_.Concatenate((_0_oldState).Dtor_samples(), _dafny.SeqOf(value))
		} else {
			_1_newSamples = (_0_oldState).Dtor_samples()
		}
		(_this).Buffered = (_this.Buffered).Update(ctx, Companion_BufferedMetricState_.Create_BufferedMetricState_(_1_newSamples, ((_0_oldState).Dtor_totalSamples()).Plus(_dafny.One)))
	}
}
func (_this *Aggregator) Flush() _dafny.Sequence {
	{
		var result _dafny.Sequence = _dafny.EmptySeq
		_ = result
		var _0_countResult _dafny.Sequence
		_ = _0_countResult
		var _out0 _dafny.Sequence
		_ = _out0
		_out0 = (_this).CollectCountMetrics()
		_0_countResult = _out0
		var _1_gaugeResult _dafny.Sequence
		_ = _1_gaugeResult
		var _out1 _dafny.Sequence
		_ = _out1
		_out1 = (_this).CollectGaugeMetrics()
		_1_gaugeResult = _out1
		var _2_setResult _dafny.Sequence
		_ = _2_setResult
		var _out2 _dafny.Sequence
		_ = _out2
		_out2 = (_this).CollectSetMetrics()
		_2_setResult = _out2
		var _3_bufferedResult _dafny.Sequence
		_ = _3_bufferedResult
		var _out3 _dafny.Sequence
		_ = _out3
		_out3 = (_this).CollectBufferedMetrics()
		_3_bufferedResult = _out3
		(_this).CountShards = _dafny.SeqCreate((_this.ShardCount).Uint32(), func(coer6 func(_dafny.Int) _dafny.Map) func(_dafny.Int) interface{} {
			return func(arg6 _dafny.Int) interface{} {
				return coer6(arg6)
			}
		}(func(_4___v3 _dafny.Int) _dafny.Map {
			return _dafny.NewMapBuilder().ToMap()
		}))
		(_this).GaugeShards = _dafny.SeqCreate((_this.ShardCount).Uint32(), func(coer7 func(_dafny.Int) _dafny.Map) func(_dafny.Int) interface{} {
			return func(arg7 _dafny.Int) interface{} {
				return coer7(arg7)
			}
		}(func(_5___v4 _dafny.Int) _dafny.Map {
			return _dafny.NewMapBuilder().ToMap()
		}))
		(_this).SetShards = _dafny.SeqCreate((_this.ShardCount).Uint32(), func(coer8 func(_dafny.Int) _dafny.Map) func(_dafny.Int) interface{} {
			return func(arg8 _dafny.Int) interface{} {
				return coer8(arg8)
			}
		}(func(_6___v5 _dafny.Int) _dafny.Map {
			return _dafny.NewMapBuilder().ToMap()
		}))
		(_this).Buffered = _dafny.NewMapBuilder().ToMap()
		var _7_cg _dafny.Sequence
		_ = _7_cg
		_7_cg = _dafny.Companion_Sequence_.Concatenate(_0_countResult, _1_gaugeResult)
		var _8_cgs _dafny.Sequence
		_ = _8_cgs
		_8_cgs = _dafny.Companion_Sequence_.Concatenate(_7_cg, _2_setResult)
		result = _dafny.Companion_Sequence_.Concatenate(_8_cgs, _3_bufferedResult)
		return result
	}
}
func (_this *Aggregator) CollectCountMetrics() _dafny.Sequence {
	{
		var r _dafny.Sequence = _dafny.EmptySeq
		_ = r
		r = _dafny.SeqOf()
		var _0_si _dafny.Int
		_ = _0_si
		_0_si = _dafny.Zero
		for (_0_si).Cmp(_this.ShardCount) < 0 {
			var _1_shard _dafny.Map
			_ = _1_shard
			_1_shard = (_this.CountShards).Select((_0_si).Uint32()).(_dafny.Map)
			var _2_remaining _dafny.Set
			_ = _2_remaining
			_2_remaining = (_1_shard).Keys()
			for !(_2_remaining).Equals(_dafny.SetOf()) {
				var _3_ctx m_Types.MetricContext
				_ = _3_ctx
				_3_ctx = Companion_Default___.PickContextFromSet(_2_remaining)
				var _4_v _dafny.Int
				_ = _4_v
				_4_v = (_1_shard).Get(_3_ctx).(_dafny.Int)
				if (_4_v).Sign() != 0 {
					var _5_m m_WireFormat.WireMetric
					_ = _5_m
					_5_m = m_WireFormat.Companion_WireMetric_.Create_WireMetric_((_3_ctx).Dtor_name(), Companion_Default___.IntToString(_4_v), m_Types.Companion_MetricType_.Create_Count_(), m_Types.Companion_Option_.Create_None_(), (_3_ctx).Dtor_tags(), m_Types.Companion_Option_.Create_None_(), m_Types.Companion_Option_.Create_None_(), m_Types.Companion_TagCardinality_.Create_CardinalityNotSet_())
					r = _dafny.Companion_Sequence_.Concatenate(r, _dafny.SeqOf(_5_m))
				}
				_2_remaining = (_2_remaining).Difference(_dafny.SetOf(_3_ctx))
			}
			_0_si = (_0_si).Plus(_dafny.One)
		}
		return r
	}
}
func (_this *Aggregator) CollectGaugeMetrics() _dafny.Sequence {
	{
		var r _dafny.Sequence = _dafny.EmptySeq
		_ = r
		r = _dafny.SeqOf()
		var _0_si _dafny.Int
		_ = _0_si
		_0_si = _dafny.Zero
		for (_0_si).Cmp(_this.ShardCount) < 0 {
			var _1_shard _dafny.Map
			_ = _1_shard
			_1_shard = (_this.GaugeShards).Select((_0_si).Uint32()).(_dafny.Map)
			var _2_remaining _dafny.Set
			_ = _2_remaining
			_2_remaining = (_1_shard).Keys()
			for !(_2_remaining).Equals(_dafny.SetOf()) {
				var _3_ctx m_Types.MetricContext
				_ = _3_ctx
				_3_ctx = Companion_Default___.PickContextFromSet(_2_remaining)
				var _4_v _dafny.Real
				_ = _4_v
				_4_v = (_1_shard).Get(_3_ctx).(_dafny.Real)
				var _5_m m_WireFormat.WireMetric
				_ = _5_m
				_5_m = m_WireFormat.Companion_WireMetric_.Create_WireMetric_((_3_ctx).Dtor_name(), Companion_Default___.RealToString(_4_v), m_Types.Companion_MetricType_.Create_Gauge_(), m_Types.Companion_Option_.Create_None_(), (_3_ctx).Dtor_tags(), m_Types.Companion_Option_.Create_None_(), m_Types.Companion_Option_.Create_None_(), m_Types.Companion_TagCardinality_.Create_CardinalityNotSet_())
				r = _dafny.Companion_Sequence_.Concatenate(r, _dafny.SeqOf(_5_m))
				_2_remaining = (_2_remaining).Difference(_dafny.SetOf(_3_ctx))
			}
			_0_si = (_0_si).Plus(_dafny.One)
		}
		return r
	}
}
func (_this *Aggregator) CollectSetMetrics() _dafny.Sequence {
	{
		var r _dafny.Sequence = _dafny.EmptySeq
		_ = r
		r = _dafny.SeqOf()
		var _0_si _dafny.Int
		_ = _0_si
		_0_si = _dafny.Zero
		for (_0_si).Cmp(_this.ShardCount) < 0 {
			var _1_shard _dafny.Map
			_ = _1_shard
			_1_shard = (_this.SetShards).Select((_0_si).Uint32()).(_dafny.Map)
			var _2_remaining _dafny.Set
			_ = _2_remaining
			_2_remaining = (_1_shard).Keys()
			for !(_2_remaining).Equals(_dafny.SetOf()) {
				var _3_ctx m_Types.MetricContext
				_ = _3_ctx
				_3_ctx = Companion_Default___.PickContextFromSet(_2_remaining)
				var _4_v _dafny.Set
				_ = _4_v
				_4_v = (_1_shard).Get(_3_ctx).(_dafny.Set)
				if !(_4_v).Equals(_dafny.SetOf()) {
					var _5_m m_WireFormat.WireMetric
					_ = _5_m
					_5_m = m_WireFormat.Companion_WireMetric_.Create_WireMetric_((_3_ctx).Dtor_name(), Companion_Default___.IntToString((_4_v).Cardinality()), m_Types.Companion_MetricType_.Create_Set_(), m_Types.Companion_Option_.Create_None_(), (_3_ctx).Dtor_tags(), m_Types.Companion_Option_.Create_None_(), m_Types.Companion_Option_.Create_None_(), m_Types.Companion_TagCardinality_.Create_CardinalityNotSet_())
					r = _dafny.Companion_Sequence_.Concatenate(r, _dafny.SeqOf(_5_m))
				}
				_2_remaining = (_2_remaining).Difference(_dafny.SetOf(_3_ctx))
			}
			_0_si = (_0_si).Plus(_dafny.One)
		}
		return r
	}
}
func (_this *Aggregator) CollectBufferedMetrics() _dafny.Sequence {
	{
		var r _dafny.Sequence = _dafny.EmptySeq
		_ = r
		r = _dafny.SeqOf()
		var _0_remaining _dafny.Set
		_ = _0_remaining
		_0_remaining = (_this.Buffered).Keys()
		for !(_0_remaining).Equals(_dafny.SetOf()) {
			var _1_ctx m_Types.MetricContext
			_ = _1_ctx
			_1_ctx = Companion_Default___.PickContextFromSet(_0_remaining)
			var _2_bs BufferedMetricState
			_ = _2_bs
			_2_bs = (_this.Buffered).Get(_1_ctx).(BufferedMetricState)
			var _3_cnt _dafny.Int
			_ = _3_cnt
			_3_cnt = (_2_bs).Dtor_totalSamples()
			var _4_m m_WireFormat.WireMetric
			_ = _4_m
			_4_m = m_WireFormat.Companion_WireMetric_.Create_WireMetric_((_1_ctx).Dtor_name(), Companion_Default___.IntToString(_3_cnt), m_Types.Companion_MetricType_.Create_Histogram_(), m_Types.Companion_Option_.Create_None_(), (_1_ctx).Dtor_tags(), m_Types.Companion_Option_.Create_None_(), m_Types.Companion_Option_.Create_None_(), m_Types.Companion_TagCardinality_.Create_CardinalityNotSet_())
			r = _dafny.Companion_Sequence_.Concatenate(r, _dafny.SeqOf(_4_m))
			_0_remaining = (_0_remaining).Difference(_dafny.SetOf(_1_ctx))
		}
		return r
	}
}
func (_this *Aggregator) Stop() {
	{
		(_this).State = Companion_AggregatorState_.Create_Stopped_()
	}
}

// End of class Aggregator
