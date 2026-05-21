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

# Module: Sender

class default__:
    def  __init__(self):
        pass

    @staticmethod
    def FirstIndexOf(s, x):
        d_0___accumulator_ = 0
        while True:
            with _dafny.label():
                if ((s)[0]) == (x):
                    return (0) + (d_0___accumulator_)
                elif True:
                    d_0___accumulator_ = (d_0___accumulator_) + (1)
                    in0_ = _dafny.SeqWithoutIsStrInference((s)[1::])
                    in1_ = x
                    s = in0_
                    x = in1_
                    raise _dafny.TailCall()
                break


class SenderState:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [SenderState_Running(), SenderState_Stopped()]
    @classmethod
    def default(cls, ):
        return lambda: SenderState_Running()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_Running(self) -> bool:
        return isinstance(self, SenderState_Running)
    @property
    def is_Stopped(self) -> bool:
        return isinstance(self, SenderState_Stopped)

class SenderState_Running(SenderState, NamedTuple('Running', [])):
    def __dafnystr__(self) -> str:
        return f'Sender.SenderState.Running'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, SenderState_Running)
    def __hash__(self) -> int:
        return super().__hash__()

class SenderState_Stopped(SenderState, NamedTuple('Stopped', [])):
    def __dafnystr__(self) -> str:
        return f'Sender.SenderState.Stopped'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, SenderState_Stopped)
    def __hash__(self) -> int:
        return super().__hash__()


class Telemetry:
    @classmethod
    def default(cls, ):
        return lambda: Telemetry_Telemetry(int(0), int(0), int(0), int(0), int(0), int(0))
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_Telemetry(self) -> bool:
        return isinstance(self, Telemetry_Telemetry)

class Telemetry_Telemetry(Telemetry, NamedTuple('Telemetry', [('payloadsSent', Any), ('payloadsDroppedQueueFull', Any), ('payloadsDroppedWriter', Any), ('bytesSent', Any), ('bytesDroppedQueueFull', Any), ('bytesDroppedWriter', Any)])):
    def __dafnystr__(self) -> str:
        return f'Sender.Telemetry.Telemetry({_dafny.string_of(self.payloadsSent)}, {_dafny.string_of(self.payloadsDroppedQueueFull)}, {_dafny.string_of(self.payloadsDroppedWriter)}, {_dafny.string_of(self.bytesSent)}, {_dafny.string_of(self.bytesDroppedQueueFull)}, {_dafny.string_of(self.bytesDroppedWriter)})'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, Telemetry_Telemetry) and self.payloadsSent == __o.payloadsSent and self.payloadsDroppedQueueFull == __o.payloadsDroppedQueueFull and self.payloadsDroppedWriter == __o.payloadsDroppedWriter and self.bytesSent == __o.bytesSent and self.bytesDroppedQueueFull == __o.bytesDroppedQueueFull and self.bytesDroppedWriter == __o.bytesDroppedWriter
    def __hash__(self) -> int:
        return super().__hash__()


class Transport:
    pass
    def Write(self, data):
        pass

    def Close(self):
        pass


