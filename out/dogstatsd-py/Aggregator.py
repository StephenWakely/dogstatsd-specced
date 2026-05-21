import sys
from typing import Callable, Any, TypeVar, NamedTuple
from math import floor
from itertools import count

import module_ as module_
import _dafny as _dafny
import System_ as System_
import Types as Types
import Errors as Errors
import Buffer as Buffer
import WireFormat as WireFormat

# Module: Aggregator

class default__:
    def  __init__(self):
        pass

    @staticmethod
    def FNV1aStep(h, c):
        d_0_b_ = _dafny.euclidian_modulus(ord(c), 256)
        return (((h) ^ (d_0_b_)) * (default__.FNV__PRIME__32)) & ((1 << 32) - 1)

    @staticmethod
    def FNV1aStringAcc(s, h):
        while True:
            with _dafny.label():
                if (len(s)) == (0):
                    return h
                elif True:
                    in0_ = _dafny.SeqWithoutIsStrInference((s)[1::])
                    in1_ = default__.FNV1aStep(h, (s)[0])
                    s = in0_
                    h = in1_
                    raise _dafny.TailCall()
                break

    @staticmethod
    def FNV1aTagsAcc(tags, h):
        while True:
            with _dafny.label():
                if (len(tags)) == (0):
                    return h
                elif True:
                    in0_ = _dafny.SeqWithoutIsStrInference((tags)[1::])
                    in1_ = default__.FNV1aStringAcc((tags)[0], h)
                    tags = in0_
                    h = in1_
                    raise _dafny.TailCall()
                break

    @staticmethod
    def ContextHash(ctx):
        return default__.FNV1aTagsAcc((ctx).tags, default__.FNV1aStringAcc((ctx).name, default__.FNV__OFFSET__32))

    @staticmethod
    def ShardIndex(ctx, shardCount):
        return _dafny.euclidian_modulus(default__.ContextHash(ctx), shardCount)

    @staticmethod
    def AllType(metrics, t):
        def lambda0_(forall_var_0_):
            d_0_k_: int = forall_var_0_
            return not (((0) <= (d_0_k_)) and ((d_0_k_) < (len(metrics)))) or ((((metrics)[d_0_k_]).metricType) == (t))

        return _dafny.quantifier(_dafny.IntegerRange(0, len(metrics)), True, lambda0_)

    @staticmethod
    def UniqueWireMetrics(metrics):
        def lambda0_(forall_var_0_):
            def lambda1_(forall_var_1_):
                d_1_j_: int = forall_var_1_
                return not ((((0) <= (d_0_i_)) and ((d_0_i_) < (d_1_j_))) and ((d_1_j_) < (len(metrics)))) or (not((((((metrics)[d_0_i_]).name) == (((metrics)[d_1_j_]).name)) and ((((metrics)[d_0_i_]).tags) == (((metrics)[d_1_j_]).tags))) and ((((metrics)[d_0_i_]).metricType) == (((metrics)[d_1_j_]).metricType))))

            d_0_i_: int = forall_var_0_
            return _dafny.quantifier(_dafny.IntegerRange((d_0_i_) + (1), len(metrics)), True, lambda1_)

        return _dafny.quantifier(_dafny.IntegerRange(0, len(metrics)), True, lambda0_)

    @staticmethod
    def IntToString(n):
        return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, ""))

    @staticmethod
    def RealToString(r):
        return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, ""))

    @staticmethod
    def PickContextFromSet(s):
        return Types.MetricContext_MetricContext(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "")), _dafny.SeqWithoutIsStrInference([]))

    @_dafny.classproperty
    def FNV__PRIME__32(instance):
        return 16777619
    @_dafny.classproperty
    def FNV__OFFSET__32(instance):
        return 2166136261

class AggregatorState:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [AggregatorState_Running(), AggregatorState_Stopped()]
    @classmethod
    def default(cls, ):
        return lambda: AggregatorState_Running()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_Running(self) -> bool:
        return isinstance(self, AggregatorState_Running)
    @property
    def is_Stopped(self) -> bool:
        return isinstance(self, AggregatorState_Stopped)

class AggregatorState_Running(AggregatorState, NamedTuple('Running', [])):
    def __dafnystr__(self) -> str:
        return f'Aggregator.AggregatorState.Running'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, AggregatorState_Running)
    def __hash__(self) -> int:
        return super().__hash__()

class AggregatorState_Stopped(AggregatorState, NamedTuple('Stopped', [])):
    def __dafnystr__(self) -> str:
        return f'Aggregator.AggregatorState.Stopped'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, AggregatorState_Stopped)
    def __hash__(self) -> int:
        return super().__hash__()


class BufferedMetricState:
    @classmethod
    def default(cls, ):
        return lambda: BufferedMetricState_BufferedMetricState(_dafny.Seq({}), int(0))
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_BufferedMetricState(self) -> bool:
        return isinstance(self, BufferedMetricState_BufferedMetricState)

