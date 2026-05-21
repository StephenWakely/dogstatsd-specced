import sys
from typing import Callable, Any, TypeVar, NamedTuple
from math import floor
from itertools import count

import module_ as module_
import _dafny as _dafny
import System_ as System_
import Types as Types
import Errors as Errors

# Module: Buffer


class Unit:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [Unit_Unit()]
    @classmethod
    def default(cls, ):
        return lambda: Unit_Unit()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_Unit(self) -> bool:
        return isinstance(self, Unit_Unit)

class Unit_Unit(Unit, NamedTuple('Unit', [])):
    def __dafnystr__(self) -> str:
        return f'Buffer.Unit.Unit'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, Unit_Unit)
    def __hash__(self) -> int:
        return super().__hash__()


class Buffer:
    def  __init__(self):
        self.data: _dafny.Seq = _dafny.Seq({})
        self.len_: int = int(0)
        self.maxSize: int = int(0)
        self.elementCount: int = int(0)
        self.maxElements: int = int(0)
        pass

    def __dafnystr__(self) -> str:
        return "Buffer.Buffer"
    def Valid(self):
        return (((self.len_) <= (self.maxSize)) and ((self.elementCount) <= (self.maxElements))) and ((len(self.data)) == (self.maxSize))

    def New(self, ms, me):
        (self).maxSize = ms
        (self).maxElements = me
        (self).data = _dafny.SeqWithoutIsStrInference([0 for d_0___v0_ in range(ms)])
        (self).len_ = 0
        (self).elementCount = 0

    def WriteMetric(self, metric):
        r: Errors.Result = Errors.Result.default()()
        d_0_metricLen_: int
        d_0_metricLen_ = len(metric)
        if (((self.len_) + (d_0_metricLen_)) > (self.maxSize)) or ((self.elementCount) >= (self.maxElements)):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrorSenderChannelFull())
            return r
        d_1_newLen_: int
        d_1_newLen_ = (self.len_) + (d_0_metricLen_)
        d_2_remaining_: int
        d_2_remaining_ = (self.maxSize) - (d_1_newLen_)
        (self).data = ((_dafny.SeqWithoutIsStrInference((self.data)[:self.len_:])) + (metric)) + (_dafny.SeqWithoutIsStrInference([0 for d_3___v1_ in range(d_2_remaining_)]))
        (self).len_ = d_1_newLen_
        (self).elementCount = (self.elementCount) + (1)
        r = Errors.Result_Ok(Unit_Unit())
        return r

    def Reset(self):
        (self).data = _dafny.SeqWithoutIsStrInference([0 for d_0___v2_ in range(self.maxSize)])
        (self).len_ = 0
        (self).elementCount = 0

    def IsEmpty(self):
        return (self.len_) == (0)

    def Bytes(self):
        return _dafny.SeqWithoutIsStrInference((self.data)[:self.len_:])

