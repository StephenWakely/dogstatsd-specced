// Package Types
// Dafny module Types compiled into Go

package Types

import (
	m__System "System_"
	_dafny "dafny"
	os "os"
)

var _ = os.Args
var _ _dafny.Dummy__
var _ m__System.Dummy__

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
	return "Types.Default__"
}
func (_this *Default__) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = &Default__{}

func (_static *CompanionStruct_Default___) MetricTypeSymbol(t MetricType) _dafny.Sequence {
	var _source0 MetricType = t
	_ = _source0
	{
		if _source0.Is_Gauge() {
			return _dafny.UnicodeSeqOfUtf8Bytes("g")
		}
	}
	{
		if _source0.Is_Count() {
			return _dafny.UnicodeSeqOfUtf8Bytes("c")
		}
	}
	{
		if _source0.Is_Histogram() {
			return _dafny.UnicodeSeqOfUtf8Bytes("h")
		}
	}
	{
		if _source0.Is_Distribution() {
			return _dafny.UnicodeSeqOfUtf8Bytes("d")
		}
	}
	{
		if _source0.Is_Set() {
			return _dafny.UnicodeSeqOfUtf8Bytes("s")
		}
	}
	{
		return _dafny.UnicodeSeqOfUtf8Bytes("ms")
	}
}
func (_static *CompanionStruct_Default___) CardinalityString(c TagCardinality) Option {
	var _source0 TagCardinality = c
	_ = _source0
	{
		if _source0.Is_CardinalityNotSet() {
			return Companion_Option_.Create_None_()
		}
	}
	{
		if _source0.Is_CardinalityNone() {
			return Companion_Option_.Create_Some_(_dafny.UnicodeSeqOfUtf8Bytes("none"))
		}
	}
	{
		if _source0.Is_CardinalityLow() {
			return Companion_Option_.Create_Some_(_dafny.UnicodeSeqOfUtf8Bytes("low"))
		}
	}
	{
		if _source0.Is_CardinalityOrchestrator() {
			return Companion_Option_.Create_Some_(_dafny.UnicodeSeqOfUtf8Bytes("orchestrator"))
		}
	}
	{
		return Companion_Option_.Create_Some_(_dafny.UnicodeSeqOfUtf8Bytes("high"))
	}
}
func (_static *CompanionStruct_Default___) DefaultConfig() DogStatsDConfig {
	return Companion_DogStatsDConfig_.Create_DogStatsDConfig_(Companion_Default___.UDP__MAX__BYTES(), Companion_Default___.DEFAULT__BUFFER__FLUSH__INTERVAL__MS(), Companion_Default___.DEFAULT__AGGREGATION__FLUSH__INTERVAL__MS(), Companion_Default___.DEFAULT__SENDER__QUEUE__SIZE(), Companion_Default___.DEFAULT__BUFFER__POOL__CAPACITY(), true, false, _dafny.IntOfInt64(-1), true, Companion_TagCardinality_.Create_CardinalityNotSet_())
}
func (_static *CompanionStruct_Default___) UDP__MAX__BYTES() _dafny.Int {
	return _dafny.IntOfInt64(1432)
}
func (_static *CompanionStruct_Default___) DEFAULT__BUFFER__FLUSH__INTERVAL__MS() _dafny.Int {
	return _dafny.IntOfInt64(100)
}
func (_static *CompanionStruct_Default___) DEFAULT__AGGREGATION__FLUSH__INTERVAL__MS() _dafny.Int {
	return _dafny.IntOfInt64(2000)
}
func (_static *CompanionStruct_Default___) DEFAULT__SENDER__QUEUE__SIZE() _dafny.Int {
	return _dafny.IntOfInt64(512)
}
func (_static *CompanionStruct_Default___) DEFAULT__BUFFER__POOL__CAPACITY() _dafny.Int {
	return _dafny.IntOfInt64(2048)
}
func (_static *CompanionStruct_Default___) UDS__MAX__BYTES() _dafny.Int {
	return _dafny.IntOfInt64(8192)
}

// End of class Default__

// Definition of datatype Option
type Option struct {
	Data_Option_
}

func (_this Option) Get_() Data_Option_ {
	return _this.Data_Option_
}