class BufferedMetricState_BufferedMetricState(BufferedMetricState, NamedTuple('BufferedMetricState', [('samples', Any), ('totalSamples', Any)])):
    def __dafnystr__(self) -> str:
        return f'Aggregator.BufferedMetricState.BufferedMetricState({_dafny.string_of(self.samples)}, {_dafny.string_of(self.totalSamples)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, BufferedMetricState_BufferedMetricState) and self.samples == __o.samples and self.totalSamples == __o.totalSamples
    def __hash__(self) -> int:
        return super().__hash__()


class Aggregator:
    def  __init__(self):
        self.state: AggregatorState = AggregatorState.default()()
        self.countShards: _dafny.Seq = _dafny.Seq({})
        self.gaugeShards: _dafny.Seq = _dafny.Seq({})
        self.setShards: _dafny.Seq = _dafny.Seq({})
        self.buffered: _dafny.Map = _dafny.Map({})
        self.shardCount: int = int(0)
        pass

    def __dafnystr__(self) -> str:
        return "Aggregator.Aggregator"
    def Valid(self):
        def lambda0_(forall_var_0_):
            def lambda1_(forall_var_1_):
                d_1_ctx_: Types.MetricContext = forall_var_1_
                return not ((d_1_ctx_) in ((self.countShards)[d_0_s_])) or ((((self.countShards)[d_0_s_])[d_1_ctx_]) >= (0))

            d_0_s_: int = forall_var_0_
            return not (((0) <= (d_0_s_)) and ((d_0_s_) < (self.shardCount))) or (_dafny.quantifier(((self.countShards)[d_0_s_]).keys.Elements, True, lambda1_))

        def lambda2_(forall_var_2_):
            def lambda3_(forall_var_3_):
                d_3_ctx_: Types.MetricContext = forall_var_3_
                return not ((d_3_ctx_) in ((self.countShards)[d_2_s_])) or ((default__.ShardIndex(d_3_ctx_, self.shardCount)) == (d_2_s_))

            d_2_s_: int = forall_var_2_
            return not (((0) <= (d_2_s_)) and ((d_2_s_) < (self.shardCount))) or (_dafny.quantifier(((self.countShards)[d_2_s_]).keys.Elements, True, lambda3_))

        def lambda4_(forall_var_4_):
            def lambda5_(forall_var_5_):
                d_5_ctx_: Types.MetricContext = forall_var_5_
                return not ((d_5_ctx_) in ((self.gaugeShards)[d_4_s_])) or ((default__.ShardIndex(d_5_ctx_, self.shardCount)) == (d_4_s_))

            d_4_s_: int = forall_var_4_
            return not (((0) <= (d_4_s_)) and ((d_4_s_) < (self.shardCount))) or (_dafny.quantifier(((self.gaugeShards)[d_4_s_]).keys.Elements, True, lambda5_))

        def lambda6_(forall_var_6_):
            def lambda7_(forall_var_7_):
                d_7_ctx_: Types.MetricContext = forall_var_7_
                return not ((d_7_ctx_) in ((self.setShards)[d_6_s_])) or ((default__.ShardIndex(d_7_ctx_, self.shardCount)) == (d_6_s_))

            d_6_s_: int = forall_var_6_
            return not (((0) <= (d_6_s_)) and ((d_6_s_) < (self.shardCount))) or (_dafny.quantifier(((self.setShards)[d_6_s_]).keys.Elements, True, lambda7_))

        return ((((((((self.shardCount) > (0)) and ((len(self.countShards)) == (self.shardCount))) and ((len(self.gaugeShards)) == (self.shardCount))) and ((len(self.setShards)) == (self.shardCount))) and (_dafny.quantifier(_dafny.IntegerRange(0, self.shardCount), True, lambda0_))) and (_dafny.quantifier(_dafny.IntegerRange(0, self.shardCount), True, lambda2_))) and (_dafny.quantifier(_dafny.IntegerRange(0, self.shardCount), True, lambda4_))) and (_dafny.quantifier(_dafny.IntegerRange(0, self.shardCount), True, lambda6_))

    def New(self, n):
        (self).state = AggregatorState_Running()
        (self).shardCount = n
        (self).countShards = _dafny.SeqWithoutIsStrInference([_dafny.Map({}) for d_0___v0_ in range(n)])
        (self).gaugeShards = _dafny.SeqWithoutIsStrInference([_dafny.Map({}) for d_1___v1_ in range(n)])
        (self).setShards = _dafny.SeqWithoutIsStrInference([_dafny.Map({}) for d_2___v2_ in range(n)])
        (self).buffered = _dafny.Map({})

    def SampleCount(self, ctx, value):
        d_0_s_: int
        d_0_s_ = default__.ShardIndex(ctx, self.shardCount)
        d_1_prev_: int
        if (ctx) in ((self.countShards)[d_0_s_]):
            d_1_prev_ = ((self.countShards)[d_0_s_])[ctx]
        elif True:
            d_1_prev_ = 0
        (self).countShards = (self.countShards).set(d_0_s_, ((self.countShards)[d_0_s_]).set(ctx, (d_1_prev_) + (value)))

    def SampleGauge(self, ctx, value):
        d_0_s_: int
        d_0_s_ = default__.ShardIndex(ctx, self.shardCount)
        (self).gaugeShards = (self.gaugeShards).set(d_0_s_, ((self.gaugeShards)[d_0_s_]).set(ctx, value))

    def SampleSet(self, ctx, value):
        d_0_s_: int
        d_0_s_ = default__.ShardIndex(ctx, self.shardCount)
        d_1_oldSet_: _dafny.Set
        if (ctx) in ((self.setShards)[d_0_s_]):
            d_1_oldSet_ = ((self.setShards)[d_0_s_])[ctx]
        elif True:
            d_1_oldSet_ = _dafny.Set({})
        (self).setShards = (self.setShards).set(d_0_s_, ((self.setShards)[d_0_s_]).set(ctx, (d_1_oldSet_) | (_dafny.Set({value}))))

    def SampleBuffered(self, ctx, value, maxSamples):
        d_0_oldState_: BufferedMetricState
        if (ctx) in (self.buffered):
            d_0_oldState_ = (self.buffered)[ctx]
        elif True:
            d_0_oldState_ = BufferedMetricState_BufferedMetricState(_dafny.SeqWithoutIsStrInference([]), 0)
        d_1_newSamples_: _dafny.Seq
        if ((maxSamples) > (0)) and ((len((d_0_oldState_).samples)) < (maxSamples)):
            d_1_newSamples_ = ((d_0_oldState_).samples) + (_dafny.SeqWithoutIsStrInference([value]))
        elif True:
            d_1_newSamples_ = (d_0_oldState_).samples
        (self).buffered = (self.buffered).set(ctx, BufferedMetricState_BufferedMetricState(d_1_newSamples_, ((d_0_oldState_).totalSamples) + (1)))

    def Flush(self):
        result: _dafny.Seq = _dafny.Seq({})
        d_0_countResult_: _dafny.Seq
        out0_: _dafny.Seq
        out0_ = (self).CollectCountMetrics()
        d_0_countResult_ = out0_
        d_1_gaugeResult_: _dafny.Seq
        out1_: _dafny.Seq
        out1_ = (self).CollectGaugeMetrics()
        d_1_gaugeResult_ = out1_
        d_2_setResult_: _dafny.Seq
        out2_: _dafny.Seq
        out2_ = (self).CollectSetMetrics()
        d_2_setResult_ = out2_
        d_3_bufferedResult_: _dafny.Seq
        out3_: _dafny.Seq
        out3_ = (self).CollectBufferedMetrics()
        d_3_bufferedResult_ = out3_
        (self).countShards = _dafny.SeqWithoutIsStrInference([_dafny.Map({}) for d_4___v3_ in range(self.shardCount)])
        (self).gaugeShards = _dafny.SeqWithoutIsStrInference([_dafny.Map({}) for d_5___v4_ in range(self.shardCount)])
        (self).setShards = _dafny.SeqWithoutIsStrInference([_dafny.Map({}) for d_6___v5_ in range(self.shardCount)])
        (self).buffered = _dafny.Map({})
        d_7_cg_: _dafny.Seq
        d_7_cg_ = (d_0_countResult_) + (d_1_gaugeResult_)
        d_8_cgs_: _dafny.Seq
        d_8_cgs_ = (d_7_cg_) + (d_2_setResult_)
        result = (d_8_cgs_) + (d_3_bufferedResult_)
        return result

    def CollectCountMetrics(self):
        r: _dafny.Seq = _dafny.Seq({})
        r = _dafny.SeqWithoutIsStrInference([])
        d_0_si_: int
        d_0_si_ = 0
        while (d_0_si_) < (self.shardCount):
            d_1_shard_: _dafny.Map
            d_1_shard_ = (self.countShards)[d_0_si_]
            d_2_remaining_: _dafny.Set
            d_2_remaining_ = (d_1_shard_).keys
            while (d_2_remaining_) != (_dafny.Set({})):
                d_3_ctx_: Types.MetricContext
                d_3_ctx_ = default__.PickContextFromSet(d_2_remaining_)
                d_4_v_: int
                d_4_v_ = (d_1_shard_)[d_3_ctx_]
                if (d_4_v_) != (0):
                    d_5_m_: WireFormat.WireMetric
                    d_5_m_ = WireFormat.WireMetric_WireMetric((d_3_ctx_).name, default__.IntToString(d_4_v_), Types.MetricType_Count(), Types.Option_None(), (d_3_ctx_).tags, Types.Option_None(), Types.Option_None(), Types.TagCardinality_CardinalityNotSet())
                    r = (r) + (_dafny.SeqWithoutIsStrInference([d_5_m_]))
                d_2_remaining_ = (d_2_remaining_) - (_dafny.Set({d_3_ctx_}))
            d_0_si_ = (d_0_si_) + (1)
        return r

    def CollectGaugeMetrics(self):
        r: _dafny.Seq = _dafny.Seq({})
        r = _dafny.SeqWithoutIsStrInference([])
        d_0_si_: int
        d_0_si_ = 0
        while (d_0_si_) < (self.shardCount):
            d_1_shard_: _dafny.Map
            d_1_shard_ = (self.gaugeShards)[d_0_si_]
            d_2_remaining_: _dafny.Set
            d_2_remaining_ = (d_1_shard_).keys
            while (d_2_remaining_) != (_dafny.Set({})):
                d_3_ctx_: Types.MetricContext
                d_3_ctx_ = default__.PickContextFromSet(d_2_remaining_)
                d_4_v_: _dafny.BigRational
                d_4_v_ = (d_1_shard_)[d_3_ctx_]
                d_5_m_: WireFormat.WireMetric
                d_5_m_ = WireFormat.WireMetric_WireMetric((d_3_ctx_).name, default__.RealToString(d_4_v_), Types.MetricType_Gauge(), Types.Option_None(), (d_3_ctx_).tags, Types.Option_None(), Types.Option_None(), Types.TagCardinality_CardinalityNotSet())
                r = (r) + (_dafny.SeqWithoutIsStrInference([d_5_m_]))
                d_2_remaining_ = (d_2_remaining_) - (_dafny.Set({d_3_ctx_}))
            d_0_si_ = (d_0_si_) + (1)
        return r

    def CollectSetMetrics(self):
        r: _dafny.Seq = _dafny.Seq({})
        r = _dafny.SeqWithoutIsStrInference([])
        d_0_si_: int
        d_0_si_ = 0
        while (d_0_si_) < (self.shardCount):
            d_1_shard_: _dafny.Map
            d_1_shard_ = (self.setShards)[d_0_si_]
            d_2_remaining_: _dafny.Set
            d_2_remaining_ = (d_1_shard_).keys
            while (d_2_remaining_) != (_dafny.Set({})):
                d_3_ctx_: Types.MetricContext
                d_3_ctx_ = default__.PickContextFromSet(d_2_remaining_)
                d_4_v_: _dafny.Set
                d_4_v_ = (d_1_shard_)[d_3_ctx_]
                if (d_4_v_) != (_dafny.Set({})):
                    d_5_m_: WireFormat.WireMetric
                    d_5_m_ = WireFormat.WireMetric_WireMetric((d_3_ctx_).name, default__.IntToString(len(d_4_v_)), Types.MetricType_Set(), Types.Option_None(), (d_3_ctx_).tags, Types.Option_None(), Types.Option_None(), Types.TagCardinality_CardinalityNotSet())
                    r = (r) + (_dafny.SeqWithoutIsStrInference([d_5_m_]))
                d_2_remaining_ = (d_2_remaining_) - (_dafny.Set({d_3_ctx_}))
            d_0_si_ = (d_0_si_) + (1)
        return r

    def CollectBufferedMetrics(self):
        r: _dafny.Seq = _dafny.Seq({})
        r = _dafny.SeqWithoutIsStrInference([])
        d_0_remaining_: _dafny.Set
        d_0_remaining_ = (self.buffered).keys
        while (d_0_remaining_) != (_dafny.Set({})):
            d_1_ctx_: Types.MetricContext
            d_1_ctx_ = default__.PickContextFromSet(d_0_remaining_)
            d_2_bs_: BufferedMetricState
            d_2_bs_ = (self.buffered)[d_1_ctx_]
            d_3_cnt_: int
            d_3_cnt_ = (d_2_bs_).totalSamples
            d_4_m_: WireFormat.WireMetric
            d_4_m_ = WireFormat.WireMetric_WireMetric((d_1_ctx_).name, default__.IntToString(d_3_cnt_), Types.MetricType_Histogram(), Types.Option_None(), (d_1_ctx_).tags, Types.Option_None(), Types.Option_None(), Types.TagCardinality_CardinalityNotSet())
            r = (r) + (_dafny.SeqWithoutIsStrInference([d_4_m_]))
            d_0_remaining_ = (d_0_remaining_) - (_dafny.Set({d_1_ctx_}))
        return r

    def Stop(self):
        (self).state = AggregatorState_Stopped()

