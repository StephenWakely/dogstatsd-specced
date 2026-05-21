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

# Module: WireFormat

class default__:
    def  __init__(self):
        pass

    @staticmethod
    def StringToBytes(s):
        d_0___accumulator_ = _dafny.SeqWithoutIsStrInference([])
        while True:
            with _dafny.label():
                if (len(s)) == (0):
                    return (d_0___accumulator_) + (_dafny.SeqWithoutIsStrInference([]))
                elif True:
                    d_1_code_ = ord((s)[0])
                    d_2_bval_ = (d_1_code_ if ((0) <= (d_1_code_)) and ((d_1_code_) < (256)) else 0)
                    d_0___accumulator_ = (d_0___accumulator_) + (_dafny.SeqWithoutIsStrInference([d_2_bval_]))
                    in0_ = _dafny.SeqWithoutIsStrInference((s)[1::])
                    s = in0_
                    raise _dafny.TailCall()
                break

    @staticmethod
    def RealToDecimalBytes(r):
        return _dafny.SeqWithoutIsStrInference([])

    @staticmethod
    def SerializeName(name):
        return default__.StringToBytes(name)

    @staticmethod
    def SerializeValue(value):
        return default__.StringToBytes(value)

    @staticmethod
    def SerializeType(t):
        return default__.StringToBytes(Types.default__.MetricTypeSymbol(t))

    @staticmethod
    def SerializeRate(rate):
        if ((rate).is_None) or (((rate).value) >= (_dafny.BigRational('1e0'))):
            return _dafny.SeqWithoutIsStrInference([])
        elif True:
            return (default__.StringToBytes(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "|@")))) + (default__.RealToDecimalBytes((rate).value))

    @staticmethod
    def JoinTags(tags):
        d_0___accumulator_ = _dafny.SeqWithoutIsStrInference([])
        while True:
            with _dafny.label():
                if (len(tags)) == (0):
                    return (d_0___accumulator_) + (_dafny.SeqWithoutIsStrInference([]))
                elif (len(tags)) == (1):
                    return (d_0___accumulator_) + (default__.StringToBytes((tags)[0]))
                elif True:
                    d_0___accumulator_ = (d_0___accumulator_) + ((default__.StringToBytes((tags)[0])) + (default__.StringToBytes(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, ",")))))
                    in0_ = _dafny.SeqWithoutIsStrInference((tags)[1::])
                    tags = in0_
                    raise _dafny.TailCall()
                break

    @staticmethod
    def SerializeTags(tags):
        if (len(tags)) == (0):
            return _dafny.SeqWithoutIsStrInference([])
        elif True:
            return (default__.StringToBytes(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "|#")))) + (default__.JoinTags(tags))

    @staticmethod
    def SerializeContainerID(cid):
        source0_ = cid
        if True:
            if source0_.is_None:
                return _dafny.SeqWithoutIsStrInference([])
        if True:
            d_0_id_ = source0_.value
            return (default__.StringToBytes(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "|c:")))) + (default__.StringToBytes(d_0_id_))

    @staticmethod
    def SerializeExternalEnv(env):
        source0_ = env
        if True:
            if source0_.is_None:
                return _dafny.SeqWithoutIsStrInference([])
        if True:
            d_0_e_ = source0_.value
            if (len(d_0_e_)) == (0):
                return _dafny.SeqWithoutIsStrInference([])
            elif True:
                return (default__.StringToBytes(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "|e:")))) + (default__.StringToBytes(d_0_e_))

    @staticmethod
    def SerializeCardinality(c):
        source0_ = Types.default__.CardinalityString(c)
        if True:
            if source0_.is_None:
                return _dafny.SeqWithoutIsStrInference([])
        if True:
            d_0_s_ = source0_.value
            return (default__.StringToBytes(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "|card:")))) + (default__.StringToBytes(d_0_s_))

    @staticmethod
    def SerializeWireFormat(m):
        return ((((((((((default__.SerializeName((m).name)) + (default__.StringToBytes(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, ":"))))) + (default__.SerializeValue((m).value))) + (default__.StringToBytes(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "|"))))) + (default__.SerializeType((m).metricType))) + (default__.SerializeRate((m).rate))) + (default__.SerializeTags((m).tags))) + (default__.SerializeContainerID((m).containerID))) + (default__.SerializeExternalEnv((m).externalEnv))) + (default__.SerializeCardinality((m).cardinality))) + (_dafny.SeqWithoutIsStrInference([ord(_dafny.CodePoint('\n'))]))


class WireMetric:
    @classmethod
    def default(cls, ):
        return lambda: WireMetric_WireMetric(_dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "")), _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "")), Types.MetricType.default()(), Types.Option.default()(), _dafny.Seq({}), Types.Option.default()(), Types.Option.default()(), Types.TagCardinality.default()())
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_WireMetric(self) -> bool:
        return isinstance(self, WireMetric_WireMetric)

class WireMetric_WireMetric(WireMetric, NamedTuple('WireMetric', [('name', Any), ('value', Any), ('metricType', Any), ('rate', Any), ('tags', Any), ('containerID', Any), ('externalEnv', Any), ('cardinality', Any)])):
    def __dafnystr__(self) -> str:
        return f'WireFormat.WireMetric.WireMetric({self.name.VerbatimString(True)}, {self.value.VerbatimString(True)}, {_dafny.string_of(self.metricType)}, {_dafny.string_of(self.rate)}, {_dafny.string_of(self.tags)}, {_dafny.string_of(self.containerID)}, {_dafny.string_of(self.externalEnv)}, {_dafny.string_of(self.cardinality)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, WireMetric_WireMetric) and self.name == __o.name and self.value == __o.value and self.metricType == __o.metricType and self.rate == __o.rate and self.tags == __o.tags and self.containerID == __o.containerID and self.externalEnv == __o.externalEnv and self.cardinality == __o.cardinality
    def __hash__(self) -> int:
        return super().__hash__()