type Data_Option_ interface {
	isOption()
}

type CompanionStruct_Option_ struct {
}

var Companion_Option_ = CompanionStruct_Option_{}

type Option_None struct {
}

func (Option_None) isOption() {}

func (CompanionStruct_Option_) Create_None_() Option {
	return Option{Option_None{}}
}

func (_this Option) Is_None() bool {
	_, ok := _this.Get_().(Option_None)
	return ok
}

type Option_Some struct {
	Value interface{}
}

func (Option_Some) isOption() {}

func (CompanionStruct_Option_) Create_Some_(Value interface{}) Option {
	return Option{Option_Some{Value}}
}

func (_this Option) Is_Some() bool {
	_, ok := _this.Get_().(Option_Some)
	return ok
}

func (CompanionStruct_Option_) Default() Option {
	return Companion_Option_.Create_None_()
}

func (_this Option) Dtor_value() interface{} {
	return _this.Get_().(Option_Some).Value
}

func (_this Option) String() string {
	switch data := _this.Get_().(type) {
	case nil:
		return "null"
	case Option_None:
		{
			return "Types.Option.None"
		}
	case Option_Some:
		{
			return "Types.Option.Some" + "(" + _dafny.String(data.Value) + ")"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this Option) Equals(other Option) bool {
	switch data1 := _this.Get_().(type) {
	case Option_None:
		{
			_, ok := other.Get_().(Option_None)
			return ok
		}
	case Option_Some:
		{
			data2, ok := other.Get_().(Option_Some)
			return ok && _dafny.AreEqual(data1.Value, data2.Value)
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this Option) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(Option)
	return ok && _this.Equals(typed)
}

func Type_Option_() _dafny.TypeDescriptor {
	return type_Option_{}
}

type type_Option_ struct {
}

func (_this type_Option_) Default() interface{} {
	return Companion_Option_.Default()
}

func (_this type_Option_) String() string {
	return "Types.Option"
}
func (_this Option) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = Option{}

// End of datatype Option

// Definition of datatype MetricType
type MetricType struct {
	Data_MetricType_
}

func (_this MetricType) Get_() Data_MetricType_ {
	return _this.Data_MetricType_
}

type Data_MetricType_ interface {
	isMetricType()
}

type CompanionStruct_MetricType_ struct {
}

var Companion_MetricType_ = CompanionStruct_MetricType_{}

type MetricType_Gauge struct {
}

func (MetricType_Gauge) isMetricType() {}

func (CompanionStruct_MetricType_) Create_Gauge_() MetricType {
	return MetricType{MetricType_Gauge{}}
}

func (_this MetricType) Is_Gauge() bool {
	_, ok := _this.Get_().(MetricType_Gauge)
	return ok
}

type MetricType_Count struct {
}

func (MetricType_Count) isMetricType() {}

func (CompanionStruct_MetricType_) Create_Count_() MetricType {
	return MetricType{MetricType_Count{}}
}

func (_this MetricType) Is_Count() bool {
	_, ok := _this.Get_().(MetricType_Count)
	return ok
}

type MetricType_Histogram struct {
}

func (MetricType_Histogram) isMetricType() {}

func (CompanionStruct_MetricType_) Create_Histogram_() MetricType {
	return MetricType{MetricType_Histogram{}}
}

func (_this MetricType) Is_Histogram() bool {
	_, ok := _this.Get_().(MetricType_Histogram)
	return ok
}

type MetricType_Distribution struct {
}

func (MetricType_Distribution) isMetricType() {}

func (CompanionStruct_MetricType_) Create_Distribution_() MetricType {
	return MetricType{MetricType_Distribution{}}
}

func (_this MetricType) Is_Distribution() bool {
	_, ok := _this.Get_().(MetricType_Distribution)
	return ok
}

type MetricType_Set struct {
}

func (MetricType_Set) isMetricType() {}

func (CompanionStruct_MetricType_) Create_Set_() MetricType {
	return MetricType{MetricType_Set{}}
}

func (_this MetricType) Is_Set() bool {
	_, ok := _this.Get_().(MetricType_Set)
	return ok
}

type MetricType_Timing struct {
}

func (MetricType_Timing) isMetricType() {}

func (CompanionStruct_MetricType_) Create_Timing_() MetricType {
	return MetricType{MetricType_Timing{}}
}

func (_this MetricType) Is_Timing() bool {
	_, ok := _this.Get_().(MetricType_Timing)
	return ok
}

func (CompanionStruct_MetricType_) Default() MetricType {
	return Companion_MetricType_.Create_Gauge_()
}

func (_ CompanionStruct_MetricType_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_MetricType_.Create_Gauge_(), true
		case 1:
			return Companion_MetricType_.Create_Count_(), true
		case 2:
			return Companion_MetricType_.Create_Histogram_(), true
		case 3:
			return Companion_MetricType_.Create_Distribution_(), true
		case 4:
			return Companion_MetricType_.Create_Set_(), true
		case 5:
			return Companion_MetricType_.Create_Timing_(), true
		default:
			return MetricType{}, false
		}
	}
}

func (_this MetricType) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case MetricType_Gauge:
		{
			return "Types.MetricType.Gauge"
		}
	case MetricType_Count:
		{
			return "Types.MetricType.Count"
		}
	case MetricType_Histogram:
		{
			return "Types.MetricType.Histogram"
		}
	case MetricType_Distribution:
		{
			return "Types.MetricType.Distribution"
		}
	case MetricType_Set:
		{
			return "Types.MetricType.Set"
		}
	case MetricType_Timing:
		{
			return "Types.MetricType.Timing"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this MetricType) Equals(other MetricType) bool {
	switch _this.Get_().(type) {
	case MetricType_Gauge:
		{
			_, ok := other.Get_().(MetricType_Gauge)
			return ok
		}
	case MetricType_Count:
		{
			_, ok := other.Get_().(MetricType_Count)
			return ok
		}
	case MetricType_Histogram:
		{
			_, ok := other.Get_().(MetricType_Histogram)
			return ok
		}
	case MetricType_Distribution:
		{
			_, ok := other.Get_().(MetricType_Distribution)
			return ok
		}
	case MetricType_Set:
		{
			_, ok := other.Get_().(MetricType_Set)
			return ok
		}
	case MetricType_Timing:
		{
			_, ok := other.Get_().(MetricType_Timing)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this MetricType) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(MetricType)
	return ok && _this.Equals(typed)
}

func Type_MetricType_() _dafny.TypeDescriptor {
	return type_MetricType_{}
}

type type_MetricType_ struct {
}

func (_this type_MetricType_) Default() interface{} {
	return Companion_MetricType_.Default()
}

func (_this type_MetricType_) String() string {
	return "Types.MetricType"
}
func (_this MetricType) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = MetricType{}

// End of datatype MetricType

// Definition of datatype TransportMode
type TransportMode struct {
	Data_TransportMode_
}

func (_this TransportMode) Get_() Data_TransportMode_ {
	return _this.Data_TransportMode_
}

type Data_TransportMode_ interface {
	isTransportMode()
}

type CompanionStruct_TransportMode_ struct {
}

var Companion_TransportMode_ = CompanionStruct_TransportMode_{}

type TransportMode_UDP struct {
}

func (TransportMode_UDP) isTransportMode() {}

func (CompanionStruct_TransportMode_) Create_UDP_() TransportMode {
	return TransportMode{TransportMode_UDP{}}
}

func (_this TransportMode) Is_UDP() bool {
	_, ok := _this.Get_().(TransportMode_UDP)
	return ok
}

type TransportMode_UDS struct {
}

func (TransportMode_UDS) isTransportMode() {}

func (CompanionStruct_TransportMode_) Create_UDS_() TransportMode {
	return TransportMode{TransportMode_UDS{}}
}

func (_this TransportMode) Is_UDS() bool {
	_, ok := _this.Get_().(TransportMode_UDS)
	return ok
}

type TransportMode_Pipe struct {
}

func (TransportMode_Pipe) isTransportMode() {}

func (CompanionStruct_TransportMode_) Create_Pipe_() TransportMode {
	return TransportMode{TransportMode_Pipe{}}
}

func (_this TransportMode) Is_Pipe() bool {
	_, ok := _this.Get_().(TransportMode_Pipe)
	return ok
}

func (CompanionStruct_TransportMode_) Default() TransportMode {
	return Companion_TransportMode_.Create_UDP_()
}

func (_ CompanionStruct_TransportMode_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_TransportMode_.Create_UDP_(), true
		case 1:
			return Companion_TransportMode_.Create_UDS_(), true
		case 2:
			return Companion_TransportMode_.Create_Pipe_(), true
		default:
			return TransportMode{}, false
		}
	}
}