class Sender:
    def  __init__(self):
        self.state: SenderState = SenderState.default()()
        self.queue: _dafny.Seq = _dafny.Seq({})
        self.maxQueueSize: int = int(0)
        self.telemetry: Telemetry = Telemetry.default()()
        pass

    def __dafnystr__(self) -> str:
        return "Sender.Sender"
    def New(self, mqs):
        (self).state = SenderState_Running()
        (self).queue = _dafny.SeqWithoutIsStrInference([])
        (self).maxQueueSize = mqs
        (self).telemetry = Telemetry_Telemetry(0, 0, 0, 0, 0, 0)

    def Enqueue(self, b):
        r: Errors.Result = Errors.Result.default()()
        if (len(self.queue)) < (self.maxQueueSize):
            (self).queue = (self.queue) + (_dafny.SeqWithoutIsStrInference([b]))
            r = Errors.Result_Ok(Buffer.Unit_Unit())
        elif True:
            d_0_dropped_: int
            d_0_dropped_ = b.len_
            d_1_dt__update__tmp_h0_ = self.telemetry
            d_2_dt__update_hbytesDroppedQueueFull_h0_ = ((self.telemetry).bytesDroppedQueueFull) + (d_0_dropped_)
            d_3_dt__update_hpayloadsDroppedQueueFull_h0_ = ((self.telemetry).payloadsDroppedQueueFull) + (1)
            (self).telemetry = Telemetry_Telemetry((d_1_dt__update__tmp_h0_).payloadsSent, d_3_dt__update_hpayloadsDroppedQueueFull_h0_, (d_1_dt__update__tmp_h0_).payloadsDroppedWriter, (d_1_dt__update__tmp_h0_).bytesSent, d_2_dt__update_hbytesDroppedQueueFull_h0_, (d_1_dt__update__tmp_h0_).bytesDroppedWriter)
            r = Errors.Result_Err(Errors.DogStatsDError_ErrorSenderChannelFull())
        return r

    def Send(self, transport):
        r: Errors.Result = Errors.Result.default()()
        d_0_buf_: Buffer.Buffer
        d_0_buf_ = (self.queue)[0]
        (self).queue = _dafny.SeqWithoutIsStrInference((self.queue)[1::])
        d_1_bytes_: _dafny.Seq
        d_1_bytes_ = (d_0_buf_).Bytes()
        d_2_wr_: Errors.Result
        out0_: Errors.Result
        out0_ = (transport).Write(d_1_bytes_)
        d_2_wr_ = out0_
        source0_ = d_2_wr_
        with _dafny.label("match0"):
            if True:
                if source0_.is_Ok:
                    d_3_dt__update__tmp_h0_ = self.telemetry
                    d_4_dt__update_hbytesSent_h0_ = ((self.telemetry).bytesSent) + (len(d_1_bytes_))
                    d_5_dt__update_hpayloadsSent_h0_ = ((self.telemetry).payloadsSent) + (1)
                    (self).telemetry = Telemetry_Telemetry(d_5_dt__update_hpayloadsSent_h0_, (d_3_dt__update__tmp_h0_).payloadsDroppedQueueFull, (d_3_dt__update__tmp_h0_).payloadsDroppedWriter, d_4_dt__update_hbytesSent_h0_, (d_3_dt__update__tmp_h0_).bytesDroppedQueueFull, (d_3_dt__update__tmp_h0_).bytesDroppedWriter)
                    r = Errors.Result_Ok(Buffer.Unit_Unit())
                    raise _dafny.Break("match0")
            if True:
                d_6_e_ = source0_.error
                d_7_dt__update__tmp_h1_ = self.telemetry
                d_8_dt__update_hbytesDroppedWriter_h0_ = ((self.telemetry).bytesDroppedWriter) + (len(d_1_bytes_))
                d_9_dt__update_hpayloadsDroppedWriter_h0_ = ((self.telemetry).payloadsDroppedWriter) + (1)
                (self).telemetry = Telemetry_Telemetry((d_7_dt__update__tmp_h1_).payloadsSent, (d_7_dt__update__tmp_h1_).payloadsDroppedQueueFull, d_9_dt__update_hpayloadsDroppedWriter_h0_, (d_7_dt__update__tmp_h1_).bytesSent, (d_7_dt__update__tmp_h1_).bytesDroppedQueueFull, d_8_dt__update_hbytesDroppedWriter_h0_)
                r = Errors.Result_Err(d_6_e_)
            pass
        return r

    def Stop(self, transport):
        while (len(self.queue)) > (0):
            d_0_prevQueue_: _dafny.Seq
            d_0_prevQueue_ = self.queue
            d_1_buf_: Buffer.Buffer
            d_1_buf_ = (d_0_prevQueue_)[0]
            (self).queue = _dafny.SeqWithoutIsStrInference((d_0_prevQueue_)[1::])
            d_2_bytes_: _dafny.Seq
            d_2_bytes_ = (d_1_buf_).Bytes()
            d_3_wr_: Errors.Result
            out0_: Errors.Result
            out0_ = (transport).Write(d_2_bytes_)
            d_3_wr_ = out0_
            source0_ = d_3_wr_
            with _dafny.label("match0"):
                if True:
                    if source0_.is_Ok:
                        d_4_dt__update__tmp_h0_ = self.telemetry
                        d_5_dt__update_hbytesSent_h0_ = ((self.telemetry).bytesSent) + (len(d_2_bytes_))
                        d_6_dt__update_hpayloadsSent_h0_ = ((self.telemetry).payloadsSent) + (1)
                        (self).telemetry = Telemetry_Telemetry(d_6_dt__update_hpayloadsSent_h0_, (d_4_dt__update__tmp_h0_).payloadsDroppedQueueFull, (d_4_dt__update__tmp_h0_).payloadsDroppedWriter, d_5_dt__update_hbytesSent_h0_, (d_4_dt__update__tmp_h0_).bytesDroppedQueueFull, (d_4_dt__update__tmp_h0_).bytesDroppedWriter)
                        raise _dafny.Break("match0")
                if True:
                    d_7_dt__update__tmp_h1_ = self.telemetry
                    d_8_dt__update_hbytesDroppedWriter_h0_ = ((self.telemetry).bytesDroppedWriter) + (len(d_2_bytes_))
                    d_9_dt__update_hpayloadsDroppedWriter_h0_ = ((self.telemetry).payloadsDroppedWriter) + (1)
                    (self).telemetry = Telemetry_Telemetry((d_7_dt__update__tmp_h1_).payloadsSent, (d_7_dt__update__tmp_h1_).payloadsDroppedQueueFull, d_9_dt__update_hpayloadsDroppedWriter_h0_, (d_7_dt__update__tmp_h1_).bytesSent, (d_7_dt__update__tmp_h1_).bytesDroppedQueueFull, d_8_dt__update_hbytesDroppedWriter_h0_)
                pass
        (transport).Close()
        (self).state = SenderState_Stopped()

