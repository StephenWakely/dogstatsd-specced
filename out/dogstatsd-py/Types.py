import sys
from typing import Callable, Any, TypeVar, NamedTuple
from math import floor
from itertools import count

import module_ as module_
import _dafny as _dafny
import System_ as System_

# Module: Types

class default__:
    def  __init__(self):
        pass

    @staticmethod
    def MetricTypeSymbol(t):
        source0_ = t
        if True:
            if source0_.is_Gauge:
                return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "g"))
        if True:
            if source0_.is_Count:
                return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "c"))
        if True:
            if source0_.is_Histogram:
                return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "h"))
        if True:
            if source0_.is_Distribution:
                return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "d"))
        if True:
            if source0_.is_Set:
                return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "s"))
        if True:
            return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "ms"))

    @staticmethod
    def CardinalityString(c):
        source0_ = c
        if True:
            if source0_.is_CardinalityNotSet:
                return Option_None()
        if True:
            if source0_.is_CardinalityNone:
                return Option_Some(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "none")))
        if True:
            if source0_.is_CardinalityLow:
                return Option_Some(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "low")))
        if True:
            if source0_.is_CardinalityOrchestrator:
                return Option_Some(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "orchestrator")))
        if True:
            return Option_Some(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "high")))

    @staticmethod
    def DefaultConfig():
        return DogStatsDConfig_DogStatsDConfig(default__.UDP__MAX__BYTES, default__.DEFAULT__BUFFER__FLUSH__INTERVAL__MS, default__.DEFAULT__AGGREGATION__FLUSH__INTERVAL__MS, default__.DEFAULT__SENDER__QUEUE__SIZE, default__.DEFAULT__BUFFER__POOL__CAPACITY, True, False, -1, True, TagCardinality_CardinalityNotSet())

    @_dafny.classproperty
    def UDP__MAX__BYTES(instance):
        return 1432
    @_dafny.classproperty
    def DEFAULT__BUFFER__FLUSH__INTERVAL__MS(instance):
        return 100
    @_dafny.classproperty
    def DEFAULT__AGGREGATION__FLUSH__INTERVAL__MS(instance):
        return 2000
    @_dafny.classproperty
    def DEFAULT__SENDER__QUEUE__SIZE(instance):
        return 512
    @_dafny.classproperty
    def DEFAULT__BUFFER__POOL__CAPACITY(instance):
        return 2048
    @_dafny.classproperty
    def UDS__MAX__BYTES(instance):
        return 8192

class Option:
    @classmethod
    def default(cls, ):
        return lambda: Option_None()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_None(self) -> bool:
        return isinstance(self, Option_None)
    @property
    def is_Some(self) -> bool:
        return isinstance(self, Option_Some)

class Option_None(Option, NamedTuple('None_', [])):
    def __dafnystr__(self) -> str:
        return f'Types.Option.None'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, Option_None)
    def __hash__(self) -> int:
        return super().__hash__()

class Option_Some(Option, NamedTuple('Some', [('value', Any)])):
    def __dafnystr__(self) -> str:
        return f'Types.Option.Some({_dafny.string_of(self.value)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, Option_Some) and self.value == __o.value
    def __hash__(self) -> int:
        return super().__hash__()


class MetricType:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [MetricType_Gauge(), MetricType_Count(), MetricType_Histogram(), MetricType_Distribution(), MetricType_Set(), MetricType_Timing()]
    @classmethod
    def default(cls, ):
        return lambda: MetricType_Gauge()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_Gauge(self) -> bool:
        return isinstance(self, MetricType_Gauge)
    @property
    def is_Count(self) -> bool:
        return isinstance(self, MetricType_Count)
    @property
    def is_Histogram(self) -> bool:
        return isinstance(self, MetricType_Histogram)
    @property
    def is_Distribution(self) -> bool:
        return isinstance(self, MetricType_Distribution)
    @property
    def is_Set(self) -> bool:
        return isinstance(self, MetricType_Set)
    @property
    def is_Timing(self) -> bool:
        return isinstance(self, MetricType_Timing)

