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
import Aggregator as Aggregator
import Sender as Sender

# Module: Singletons

class default__:
    def  __init__(self):
        pass

    @staticmethod
    def IsPrintableNonPipe(c):
        return (((32) <= (ord(c))) and ((ord(c)) <= (126))) and ((c) != (_dafny.CodePoint('|')))

    @staticmethod
    def SanitizeExternalEnv(raw):
        d_0___accumulator_ = _dafny.SeqWithoutIsStrInference([])
        while True:
            with _dafny.label():
                if (len(raw)) == (0):
                    return (d_0___accumulator_) + (_dafny.SeqWithoutIsStrInference([]))
                elif True:
                    d_0___accumulator_ = (d_0___accumulator_) + ((_dafny.SeqWithoutIsStrInference([(raw)[0]]) if default__.IsPrintableNonPipe((raw)[0]) else _dafny.SeqWithoutIsStrInference([])))
                    in0_ = _dafny.SeqWithoutIsStrInference((raw)[1::])
                    raw = in0_
                    raise _dafny.TailCall()
                break


class InitState:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [InitState_Unset(), InitState_Set()]
    @classmethod
    def default(cls, ):
        return lambda: InitState_Unset()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_Unset(self) -> bool:
        return isinstance(self, InitState_Unset)
    @property
    def is_Set(self) -> bool:
        return isinstance(self, InitState_Set)

class InitState_Unset(InitState, NamedTuple('Unset', [])):
    def __dafnystr__(self) -> str:
        return f'Singletons.InitState.Unset'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, InitState_Unset)
    def __hash__(self) -> int:
        return super().__hash__()

class InitState_Set(InitState, NamedTuple('Set', [])):
    def __dafnystr__(self) -> str:
        return f'Singletons.InitState.Set'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, InitState_Set)
    def __hash__(self) -> int:
        return super().__hash__()


class Singleton:
    @classmethod
    def default(cls, default_T):
        return lambda: Singleton_SingletonVal(InitState.default()(), default_T())
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_SingletonVal(self) -> bool:
        return isinstance(self, Singleton_SingletonVal)

class Singleton_SingletonVal(Singleton, NamedTuple('SingletonVal', [('state', Any), ('value', Any)])):
    def __dafnystr__(self) -> str:
        return f'Singletons.Singleton.SingletonVal({_dafny.string_of(self.state)}, {_dafny.string_of(self.value)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, Singleton_SingletonVal) and self.state == __o.state and self.value == __o.value
    def __hash__(self) -> int:
        return super().__hash__()


class ContainerID:
    def  __init__(self):
        self.s: Singleton = Singleton.default(_dafny.Seq)()
        pass

    def __dafnystr__(self) -> str:
        return "Singletons.ContainerID"
    def ctor__(self):
        (self).s = Singleton_SingletonVal(InitState_Unset(), _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "")))

    def Init(self, v):
        (self).s = Singleton_SingletonVal(InitState_Set(), v)

    def Get(self):
        if ((self.s).state) == (InitState_Set()):
            return Types.Option_Some((self.s).value)
        elif True:
            return Types.Option_None()


class ExternalEnv:
    def  __init__(self):
        self.s: Singleton = Singleton.default(_dafny.Seq)()
        pass

    def __dafnystr__(self) -> str:
        return "Singletons.ExternalEnv"
    def ctor__(self):
        (self).s = Singleton_SingletonVal(InitState_Unset(), _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "")))

    def Init(self, raw):
        (self).s = Singleton_SingletonVal(InitState_Set(), default__.SanitizeExternalEnv(raw))

    def Get(self):
        if ((self.s).state) == (InitState_Set()):
            return (self.s).value
        elif True:
            return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, ""))

