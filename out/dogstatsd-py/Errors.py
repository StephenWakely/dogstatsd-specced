import sys
from typing import Callable, Any, TypeVar, NamedTuple
from math import floor
from itertools import count

import module_ as module_
import _dafny as _dafny
import System_ as System_
import Types as Types

# Module: Errors

class default__:
    def  __init__(self):
        pass

    @staticmethod
    def ErrorMessage(e):
        source0_ = e
        if True:
            if source0_.is_ErrNoClient:
                return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "operation on nil or closed client"))
        if True:
            if source0_.is_ErrorInputChannelFull:
                return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "worker input channel full"))
        if True:
            if source0_.is_ErrorSenderChannelFull:
                return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "sender channel full"))
        if True:
            return _dafny.SeqWithoutIsStrInference(map(_dafny.CodePoint, "metric exceeds max bytes per payload"))


class DogStatsDError:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [DogStatsDError_ErrNoClient(), DogStatsDError_ErrorInputChannelFull(), DogStatsDError_ErrorSenderChannelFull(), DogStatsDError_MessageTooLongError()]
    @classmethod
    def default(cls, ):
        return lambda: DogStatsDError_ErrNoClient()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_ErrNoClient(self) -> bool:
        return isinstance(self, DogStatsDError_ErrNoClient)
    @property
    def is_ErrorInputChannelFull(self) -> bool:
        return isinstance(self, DogStatsDError_ErrorInputChannelFull)
    @property
    def is_ErrorSenderChannelFull(self) -> bool:
        return isinstance(self, DogStatsDError_ErrorSenderChannelFull)
    @property
    def is_MessageTooLongError(self) -> bool:
        return isinstance(self, DogStatsDError_MessageTooLongError)

class DogStatsDError_ErrNoClient(DogStatsDError, NamedTuple('ErrNoClient', [])):
    def __dafnystr__(self) -> str:
        return f'Errors.DogStatsDError.ErrNoClient'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, DogStatsDError_ErrNoClient)
    def __hash__(self) -> int:
        return super().__hash__()

class DogStatsDError_ErrorInputChannelFull(DogStatsDError, NamedTuple('ErrorInputChannelFull', [])):
    def __dafnystr__(self) -> str:
        return f'Errors.DogStatsDError.ErrorInputChannelFull'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, DogStatsDError_ErrorInputChannelFull)
    def __hash__(self) -> int:
        return super().__hash__()

class DogStatsDError_ErrorSenderChannelFull(DogStatsDError, NamedTuple('ErrorSenderChannelFull', [])):
    def __dafnystr__(self) -> str:
        return f'Errors.DogStatsDError.ErrorSenderChannelFull'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, DogStatsDError_ErrorSenderChannelFull)
    def __hash__(self) -> int:
        return super().__hash__()

class DogStatsDError_MessageTooLongError(DogStatsDError, NamedTuple('MessageTooLongError', [])):
    def __dafnystr__(self) -> str:
        return f'Errors.DogStatsDError.MessageTooLongError'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, DogStatsDError_MessageTooLongError)
    def __hash__(self) -> int:
        return super().__hash__()


class Result:
    @classmethod
    def default(cls, ):
        return lambda: Result_Err(DogStatsDError.default()())
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_Ok(self) -> bool:
        return isinstance(self, Result_Ok)
    @property
    def is_Err(self) -> bool:
        return isinstance(self, Result_Err)

class Result_Ok(Result, NamedTuple('Ok', [('value', Any)])):
    def __dafnystr__(self) -> str:
        return f'Errors.Result.Ok({_dafny.string_of(self.value)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, Result_Ok) and self.value == __o.value
    def __hash__(self) -> int:
        return super().__hash__()

class Result_Err(Result, NamedTuple('Err', [('error', Any)])):
    def __dafnystr__(self) -> str:
        return f'Errors.Result.Err({_dafny.string_of(self.error)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, Result_Err) and self.error == __o.error
    def __hash__(self) -> int:
        return super().__hash__()