class MetricType_Gauge(MetricType, NamedTuple('Gauge', [])):
    def __dafnystr__(self) -> str:
        return f'Types.MetricType.Gauge'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, MetricType_Gauge)
    def __hash__(self) -> int:
        return super().__hash__()

class MetricType_Count(MetricType, NamedTuple('Count', [])):
    def __dafnystr__(self) -> str:
        return f'Types.MetricType.Count'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, MetricType_Count)
    def __hash__(self) -> int:
        return super().__hash__()

class MetricType_Histogram(MetricType, NamedTuple('Histogram', [])):
    def __dafnystr__(self) -> str:
        return f'Types.MetricType.Histogram'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, MetricType_Histogram)
    def __hash__(self) -> int:
        return super().__hash__()

class MetricType_Distribution(MetricType, NamedTuple('Distribution', [])):
    def __dafnystr__(self) -> str:
        return f'Types.MetricType.Distribution'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, MetricType_Distribution)
    def __hash__(self) -> int:
        return super().__hash__()

class MetricType_Set(MetricType, NamedTuple('Set', [])):
    def __dafnystr__(self) -> str:
        return f'Types.MetricType.Set'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, MetricType_Set)
    def __hash__(self) -> int:
        return super().__hash__()

class MetricType_Timing(MetricType, NamedTuple('Timing', [])):
    def __dafnystr__(self) -> str:
        return f'Types.MetricType.Timing'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, MetricType_Timing)
    def __hash__(self) -> int:
        return super().__hash__()


class TransportMode:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [TransportMode_UDP(), TransportMode_UDS(), TransportMode_Pipe()]
    @classmethod
    def default(cls, ):
        return lambda: TransportMode_UDP()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_UDP(self) -> bool:
        return isinstance(self, TransportMode_UDP)
    @property
    def is_UDS(self) -> bool:
        return isinstance(self, TransportMode_UDS)
    @property
    def is_Pipe(self) -> bool:
        return isinstance(self, TransportMode_Pipe)

class TransportMode_UDP(TransportMode, NamedTuple('UDP', [])):
    def __dafnystr__(self) -> str:
        return f'Types.TransportMode.UDP'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, TransportMode_UDP)
    def __hash__(self) -> int:
        return super().__hash__()

class TransportMode_UDS(TransportMode, NamedTuple('UDS', [])):
    def __dafnystr__(self) -> str:
        return f'Types.TransportMode.UDS'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, TransportMode_UDS)
    def __hash__(self) -> int:
        return super().__hash__()

class TransportMode_Pipe(TransportMode, NamedTuple('Pipe', [])):
    def __dafnystr__(self) -> str:
        return f'Types.TransportMode.Pipe'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, TransportMode_Pipe)
    def __hash__(self) -> int:
        return super().__hash__()


class TagCardinality:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [TagCardinality_CardinalityNotSet(), TagCardinality_CardinalityNone(), TagCardinality_CardinalityLow(), TagCardinality_CardinalityOrchestrator(), TagCardinality_CardinalityHigh()]
    @classmethod
    def default(cls, ):
        return lambda: TagCardinality_CardinalityNotSet()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_CardinalityNotSet(self) -> bool:
        return isinstance(self, TagCardinality_CardinalityNotSet)
    @property
    def is_CardinalityNone(self) -> bool:
        return isinstance(self, TagCardinality_CardinalityNone)
    @property
    def is_CardinalityLow(self) -> bool:
        return isinstance(self, TagCardinality_CardinalityLow)
    @property
    def is_CardinalityOrchestrator(self) -> bool:
        return isinstance(self, TagCardinality_CardinalityOrchestrator)
    @property
    def is_CardinalityHigh(self) -> bool:
        return isinstance(self, TagCardinality_CardinalityHigh)

class TagCardinality_CardinalityNotSet(TagCardinality, NamedTuple('CardinalityNotSet', [])):
    def __dafnystr__(self) -> str:
        return f'Types.TagCardinality.CardinalityNotSet'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, TagCardinality_CardinalityNotSet)
    def __hash__(self) -> int:
        return super().__hash__()