func (_this TransportMode) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case TransportMode_UDP:
		{
			return "Types.TransportMode.UDP"
		}
	case TransportMode_UDS:
		{
			return "Types.TransportMode.UDS"
		}
	case TransportMode_Pipe:
		{
			return "Types.TransportMode.Pipe"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this TransportMode) Equals(other TransportMode) bool {
	switch _this.Get_().(type) {
	case TransportMode_UDP:
		{
			_, ok := other.Get_().(TransportMode_UDP)
			return ok
		}
	case TransportMode_UDS:
		{
			_, ok := other.Get_().(TransportMode_UDS)
			return ok
		}
	case TransportMode_Pipe:
		{
			_, ok := other.Get_().(TransportMode_Pipe)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this TransportMode) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(TransportMode)
	return ok && _this.Equals(typed)
}

func Type_TransportMode_() _dafny.TypeDescriptor {
	return type_TransportMode_{}
}

type type_TransportMode_ struct {
}

func (_this type_TransportMode_) Default() interface{} {
	return Companion_TransportMode_.Default()
}

func (_this type_TransportMode_) String() string {
	return "Types.TransportMode"
}
func (_this TransportMode) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = TransportMode{}

// End of datatype TransportMode

// Definition of datatype TagCardinality
type TagCardinality struct {
	Data_TagCardinality_
}

func (_this TagCardinality) Get_() Data_TagCardinality_ {
	return _this.Data_TagCardinality_
}

type Data_TagCardinality_ interface {
	isTagCardinality()
}

type CompanionStruct_TagCardinality_ struct {
}

var Companion_TagCardinality_ = CompanionStruct_TagCardinality_{}

type TagCardinality_CardinalityNotSet struct {
}

func (TagCardinality_CardinalityNotSet) isTagCardinality() {}

func (CompanionStruct_TagCardinality_) Create_CardinalityNotSet_() TagCardinality {
	return TagCardinality{TagCardinality_CardinalityNotSet{}}
}

func (_this TagCardinality) Is_CardinalityNotSet() bool {
	_, ok := _this.Get_().(TagCardinality_CardinalityNotSet)
	return ok
}

type TagCardinality_CardinalityNone struct {
}

func (TagCardinality_CardinalityNone) isTagCardinality() {}

func (CompanionStruct_TagCardinality_) Create_CardinalityNone_() TagCardinality {
	return TagCardinality{TagCardinality_CardinalityNone{}}
}

func (_this TagCardinality) Is_CardinalityNone() bool {
	_, ok := _this.Get_().(TagCardinality_CardinalityNone)
	return ok
}

type TagCardinality_CardinalityLow struct {
}

func (TagCardinality_CardinalityLow) isTagCardinality() {}

func (CompanionStruct_TagCardinality_) Create_CardinalityLow_() TagCardinality {
	return TagCardinality{TagCardinality_CardinalityLow{}}
}

func (_this TagCardinality) Is_CardinalityLow() bool {
	_, ok := _this.Get_().(TagCardinality_CardinalityLow)
	return ok
}

type TagCardinality_CardinalityOrchestrator struct {
}

func (TagCardinality_CardinalityOrchestrator) isTagCardinality() {}

func (CompanionStruct_TagCardinality_) Create_CardinalityOrchestrator_() TagCardinality {
	return TagCardinality{TagCardinality_CardinalityOrchestrator{}}
}

func (_this TagCardinality) Is_CardinalityOrchestrator() bool {
	_, ok := _this.Get_().(TagCardinality_CardinalityOrchestrator)
	return ok
}

type TagCardinality_CardinalityHigh struct {
}

func (TagCardinality_CardinalityHigh) isTagCardinality() {}

func (CompanionStruct_TagCardinality_) Create_CardinalityHigh_() TagCardinality {
	return TagCardinality{TagCardinality_CardinalityHigh{}}
}

func (_this TagCardinality) Is_CardinalityHigh() bool {
	_, ok := _this.Get_().(TagCardinality_CardinalityHigh)
	return ok
}

func (CompanionStruct_TagCardinality_) Default() TagCardinality {
	return Companion_TagCardinality_.Create_CardinalityNotSet_()
}

func (_ CompanionStruct_TagCardinality_) AllSingletonConstructors() _dafny.Iterator {
	i := -1
	return func() (interface{}, bool) {
		i++
		switch i {
		case 0:
			return Companion_TagCardinality_.Create_CardinalityNotSet_(), true
		case 1:
			return Companion_TagCardinality_.Create_CardinalityNone_(), true
		case 2:
			return Companion_TagCardinality_.Create_CardinalityLow_(), true
		case 3:
			return Companion_TagCardinality_.Create_CardinalityOrchestrator_(), true
		case 4:
			return Companion_TagCardinality_.Create_CardinalityHigh_(), true
		default:
			return TagCardinality{}, false
		}
	}
}

func (_this TagCardinality) String() string {
	switch _this.Get_().(type) {
	case nil:
		return "null"
	case TagCardinality_CardinalityNotSet:
		{
			return "Types.TagCardinality.CardinalityNotSet"
		}
	case TagCardinality_CardinalityNone:
		{
			return "Types.TagCardinality.CardinalityNone"
		}
	case TagCardinality_CardinalityLow:
		{
			return "Types.TagCardinality.CardinalityLow"
		}
	case TagCardinality_CardinalityOrchestrator:
		{
			return "Types.TagCardinality.CardinalityOrchestrator"
		}
	case TagCardinality_CardinalityHigh:
		{
			return "Types.TagCardinality.CardinalityHigh"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this TagCardinality) Equals(other TagCardinality) bool {
	switch _this.Get_().(type) {
	case TagCardinality_CardinalityNotSet:
		{
			_, ok := other.Get_().(TagCardinality_CardinalityNotSet)
			return ok
		}
	case TagCardinality_CardinalityNone:
		{
			_, ok := other.Get_().(TagCardinality_CardinalityNone)
			return ok
		}
	case TagCardinality_CardinalityLow:
		{
			_, ok := other.Get_().(TagCardinality_CardinalityLow)
			return ok
		}
	case TagCardinality_CardinalityOrchestrator:
		{
			_, ok := other.Get_().(TagCardinality_CardinalityOrchestrator)
			return ok
		}
	case TagCardinality_CardinalityHigh:
		{
			_, ok := other.Get_().(TagCardinality_CardinalityHigh)
			return ok
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this TagCardinality) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(TagCardinality)
	return ok && _this.Equals(typed)
}

func Type_TagCardinality_() _dafny.TypeDescriptor {
	return type_TagCardinality_{}
}

type type_TagCardinality_ struct {
}

func (_this type_TagCardinality_) Default() interface{} {
	return Companion_TagCardinality_.Default()
}

func (_this type_TagCardinality_) String() string {
	return "Types.TagCardinality"
}
func (_this TagCardinality) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = TagCardinality{}

// End of datatype TagCardinality

// Definition of datatype MetricContext
type MetricContext struct {
	Data_MetricContext_
}

func (_this MetricContext) Get_() Data_MetricContext_ {
	return _this.Data_MetricContext_
}

type Data_MetricContext_ interface {
	isMetricContext()
}

type CompanionStruct_MetricContext_ struct {
}

var Companion_MetricContext_ = CompanionStruct_MetricContext_{}

type MetricContext_MetricContext struct {
	Name _dafny.Sequence
	Tags _dafny.Sequence
}

func (MetricContext_MetricContext) isMetricContext() {}

func (CompanionStruct_MetricContext_) Create_MetricContext_(Name _dafny.Sequence, Tags _dafny.Sequence) MetricContext {
	return MetricContext{MetricContext_MetricContext{Name, Tags}}
}

func (_this MetricContext) Is_MetricContext() bool {
	_, ok := _this.Get_().(MetricContext_MetricContext)
	return ok
}

func (CompanionStruct_MetricContext_) Default() MetricContext {
	return Companion_MetricContext_.Create_MetricContext_(_dafny.EmptySeq, _dafny.EmptySeq)
}

func (_this MetricContext) Dtor_name() _dafny.Sequence {
	return _this.Get_().(MetricContext_MetricContext).Name
}

func (_this MetricContext) Dtor_tags() _dafny.Sequence {
	return _this.Get_().(MetricContext_MetricContext).Tags
}

func (_this MetricContext) String() string {
	switch data := _this.Get_().(type) {
	case nil:
		return "null"
	case MetricContext_MetricContext:
		{
			return "Types.MetricContext.MetricContext" + "(" + data.Name.VerbatimString(true) + ", " + _dafny.String(data.Tags) + ")"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this MetricContext) Equals(other MetricContext) bool {
	switch data1 := _this.Get_().(type) {
	case MetricContext_MetricContext:
		{
			data2, ok := other.Get_().(MetricContext_MetricContext)
			return ok && data1.Name.Equals(data2.Name) && data1.Tags.Equals(data2.Tags)
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this MetricContext) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(MetricContext)
	return ok && _this.Equals(typed)
}

func Type_MetricContext_() _dafny.TypeDescriptor {
	return type_MetricContext_{}
}

type type_MetricContext_ struct {
}

func (_this type_MetricContext_) Default() interface{} {
	return Companion_MetricContext_.Default()
}

func (_this type_MetricContext_) String() string {
	return "Types.MetricContext"
}
func (_this MetricContext) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = MetricContext{}

// End of datatype MetricContext

// Definition of datatype DogStatsDConfig
type DogStatsDConfig struct {
	Data_DogStatsDConfig_
}

func (_this DogStatsDConfig) Get_() Data_DogStatsDConfig_ {
	return _this.Data_DogStatsDConfig_
}

type Data_DogStatsDConfig_ interface {
	isDogStatsDConfig()
}

type CompanionStruct_DogStatsDConfig_ struct {
}

var Companion_DogStatsDConfig_ = CompanionStruct_DogStatsDConfig_{}

type DogStatsDConfig_DogStatsDConfig struct {
	MaxBytesPerPayload         _dafny.Int
	BufferFlushIntervalMs      _dafny.Int
	AggregationFlushIntervalMs _dafny.Int
	SenderQueueSize            _dafny.Int
	BufferPoolCapacity         _dafny.Int
	AggregationEnabled         bool
	ExtendedAggregation        bool
	MaxSamplesPerContext       _dafny.Int
	OriginDetection            bool
	Cardinality                TagCardinality
}

func (DogStatsDConfig_DogStatsDConfig) isDogStatsDConfig() {}

func (CompanionStruct_DogStatsDConfig_) Create_DogStatsDConfig_(MaxBytesPerPayload _dafny.Int, BufferFlushIntervalMs _dafny.Int, AggregationFlushIntervalMs _dafny.Int, SenderQueueSize _dafny.Int, BufferPoolCapacity _dafny.Int, AggregationEnabled bool, ExtendedAggregation bool, MaxSamplesPerContext _dafny.Int, OriginDetection bool, Cardinality TagCardinality) DogStatsDConfig {
	return DogStatsDConfig{DogStatsDConfig_DogStatsDConfig{MaxBytesPerPayload, BufferFlushIntervalMs, AggregationFlushIntervalMs, SenderQueueSize, BufferPoolCapacity, AggregationEnabled, ExtendedAggregation, MaxSamplesPerContext, OriginDetection, Cardinality}}
}

func (_this DogStatsDConfig) Is_DogStatsDConfig() bool {
	_, ok := _this.Get_().(DogStatsDConfig_DogStatsDConfig)
	return ok
}

func (CompanionStruct_DogStatsDConfig_) Default() DogStatsDConfig {
	return Companion_DogStatsDConfig_.Create_DogStatsDConfig_(_dafny.Zero, _dafny.Zero, _dafny.Zero, _dafny.Zero, _dafny.Zero, false, false, _dafny.Zero, false, Companion_TagCardinality_.Default())
}

func (_this DogStatsDConfig) Dtor_maxBytesPerPayload() _dafny.Int {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).MaxBytesPerPayload
}

func (_this DogStatsDConfig) Dtor_bufferFlushIntervalMs() _dafny.Int {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).BufferFlushIntervalMs
}

func (_this DogStatsDConfig) Dtor_aggregationFlushIntervalMs() _dafny.Int {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).AggregationFlushIntervalMs
}

func (_this DogStatsDConfig) Dtor_senderQueueSize() _dafny.Int {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).SenderQueueSize
}

func (_this DogStatsDConfig) Dtor_bufferPoolCapacity() _dafny.Int {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).BufferPoolCapacity
}

func (_this DogStatsDConfig) Dtor_aggregationEnabled() bool {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).AggregationEnabled
}

func (_this DogStatsDConfig) Dtor_extendedAggregation() bool {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).ExtendedAggregation
}

