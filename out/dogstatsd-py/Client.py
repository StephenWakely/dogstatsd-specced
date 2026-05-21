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
import Singletons as Singletons

# Module: Client


class ClientState:
    @_dafny.classproperty
    def AllSingletonConstructors(cls):
        return [ClientState_Open(), ClientState_Closed()]
    @classmethod
    def default(cls, ):
        return lambda: ClientState_Open()
    def __ne__(self, __o: object) -> bool:
        return not self.__eq__(__o)
    @property
    def is_Open(self) -> bool:
        return isinstance(self, ClientState_Open)
    @property
    def is_Closed(self) -> bool:
        return isinstance(self, ClientState_Closed)

class ClientState_Open(ClientState, NamedTuple('Open', [])):
    def __dafnystr__(self) -> str:
        return f'Client.ClientState.Open'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, ClientState_Open)
    def __hash__(self) -> int:
        return super().__hash__()

class ClientState_Closed(ClientState, NamedTuple('Closed', [])):
    def __dafnystr__(self) -> str:
        return f'Client.ClientState.Closed'
    def __eq__(self, __o: object) -> bool:
        return isinstance(__o, ClientState_Closed)
    def __hash__(self) -> int:
        return super().__hash__()


class NullTransport(Sender.Transport):
    def  __init__(self):
        pass

    def __dafnystr__(self) -> str:
        return "Client.NullTransport"
    def ctor__(self):
        pass
        pass

    def Write(self, data):
        r: Errors.Result = Errors.Result.default()()
        r = Errors.Result_Ok(0)
        return r

    def Close(self):
        pass
        pass


class Client:
    def  __init__(self):
        self.state: ClientState = ClientState.default()()
        self.aggregator: Aggregator.Aggregator = None
        self.sender: Sender.Sender = None
        self.config: Types.DogStatsDConfig = Types.DogStatsDConfig.default()()
        self.containerID: Singletons.ContainerID = None
        self.externalEnv: Singletons.ExternalEnv = None
        pass

    def __dafnystr__(self) -> str:
        return "Client.Client"
    def New(self, cfg):
        d_0_agg_: Aggregator.Aggregator
        nw0_ = Aggregator.Aggregator()
        nw0_.New(4)
        d_0_agg_ = nw0_
        d_1_snd_: Sender.Sender
        nw1_ = Sender.Sender()
        nw1_.New((cfg).senderQueueSize)
        d_1_snd_ = nw1_
        d_2_cid_: Singletons.ContainerID
        nw2_ = Singletons.ContainerID()
        nw2_.ctor__()
        d_2_cid_ = nw2_
        d_3_env_: Singletons.ExternalEnv
        nw3_ = Singletons.ExternalEnv()
        nw3_.ctor__()
        d_3_env_ = nw3_
        (self).config = cfg
        (self).aggregator = d_0_agg_
        (self).sender = d_1_snd_
        (self).containerID = d_2_cid_
        (self).externalEnv = d_3_env_
        (self).state = ClientState_Open()

    def SubmitGauge(self, ctx, value, rate):
        r: Errors.Result = Errors.Result.default()()
        if (self.state) == (ClientState_Closed()):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrNoClient())
            return r
        if (self.config).aggregationEnabled:
            (self.aggregator).SampleGauge(ctx, value)
        r = Errors.Result_Ok(Buffer.Unit_Unit())
        return r

    def SubmitCount(self, ctx, value, rate):
        r: Errors.Result = Errors.Result.default()()
        if (self.state) == (ClientState_Closed()):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrNoClient())
            return r
        if (self.config).aggregationEnabled:
            (self.aggregator).SampleCount(ctx, value)
        r = Errors.Result_Ok(Buffer.Unit_Unit())
        return r

    def SubmitSet(self, ctx, value, rate):
        r: Errors.Result = Errors.Result.default()()
        if (self.state) == (ClientState_Closed()):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrNoClient())
            return r
        if (self.config).aggregationEnabled:
            (self.aggregator).SampleSet(ctx, value)
        r = Errors.Result_Ok(Buffer.Unit_Unit())
        return r

    def SubmitHistogram(self, ctx, value, rate):
        r: Errors.Result = Errors.Result.default()()
        if (self.state) == (ClientState_Closed()):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrNoClient())
            return r
        if (self.config).extendedAggregation:
            (self.aggregator).SampleBuffered(ctx, value, (self.config).maxSamplesPerContext)
        r = Errors.Result_Ok(Buffer.Unit_Unit())
        return r

    def SubmitDistribution(self, ctx, value, rate):
        r: Errors.Result = Errors.Result.default()()
        if (self.state) == (ClientState_Closed()):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrNoClient())
            return r
        if (self.config).extendedAggregation:
            (self.aggregator).SampleBuffered(ctx, value, (self.config).maxSamplesPerContext)
        r = Errors.Result_Ok(Buffer.Unit_Unit())
        return r

    def SubmitTiming(self, ctx, value, rate):
        r: Errors.Result = Errors.Result.default()()
        if (self.state) == (ClientState_Closed()):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrNoClient())
            return r
        if (self.config).extendedAggregation:
            (self.aggregator).SampleBuffered(ctx, value, (self.config).maxSamplesPerContext)
        r = Errors.Result_Ok(Buffer.Unit_Unit())
        return r

    def Flush(self):
        r: Errors.Result = Errors.Result.default()()
        if (self.state) == (ClientState_Closed()):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrNoClient())
            return r
        d_0___v0_: _dafny.Seq
        out0_: _dafny.Seq
        out0_ = (self.aggregator).Flush()
        d_0___v0_ = out0_
        r = Errors.Result_Ok(Buffer.Unit_Unit())
        return r

    def Close(self):
        r: Errors.Result = Errors.Result.default()()
        if (self.state) == (ClientState_Closed()):
            r = Errors.Result_Err(Errors.DogStatsDError_ErrNoClient())
            return r
        d_0___v1_: _dafny.Seq
        out0_: _dafny.Seq
        out0_ = (self.aggregator).Flush()
        d_0___v1_ = out0_
        (self.aggregator).Stop()
        d_1_t_: NullTransport
        nw0_ = NullTransport()
        nw0_.ctor__()
        d_1_t_ = nw0_
        (self.sender).Stop(d_1_t_)
        (self).state = ClientState_Closed()
        r = Errors.Result_Ok(Buffer.Unit_Unit())
        return r

    def IsClosed(self):
        return (self.state) == (ClientState_Closed())