class TagCardinality_CardinalityNone(TagCardinality, NamedTuple('CardinalityNone', [])):
    def __dafnystr__(self) -> str:
        return f'Types.TagCardinality.CardinalityNone'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, TagCardinality_CardinalityNone)
    def __hash__(self) -> int:
        return super().__hash__()

class TagCardinality_CardinalityLow(TagCardinality, NamedTuple('CardinalityLow', [])):
    def __dafnystr__(self) -> str:
        return f'Types.TagCardinality.CardinalityLow'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, TagCardinality_CardinalityLow)
    def __hash__(self) -> int:
        return super().__hash__()

class TagCardinality_CardinalityOrchestrator(TagCardinality, NamedTuple('CardinalityOrchestrator', [])):
    def __dafnystr__(self) -> str:
        return f'Types.TagCardinality.CardinalityOrchestrator'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, TagCardinality_CardinalityOrchestrator)
    def __hash__(self) -> int:
        return super().__hash__()

class TagCardinality_CardinalityHigh(TagCardinality, NamedTuple('CardinalityHigh', [])):
    def __dafnystr__(self) -> str:
        return f'Types.TagCardinality.CardinalityHigh'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, TagCardinality_CardinalityHigh)
    def __hash__(self) -> int:
        return super().__hash__()


class MetricContext:
    @classmethod
    def default(cls, ):
        return lambda: MetricContext_MetricContext(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "")), _dafny.Seq({}))
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_MetricContext(self) -> bool:
        return isinstance(self, MetricContext_MetricContext)

class MetricContext_MetricContext(MetricContext, NamedTuple('MetricContext', [('name', Any), ('tags', Any)])):
    def __dafnystr__(self) -> str:
        return f'Types.MetricContext.MetricContext({self.name.VerbatimString(True)}, {_dafny.string_of(self.tags)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, MetricContext_MetricContext) and self.name == __o.name and self.tags == __o.tags
    def __hash__(self) -> int:
        return super().__hash__()


class DogStatsDConfig:
    @classmethod
    def default(cls, ):
        return lambda: DogStatsDConfig_DogStatsDConfig(int(0), int(0), int(0), int(0), int(0), False, False, int(0), False, TagCardinality.default()())
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_DogStatsDConfig(self) -> bool:
        return isinstance(self, DogStatsDConfig_DogStatsDConfig)

class DogStatsDConfig_DogStatsDConfig(DogStatsDConfig, NamedTuple('DogStatsDConfig', [('maxBytesPerPayload', Any), ('bufferFlushIntervalMs', Any), ('aggregationFlushIntervalMs', Any), ('senderQueueSize', Any), ('bufferPoolCapacity', Any), ('aggregationEnabled', Any), ('extendedAggregation', Any), ('maxSamplesPerContext', Any), ('originDetection', Any), ('cardinality', Any)])):
    def __dafnystr__(self) -> str:
        return f'Types.DogStatsDConfig.DogStatsDConfig({_dafny.string_of(self.maxBytesPerPayload)}, {_dafny.string_of(self.bufferFlushIntervalMs)}, {_dafny.string_of(self.aggregationFlushIntervalMs)}, {_dafny.string_of(self.senderQueueSize)}, {_dafny.string_of(self.bufferPoolCapacity)}, {_dafny.string_of(self.aggregationEnabled)}, {_dafny.string_of(self.extendedAggregation)}, {_dafny.string_of(self.maxSamplesPerContext)}, {_dafny.string_of(self.originDetection)}, {_dafny.string_of(self.cardinality)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, DogStatsDConfig_DogStatsDConfig) and self.maxBytesPerPayload == __o.maxBytesPerPayload and self.bufferFlushIntervalMs == __o.bufferFlushIntervalMs and self.aggregationFlushIntervalMs == __o.aggregationFlushIntervalMs and self.senderQueueSize == __o.senderQueueSize and self.bufferPoolCapacity == __o.bufferPoolCapacity and self.aggregationEnabled == __o.aggregationEnabled and self.extendedAggregation == __o.extendedAggregation and self.maxSamplesPerContext == __o.maxSamplesPerContext and self.originDetection == __o.originDetection and self.cardinality == __o.cardinality
    def __hash__(self) -> int:
        return super().__hash__()