func (_this DogStatsDConfig) Dtor_maxSamplesPerContext() _dafny.Int {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).MaxSamplesPerContext
}

func (_this DogStatsDConfig) Dtor_originDetection() bool {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).OriginDetection
}

func (_this DogStatsDConfig) Dtor_cardinality() TagCardinality {
	return _this.Get_().(DogStatsDConfig_DogStatsDConfig).Cardinality
}

func (_this DogStatsDConfig) String() string {
	switch data := _this.Get_().(type) {
	case nil:
		return "null"
	case DogStatsDConfig_DogStatsDConfig:
		{
			return "Types.DogStatsDConfig.DogStatsDConfig" + "(" + _dafny.String(data.MaxBytesPerPayload) + ", " + _dafny.String(data.BufferFlushIntervalMs) + ", " + _dafny.String(data.AggregationFlushIntervalMs) + ", " + _dafny.String(data.SenderQueueSize) + ", " + _dafny.String(data.BufferPoolCapacity) + ", " + _dafny.String(data.AggregationEnabled) + ", " + _dafny.String(data.ExtendedAggregation) + ", " + _dafny.String(data.MaxSamplesPerContext) + ", " + _dafny.String(data.OriginDetection) + ", " + _dafny.String(data.Cardinality) + ")"
		}
	default:
		{
			return "<unexpected>"
		}
	}
}

func (_this DogStatsDConfig) Equals(other DogStatsDConfig) bool {
	switch data1 := _this.Get_().(type) {
	case DogStatsDConfig_DogStatsDConfig:
		{
			data2, ok := other.Get_().(DogStatsDConfig_DogStatsDConfig)
			return ok && data1.MaxBytesPerPayload.Cmp(data2.MaxBytesPerPayload) == 0 && data1.BufferFlushIntervalMs.Cmp(data2.BufferFlushIntervalMs) == 0 && data1.AggregationFlushIntervalMs.Cmp(data2.AggregationFlushIntervalMs) == 0 && data1.SenderQueueSize.Cmp(data2.SenderQueueSize) == 0 && data1.BufferPoolCapacity.Cmp(data2.BufferPoolCapacity) == 0 && data1.AggregationEnabled == data2.AggregationEnabled && data1.ExtendedAggregation == data2.ExtendedAggregation && data1.MaxSamplesPerContext.Cmp(data2.MaxSamplesPerContext) == 0 && data1.OriginDetection == data2.OriginDetection && data1.Cardinality.Equals(data2.Cardinality)
		}
	default:
		{
			return false // unexpected
		}
	}
}

func (_this DogStatsDConfig) EqualsGeneric(other interface{}) bool {
	typed, ok := other.(DogStatsDConfig)
	return ok && _this.Equals(typed)
}

func Type_DogStatsDConfig_() _dafny.TypeDescriptor {
	return type_DogStatsDConfig_{}
}

type type_DogStatsDConfig_ struct {
}

func (_this type_DogStatsDConfig_) Default() interface{} {
	return Companion_DogStatsDConfig_.Default()
}

func (_this type_DogStatsDConfig_) String() string {
	return "Types.DogStatsDConfig"
}
func (_this DogStatsDConfig) ParentTraits_() []*_dafny.TraitID {
	return [](*_dafny.TraitID){}
}

var _ _dafny.TraitOffspring = DogStatsDConfig{}

// End of datatype DogStatsDConfig
