#![allow(warnings, unconditional_panic)]
#![allow(nonstandard_style)]
#![cfg_attr(any(), rustfmt::skip)]

pub mod _module {
    
}
/// module Aggregator
/// src/Aggregator.dfy(7,1)
pub mod Aggregator {
    pub use ::dafny_runtime::DafnyChar;
    pub use ::dafny_runtime::truncate;
    pub use ::dafny_runtime::euclidian_modulo;
    pub use ::dafny_runtime::int;
    pub use ::dafny_runtime::Sequence;
    pub use ::std::rc::Rc;
    pub use crate::Types::MetricContext;
    pub use ::dafny_runtime::_System::nat;
    pub use crate::WireFormat::WireMetric;
    pub use crate::Types::MetricType;
    pub use ::dafny_runtime::integer_range;
    pub use ::dafny_runtime::DafnyInt;
    pub use ::dafny_runtime::string_of;
    pub use ::dafny_runtime::BigRational;
    pub use ::dafny_runtime::Set;
    pub use ::dafny_runtime::seq;
    pub use ::std::fmt::Debug;
    pub use ::std::fmt::Formatter;
    pub use ::std::fmt::Result;
    pub use ::dafny_runtime::DafnyPrint;
    pub use ::dafny_runtime::SequenceIter;
    pub use ::std::cmp::PartialEq;
    pub use ::std::cmp::Eq;
    pub use ::std::hash::Hash;
    pub use ::std::hash::Hasher;
    pub use ::std::convert::AsRef;
    pub use ::dafny_runtime::Object;
    pub use ::dafny_runtime::allocate_object;
    pub use ::dafny_runtime::read_field;
    pub use ::dafny_runtime::rd;
    pub use ::dafny_runtime::update_field_mut_uninit_object;
    pub use ::dafny_runtime::Map;
    pub use ::dafny_runtime::map;
    pub use ::dafny_runtime::Zero;
    pub use ::dafny_runtime::modify_field;
    pub use ::dafny_runtime::set;
    pub use ::dafny_runtime::MaybePlacebo;
    pub use crate::Types::Option;
    pub use crate::Types::TagCardinality;
    pub use ::dafny_runtime::UpcastObject;
    pub use ::dafny_runtime::DynAny;
    pub use ::dafny_runtime::UpcastObjectFn;

    pub struct _default {}

    impl _default {
        /// src/Aggregator.dfy(36,3)
        pub fn FNV1aStep(h: u32, c: &DafnyChar) -> u32 {
            let mut b: u32 = truncate!(euclidian_modulo(int!(c.clone().0), int!(256)), u32);
            (h ^ b).wrapping_mul(_default::FNV_PRIME_32())
        }
        /// src/Aggregator.dfy(42,3)
        pub fn FNV1aStringAcc(s: &Sequence<DafnyChar>, h: u32) -> u32 {
            let mut _r0 = s.clone();
            let mut _r1 = h;
            'TAIL_CALL_START: loop {
                let s = _r0;
                let h = _r1;
                if s.cardinality() == int!(0) {
                    return h;
                } else {
                    let mut _in0: Sequence<DafnyChar> = s.drop(&int!(1));
                    let mut _in1: u32 = _default::FNV1aStep(h, &s.get(&int!(0)));
                    _r0 = _in0.clone();
                    _r1 = _in1;
                    continue 'TAIL_CALL_START;
                }
            }
        }
        /// src/Aggregator.dfy(49,3)
        pub fn FNV1aTagsAcc(tags: &Sequence<Sequence<DafnyChar>>, h: u32) -> u32 {
            let mut _r0 = tags.clone();
            let mut _r1 = h;
            'TAIL_CALL_START: loop {
                let tags = _r0;
                let h = _r1;
                if tags.cardinality() == int!(0) {
                    return h;
                } else {
                    let mut _in0: Sequence<Sequence<DafnyChar>> = tags.drop(&int!(1));
                    let mut _in1: u32 = _default::FNV1aStringAcc(&tags.get(&int!(0)), h);
                    _r0 = _in0.clone();
                    _r1 = _in1;
                    continue 'TAIL_CALL_START;
                }
            }
        }
        /// src/Aggregator.dfy(56,3)
        pub fn ContextHash(ctx: &Rc<MetricContext>) -> u32 {
            _default::FNV1aTagsAcc(ctx.tags(), _default::FNV1aStringAcc(ctx.name(), _default::FNV_OFFSET_32()))
        }
        /// src/Aggregator.dfy(62,3)
        pub fn ShardIndex(ctx: &Rc<MetricContext>, shardCount: &nat) -> nat {
            euclidian_modulo(int!(_default::ContextHash(ctx)), shardCount.clone())
        }
        /// src/Aggregator.dfy(83,3)
        pub fn AllType(metrics: &Sequence<Rc<WireMetric>>, t: &Rc<MetricType>) -> bool {
            integer_range(int!(0), metrics.cardinality()).all(({
                    let mut t = t.clone();
                    let mut metrics = metrics.clone();
                    Rc::new(move |__forall_var_0: DafnyInt| -> bool{
            let mut k: DafnyInt = __forall_var_0.clone();
            !(int!(0) <= k.clone() && k.clone() < metrics.cardinality()) || metrics.get(&k).metricType().clone() == t.clone()
        }) as Rc<dyn ::std::ops::Fn(_) -> _>
                }).as_ref())
        }
        /// src/Aggregator.dfy(89,3)
        pub fn UniqueWireMetrics(metrics: &Sequence<Rc<WireMetric>>) -> bool {
            integer_range(int!(0), metrics.cardinality()).all(({
                    let mut metrics = metrics.clone();
                    Rc::new(move |__forall_var_0: DafnyInt| -> bool{
            let mut i: DafnyInt = __forall_var_0.clone();
            integer_range(i.clone() + int!(1), metrics.cardinality()).all(({
                    let mut i = i.clone();
                    let mut metrics = metrics.clone();
                    Rc::new(move |__forall_var_1: DafnyInt| -> bool{
            let mut j: DafnyInt = __forall_var_1.clone();
            !(int!(0) <= i.clone() && i.clone() < j.clone() && j.clone() < metrics.cardinality()) || !(metrics.get(&i).name().clone() == metrics.get(&j).name().clone() && metrics.get(&i).tags().clone() == metrics.get(&j).tags().clone() && metrics.get(&i).metricType().clone() == metrics.get(&j).metricType().clone())
        }) as Rc<dyn ::std::ops::Fn(_) -> _>
                }).as_ref())
        }) as Rc<dyn ::std::ops::Fn(_) -> _>
                }).as_ref())
        }
        /// src/Aggregator.dfy(178,3)
        pub fn IntToString(n: &DafnyInt) -> Sequence<DafnyChar> {
            string_of("")
        }
        /// src/Aggregator.dfy(180,3)
        pub fn RealToString(r: &BigRational) -> Sequence<DafnyChar> {
            string_of("")
        }
        /// src/Aggregator.dfy(187,3)
        pub fn PickContextFromSet(s: &Set<Rc<MetricContext>>) -> Rc<MetricContext> {
            Rc::new(MetricContext::MetricContext {
                    name: string_of(""),
                    tags: seq![] as Sequence<Sequence<DafnyChar>>
                })
        }
        /// src/Aggregator.dfy(32,3)
        pub fn FNV_PRIME_32() -> u32 {
            16777619 as u32
        }
        /// src/Aggregator.dfy(33,3)
        pub fn FNV_OFFSET_32() -> u32 {
            2166136261 as u32
        }
    }

    /// src/Aggregator.dfy(13,3)
    #[derive(Clone)]
    pub enum AggregatorState {
        Running {},
        Stopped {}
    }

    impl AggregatorState {}

    impl Debug
        for AggregatorState {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for AggregatorState {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                AggregatorState::Running{} => {
                    write!(_formatter, "Aggregator.AggregatorState.Running")?;
                    Ok(())
                },
                AggregatorState::Stopped{} => {
                    write!(_formatter, "Aggregator.AggregatorState.Stopped")?;
                    Ok(())
                },
            }
        }
    }

    impl AggregatorState {
        /// Enumerates all possible values of AggregatorState
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<AggregatorState>> {
            seq![Rc::new(AggregatorState::Running {}), Rc::new(AggregatorState::Stopped {})].iter()
        }
    }

    impl PartialEq
        for AggregatorState {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (AggregatorState::Running{}, AggregatorState::Running{}) => {
                    true
                },
                (AggregatorState::Stopped{}, AggregatorState::Stopped{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for AggregatorState {}

    impl Hash
        for AggregatorState {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                AggregatorState::Running{} => {
                    
                },
                AggregatorState::Stopped{} => {
                    
                },
            }
        }
    }

    impl AsRef<AggregatorState>
        for AggregatorState {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Aggregator.dfy(25,3)
    #[derive(Clone)]
    pub enum BufferedMetricState {
        BufferedMetricState {
            samples: Sequence<BigRational>,
            totalSamples: nat
        }
    }

    impl BufferedMetricState {
        /// Returns a borrow of the field samples
        pub fn samples(&self) -> &Sequence<BigRational> {
            match self {
                BufferedMetricState::BufferedMetricState{samples, totalSamples, } => samples,
            }
        }
        /// Returns a borrow of the field totalSamples
        pub fn totalSamples(&self) -> &nat {
            match self {
                BufferedMetricState::BufferedMetricState{samples, totalSamples, } => totalSamples,
            }
        }
    }

    impl Debug
        for BufferedMetricState {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for BufferedMetricState {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                BufferedMetricState::BufferedMetricState{samples, totalSamples, } => {
                    write!(_formatter, "Aggregator.BufferedMetricState.BufferedMetricState(")?;
                    DafnyPrint::fmt_print(samples, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(totalSamples, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
            }
        }
    }

    impl PartialEq
        for BufferedMetricState {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (BufferedMetricState::BufferedMetricState{samples, totalSamples, }, BufferedMetricState::BufferedMetricState{samples: _2_samples, totalSamples: _2_totalSamples, }) => {
                    samples == _2_samples && totalSamples == _2_totalSamples
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for BufferedMetricState {}

    impl Hash
        for BufferedMetricState {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                BufferedMetricState::BufferedMetricState{samples, totalSamples, } => {
                    Hash::hash(samples, _state);
                    Hash::hash(totalSamples, _state)
                },
            }
        }
    }

    impl AsRef<BufferedMetricState>
        for BufferedMetricState {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// class Aggregator
    /// src/Aggregator.dfy(194,3)
    pub struct Aggregator {
        pub state: ::dafny_runtime::Field<Rc<AggregatorState>>,
        pub countShards: ::dafny_runtime::Field<Sequence<Map<Rc<MetricContext>, DafnyInt>>>,
        pub gaugeShards: ::dafny_runtime::Field<Sequence<Map<Rc<MetricContext>, BigRational>>>,
        pub setShards: ::dafny_runtime::Field<Sequence<Map<Rc<MetricContext>, Set<Sequence<DafnyChar>>>>>,
        pub buffered: ::dafny_runtime::Field<Map<Rc<MetricContext>, Rc<BufferedMetricState>>>,
        pub shardCount: ::dafny_runtime::Field<nat>
    }

    impl Aggregator {
        /// Allocates an UNINITIALIZED instance. Only the Dafny compiler should use that.
        pub fn _allocate_object() -> Object<Self> {
            allocate_object::<Self>()
        }
        /// src/Aggregator.dfy(204,5)
        pub fn Valid(&self) -> bool {
            int!(0) < read_field!(self.shardCount) && read_field!(self.countShards).cardinality() == read_field!(self.shardCount) && read_field!(self.gaugeShards).cardinality() == read_field!(self.shardCount) && read_field!(self.setShards).cardinality() == read_field!(self.shardCount) && integer_range(int!(0), read_field!(self.shardCount)).all(({
                    let mut _this = Object::<_>::from_ref(self);
                    Rc::new(move |__forall_var_0: DafnyInt| -> bool{
            let mut s: DafnyInt = __forall_var_0.clone();
            !(int!(0) <= s.clone() && s.clone() < read_field!(rd!(_this.clone()).shardCount)) || (&read_field!(rd!(_this.clone()).countShards).get(&s)).keys().iter().all(({
                    let mut s = s.clone();
                    let mut _this = self.clone();
                    Rc::new(move |__forall_var_1: &Rc<MetricContext>| -> bool{
            let mut ctx: Rc<MetricContext> = __forall_var_1.clone();
            !read_field!(rd!(_this.clone()).countShards).get(&s).contains(&ctx) || read_field!(rd!(_this.clone()).countShards).get(&s).get(&ctx) >= int!(0)
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                }).as_ref())
        }) as Rc<dyn ::std::ops::Fn(_) -> _>
                }).as_ref()) && integer_range(int!(0), read_field!(self.shardCount)).all(({
                    let mut _this = Object::<_>::from_ref(self);
                    Rc::new(move |__forall_var_2: DafnyInt| -> bool{
            let mut s: DafnyInt = __forall_var_2.clone();
            !(int!(0) <= s.clone() && s.clone() < read_field!(rd!(_this.clone()).shardCount)) || (&read_field!(rd!(_this.clone()).countShards).get(&s)).keys().iter().all(({
                    let mut s = s.clone();
                    let mut _this = self.clone();
                    Rc::new(move |__forall_var_3: &Rc<MetricContext>| -> bool{
            let mut ctx: Rc<MetricContext> = __forall_var_3.clone();
            !read_field!(rd!(_this.clone()).countShards).get(&s).contains(&ctx) || _default::ShardIndex(&ctx, &read_field!(rd!(_this.clone()).shardCount)) == s.clone()
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                }).as_ref())
        }) as Rc<dyn ::std::ops::Fn(_) -> _>
                }).as_ref()) && integer_range(int!(0), read_field!(self.shardCount)).all(({
                    let mut _this = Object::<_>::from_ref(self);
                    Rc::new(move |__forall_var_4: DafnyInt| -> bool{
            let mut s: DafnyInt = __forall_var_4.clone();
            !(int!(0) <= s.clone() && s.clone() < read_field!(rd!(_this.clone()).shardCount)) || (&read_field!(rd!(_this.clone()).gaugeShards).get(&s)).keys().iter().all(({
                    let mut s = s.clone();
                    let mut _this = self.clone();
                    Rc::new(move |__forall_var_5: &Rc<MetricContext>| -> bool{
            let mut ctx: Rc<MetricContext> = __forall_var_5.clone();
            !read_field!(rd!(_this.clone()).gaugeShards).get(&s).contains(&ctx) || _default::ShardIndex(&ctx, &read_field!(rd!(_this.clone()).shardCount)) == s.clone()
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                }).as_ref())
        }) as Rc<dyn ::std::ops::Fn(_) -> _>
                }).as_ref()) && integer_range(int!(0), read_field!(self.shardCount)).all(({
                    let mut _this = Object::<_>::from_ref(self);
                    Rc::new(move |__forall_var_6: DafnyInt| -> bool{
            let mut s: DafnyInt = __forall_var_6.clone();
            !(int!(0) <= s.clone() && s.clone() < read_field!(rd!(_this.clone()).shardCount)) || (&read_field!(rd!(_this.clone()).setShards).get(&s)).keys().iter().all(({
                    let mut s = s.clone();
                    let mut _this = self.clone();
                    Rc::new(move |__forall_var_7: &Rc<MetricContext>| -> bool{
            let mut ctx: Rc<MetricContext> = __forall_var_7.clone();
            !read_field!(rd!(_this.clone()).setShards).get(&s).contains(&ctx) || _default::ShardIndex(&ctx, &read_field!(rd!(_this.clone()).shardCount)) == s.clone()
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                }).as_ref())
        }) as Rc<dyn ::std::ops::Fn(_) -> _>
                }).as_ref())
        }
        /// src/Aggregator.dfy(223,5)
        pub fn New(this: &Object<Aggregator>, n: &nat) -> () {
            let mut _set_state: bool = false;
            let mut _set_countShards: bool = false;
            let mut _set_gaugeShards: bool = false;
            let mut _set_setShards: bool = false;
            let mut _set_buffered: bool = false;
            let mut _set_shardCount: bool = false;
            update_field_mut_uninit_object!(this.clone(), state, _set_state, Rc::new(AggregatorState::Running {}));
            update_field_mut_uninit_object!(this.clone(), shardCount, _set_shardCount, n.clone());
            update_field_mut_uninit_object!(this.clone(), countShards, _set_countShards, {
                    let _initializer = {
                            Rc::new(move |_v0: &DafnyInt| -> Map<Rc<MetricContext>, DafnyInt>{
            map![] as Map<Rc<MetricContext>, DafnyInt>
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                        };
                    integer_range(Zero::zero(), n.clone()).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                });
            update_field_mut_uninit_object!(this.clone(), gaugeShards, _set_gaugeShards, {
                    let _initializer = {
                            Rc::new(move |_v1: &DafnyInt| -> Map<Rc<MetricContext>, BigRational>{
            map![] as Map<Rc<MetricContext>, BigRational>
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                        };
                    integer_range(Zero::zero(), n.clone()).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                });
            update_field_mut_uninit_object!(this.clone(), setShards, _set_setShards, {
                    let _initializer = {
                            Rc::new(move |_v2: &DafnyInt| -> Map<Rc<MetricContext>, Set<Sequence<DafnyChar>>>{
            map![] as Map<Rc<MetricContext>, Set<Sequence<DafnyChar>>>
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                        };
                    integer_range(Zero::zero(), n.clone()).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                });
            update_field_mut_uninit_object!(this.clone(), buffered, _set_buffered, map![] as Map<Rc<MetricContext>, Rc<BufferedMetricState>>);
            return ();
        }
        /// src/Aggregator.dfy(247,5)
        pub fn SampleCount(&self, ctx: &Rc<MetricContext>, value: &nat) -> () {
            let mut s: nat = _default::ShardIndex(ctx, &read_field!(self.shardCount));
            let mut prev: DafnyInt;
            if read_field!(self.countShards).get(&s).contains(ctx) {
                prev = read_field!(self.countShards).get(&s).get(ctx);
            } else {
                prev = int!(0);
            };
            modify_field!(self.countShards, read_field!(self.countShards).update_index(&s, &read_field!(self.countShards).get(&s).update_index(ctx, &(prev.clone() + value.clone()))));
            return ();
        }
        /// src/Aggregator.dfy(279,5)
        pub fn SampleGauge(&self, ctx: &Rc<MetricContext>, value: &BigRational) -> () {
            let mut s: nat = _default::ShardIndex(ctx, &read_field!(self.shardCount));
            modify_field!(self.gaugeShards, read_field!(self.gaugeShards).update_index(&s, &read_field!(self.gaugeShards).get(&s).update_index(ctx, value)));
            return ();
        }
        /// src/Aggregator.dfy(306,5)
        pub fn SampleSet(&self, ctx: &Rc<MetricContext>, value: &Sequence<DafnyChar>) -> () {
            let mut s: nat = _default::ShardIndex(ctx, &read_field!(self.shardCount));
            let mut oldSet: Set<Sequence<DafnyChar>>;
            if read_field!(self.setShards).get(&s).contains(ctx) {
                oldSet = read_field!(self.setShards).get(&s).get(ctx);
            } else {
                oldSet = set!{};
            };
            modify_field!(self.setShards, read_field!(self.setShards).update_index(&s, &read_field!(self.setShards).get(&s).update_index(ctx, &oldSet.merge(&set!{value.clone()}))));
            return ();
        }
        /// src/Aggregator.dfy(338,5)
        pub fn SampleBuffered(&self, ctx: &Rc<MetricContext>, value: &BigRational, maxSamples: &DafnyInt) -> () {
            let mut oldState: Rc<BufferedMetricState>;
            if read_field!(self.buffered).contains(ctx) {
                oldState = read_field!(self.buffered).get(ctx);
            } else {
                oldState = Rc::new(BufferedMetricState::BufferedMetricState {
                            samples: seq![] as Sequence<BigRational>,
                            totalSamples: int!(0)
                        });
            };
            let mut newSamples: Sequence<BigRational>;
            if int!(0) < maxSamples.clone() && oldState.samples().cardinality() < maxSamples.clone() {
                newSamples = oldState.samples().concat(&seq![value.clone()]);
            } else {
                newSamples = oldState.samples().clone();
            };
            modify_field!(self.buffered, read_field!(self.buffered).update_index(ctx, &Rc::new(BufferedMetricState::BufferedMetricState {
                            samples: newSamples.clone(),
                            totalSamples: oldState.totalSamples().clone() + int!(1)
                        })));
            return ();
        }
        /// src/Aggregator.dfy(378,5)
        pub fn Flush(&self) -> Sequence<Rc<WireMetric>> {
            let mut result = MaybePlacebo::<Sequence<Rc<WireMetric>>>::new();
            let mut countResult: Sequence<Rc<WireMetric>>;
            let mut _out0: Sequence<Rc<WireMetric>> = self.CollectCountMetrics();
            countResult = _out0.clone();
            let mut gaugeResult: Sequence<Rc<WireMetric>>;
            let mut _out1: Sequence<Rc<WireMetric>> = self.CollectGaugeMetrics();
            gaugeResult = _out1.clone();
            let mut setResult: Sequence<Rc<WireMetric>>;
            let mut _out2: Sequence<Rc<WireMetric>> = self.CollectSetMetrics();
            setResult = _out2.clone();
            let mut bufferedResult: Sequence<Rc<WireMetric>>;
            let mut _out3: Sequence<Rc<WireMetric>> = self.CollectBufferedMetrics();
            bufferedResult = _out3.clone();
            modify_field!(self.countShards, {
                    let _initializer = {
                            Rc::new(move |_v3: &DafnyInt| -> Map<Rc<MetricContext>, DafnyInt>{
            map![] as Map<Rc<MetricContext>, DafnyInt>
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                        };
                    integer_range(Zero::zero(), read_field!(self.shardCount)).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                });
            modify_field!(self.gaugeShards, {
                    let _initializer = {
                            Rc::new(move |_v4: &DafnyInt| -> Map<Rc<MetricContext>, BigRational>{
            map![] as Map<Rc<MetricContext>, BigRational>
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                        };
                    integer_range(Zero::zero(), read_field!(self.shardCount)).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                });
            modify_field!(self.setShards, {
                    let _initializer = {
                            Rc::new(move |_v5: &DafnyInt| -> Map<Rc<MetricContext>, Set<Sequence<DafnyChar>>>{
            map![] as Map<Rc<MetricContext>, Set<Sequence<DafnyChar>>>
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                        };
                    integer_range(Zero::zero(), read_field!(self.shardCount)).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                });
            modify_field!(self.buffered, map![] as Map<Rc<MetricContext>, Rc<BufferedMetricState>>);
            let mut cg: Sequence<Rc<WireMetric>> = countResult.concat(&gaugeResult);
            let mut cgs: Sequence<Rc<WireMetric>> = cg.concat(&setResult);
            result = MaybePlacebo::from(cgs.concat(&bufferedResult));
            return result.read();
        }
        /// src/Aggregator.dfy(435,5)
        pub fn CollectCountMetrics(&self) -> Sequence<Rc<WireMetric>> {
            let mut r: Sequence<Rc<WireMetric>> = seq![] as Sequence<Rc<WireMetric>>;
            let mut si: DafnyInt = int!(0);
            while si.clone() < read_field!(self.shardCount) {
                let mut shard: Map<Rc<MetricContext>, DafnyInt> = read_field!(self.countShards).get(&si);
                let mut remaining: Set<Rc<MetricContext>> = shard.keys();
                while remaining.clone() != set!{} {
                    let mut ctx: Rc<MetricContext> = _default::PickContextFromSet(&remaining);
                    let mut v: DafnyInt = shard.get(&ctx);
                    if v.clone() != int!(0) {
                        let mut m: Rc<WireMetric> = Rc::new(WireMetric::WireMetric {
                                    name: ctx.name().clone(),
                                    value: _default::IntToString(&v),
                                    metricType: Rc::new(MetricType::Count {}),
                                    rate: Rc::new(Option::None::<BigRational> {}),
                                    tags: ctx.tags().clone(),
                                    containerID: Rc::new(Option::None::<Sequence<DafnyChar>> {}),
                                    externalEnv: Rc::new(Option::None::<Sequence<DafnyChar>> {}),
                                    cardinality: Rc::new(TagCardinality::CardinalityNotSet {})
                                });
                        r = r.concat(&seq![m.clone()]);
                    };
                    remaining = remaining.subtract(&set!{ctx.clone()});
                };
                si = si.clone() + int!(1);
            };
            return r.clone();
        }
        /// src/Aggregator.dfy(520,5)
        pub fn CollectGaugeMetrics(&self) -> Sequence<Rc<WireMetric>> {
            let mut r: Sequence<Rc<WireMetric>> = seq![] as Sequence<Rc<WireMetric>>;
            let mut si: DafnyInt = int!(0);
            while si.clone() < read_field!(self.shardCount) {
                let mut shard: Map<Rc<MetricContext>, BigRational> = read_field!(self.gaugeShards).get(&si);
                let mut remaining: Set<Rc<MetricContext>> = shard.keys();
                while remaining.clone() != set!{} {
                    let mut ctx: Rc<MetricContext> = _default::PickContextFromSet(&remaining);
                    let mut v: BigRational = shard.get(&ctx);
                    let mut m: Rc<WireMetric> = Rc::new(WireMetric::WireMetric {
                                name: ctx.name().clone(),
                                value: _default::RealToString(&v),
                                metricType: Rc::new(MetricType::Gauge {}),
                                rate: Rc::new(Option::None::<BigRational> {}),
                                tags: ctx.tags().clone(),
                                containerID: Rc::new(Option::None::<Sequence<DafnyChar>> {}),
                                externalEnv: Rc::new(Option::None::<Sequence<DafnyChar>> {}),
                                cardinality: Rc::new(TagCardinality::CardinalityNotSet {})
                            });
                    r = r.concat(&seq![m.clone()]);
                    remaining = remaining.subtract(&set!{ctx.clone()});
                };
                si = si.clone() + int!(1);
            };
            return r.clone();
        }
        /// src/Aggregator.dfy(593,5)
        pub fn CollectSetMetrics(&self) -> Sequence<Rc<WireMetric>> {
            let mut r: Sequence<Rc<WireMetric>> = seq![] as Sequence<Rc<WireMetric>>;
            let mut si: DafnyInt = int!(0);
            while si.clone() < read_field!(self.shardCount) {
                let mut shard: Map<Rc<MetricContext>, Set<Sequence<DafnyChar>>> = read_field!(self.setShards).get(&si);
                let mut remaining: Set<Rc<MetricContext>> = shard.keys();
                while remaining.clone() != set!{} {
                    let mut ctx: Rc<MetricContext> = _default::PickContextFromSet(&remaining);
                    let mut v: Set<Sequence<DafnyChar>> = shard.get(&ctx);
                    if v.clone() != set!{} {
                        let mut m: Rc<WireMetric> = Rc::new(WireMetric::WireMetric {
                                    name: ctx.name().clone(),
                                    value: _default::IntToString(&v.cardinality()),
                                    metricType: Rc::new(MetricType::Set {}),
                                    rate: Rc::new(Option::None::<BigRational> {}),
                                    tags: ctx.tags().clone(),
                                    containerID: Rc::new(Option::None::<Sequence<DafnyChar>> {}),
                                    externalEnv: Rc::new(Option::None::<Sequence<DafnyChar>> {}),
                                    cardinality: Rc::new(TagCardinality::CardinalityNotSet {})
                                });
                        r = r.concat(&seq![m.clone()]);
                    };
                    remaining = remaining.subtract(&set!{ctx.clone()});
                };
                si = si.clone() + int!(1);
            };
            return r.clone();
        }
        /// src/Aggregator.dfy(668,5)
        pub fn CollectBufferedMetrics(&self) -> Sequence<Rc<WireMetric>> {
            let mut r: Sequence<Rc<WireMetric>> = seq![] as Sequence<Rc<WireMetric>>;
            let mut remaining: Set<Rc<MetricContext>> = read_field!(self.buffered).keys();
            while remaining.clone() != set!{} {
                let mut ctx: Rc<MetricContext> = _default::PickContextFromSet(&remaining);
                let mut bs: Rc<BufferedMetricState> = read_field!(self.buffered).get(&ctx);
                let mut cnt: nat = bs.totalSamples().clone();
                let mut m: Rc<WireMetric> = Rc::new(WireMetric::WireMetric {
                            name: ctx.name().clone(),
                            value: _default::IntToString(&cnt),
                            metricType: Rc::new(MetricType::Histogram {}),
                            rate: Rc::new(Option::None::<BigRational> {}),
                            tags: ctx.tags().clone(),
                            containerID: Rc::new(Option::None::<Sequence<DafnyChar>> {}),
                            externalEnv: Rc::new(Option::None::<Sequence<DafnyChar>> {}),
                            cardinality: Rc::new(TagCardinality::CardinalityNotSet {})
                        });
                r = r.concat(&seq![m.clone()]);
                remaining = remaining.subtract(&set!{ctx.clone()});
            };
            return r.clone();
        }
        /// src/Aggregator.dfy(709,5)
        pub fn Stop(&self) -> () {
            modify_field!(self.state, Rc::new(AggregatorState::Stopped {}));
            return ();
        }
    }

    impl UpcastObject<DynAny>
        for Aggregator {
        UpcastObjectFn!(DynAny);
    }
}
/// src/Buffer.dfy(6,1)
pub mod Buffer {
    pub use ::std::fmt::Debug;
    pub use ::std::fmt::Formatter;
    pub use ::dafny_runtime::DafnyPrint;
    pub use ::dafny_runtime::SequenceIter;
    pub use ::std::rc::Rc;
    pub use ::dafny_runtime::seq;
    pub use ::std::cmp::PartialEq;
    pub use ::std::cmp::Eq;
    pub use ::std::hash::Hash;
    pub use ::std::hash::Hasher;
    pub use ::std::convert::AsRef;
    pub use ::dafny_runtime::Object;
    pub use ::dafny_runtime::allocate_object;
    pub use ::dafny_runtime::read_field;
    pub use ::dafny_runtime::_System::nat;
    pub use ::dafny_runtime::update_field_mut_uninit_object;
    pub use ::dafny_runtime::DafnyInt;
    pub use ::dafny_runtime::integer_range;
    pub use ::dafny_runtime::Zero;
    pub use ::dafny_runtime::Sequence;
    pub use ::dafny_runtime::int;
    pub use ::dafny_runtime::MaybePlacebo;
    pub use crate::Errors::DogStatsDError;
    pub use ::dafny_runtime::modify_field;
    pub use ::dafny_runtime::UpcastObject;
    pub use ::dafny_runtime::DynAny;
    pub use ::dafny_runtime::UpcastObjectFn;

    /// src/Buffer.dfy(12,3)
    #[derive(Clone)]
    pub enum Unit {
        Unit {}
    }

    impl Unit {}

    impl Debug
        for Unit {
        fn fmt(&self, f: &mut Formatter) -> ::std::fmt::Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for Unit {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                Unit::Unit{} => {
                    write!(_formatter, "Buffer.Unit.Unit")?;
                    Ok(())
                },
            }
        }
    }

    impl Unit {
        /// Enumerates all possible values of Unit
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<Unit>> {
            seq![Rc::new(Unit::Unit {})].iter()
        }
    }

    impl PartialEq
        for Unit {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (Unit::Unit{}, Unit::Unit{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for Unit {}

    impl Hash
        for Unit {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                Unit::Unit{} => {
                    
                },
            }
        }
    }

    impl AsRef<Unit>
        for Unit {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Buffer.dfy(15,3)
    pub struct Buffer {
        pub data: ::dafny_runtime::Field<Sequence<u8>>,
        pub len: ::dafny_runtime::Field<nat>,
        pub maxSize: ::dafny_runtime::Field<nat>,
        pub elementCount: ::dafny_runtime::Field<nat>,
        pub maxElements: ::dafny_runtime::Field<nat>
    }

    impl Buffer {
        /// Allocates an UNINITIALIZED instance. Only the Dafny compiler should use that.
        pub fn _allocate_object() -> Object<Self> {
            allocate_object::<Self>()
        }
        /// src/Buffer.dfy(23,5)
        pub fn Valid(&self) -> bool {
            read_field!(self.len) <= read_field!(self.maxSize) && read_field!(self.elementCount) <= read_field!(self.maxElements) && read_field!(self.data).cardinality() == read_field!(self.maxSize)
        }
        /// src/Buffer.dfy(32,5)
        pub fn New(this: &Object<Buffer>, ms: &nat, me: &nat) -> () {
            let mut _set_data: bool = false;
            let mut _set_len: bool = false;
            let mut _set_maxSize: bool = false;
            let mut _set_elementCount: bool = false;
            let mut _set_maxElements: bool = false;
            update_field_mut_uninit_object!(this.clone(), maxSize, _set_maxSize, ms.clone());
            update_field_mut_uninit_object!(this.clone(), maxElements, _set_maxElements, me.clone());
            update_field_mut_uninit_object!(this.clone(), data, _set_data, {
                    let _initializer = {
                            Rc::new(move |_v0: &DafnyInt| -> u8{
            0
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                        };
                    integer_range(Zero::zero(), ms.clone()).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                });
            update_field_mut_uninit_object!(this.clone(), len, _set_len, int!(0));
            update_field_mut_uninit_object!(this.clone(), elementCount, _set_elementCount, int!(0));
            return ();
        }
        /// src/Buffer.dfy(45,5)
        pub fn WriteMetric(&self, metric: &Sequence<u8>) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            let mut metricLen: nat = metric.cardinality();
            if read_field!(self.maxSize) < read_field!(self.len) + metricLen.clone() || read_field!(self.elementCount) >= read_field!(self.maxElements) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrorSenderChannelFull {})
                            }));
                return r.read();
            };
            let mut newLen: nat = read_field!(self.len) + metricLen.clone();
            let mut remaining: nat = read_field!(self.maxSize) - newLen.clone();
            modify_field!(self.data, read_field!(self.data).take(&read_field!(self.len)).concat(metric).concat(&({
                        let _initializer = {
                                Rc::new(move |_v1: &DafnyInt| -> u8{
            0
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                            };
                        integer_range(Zero::zero(), remaining.clone()).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                    })));
            modify_field!(self.len, newLen.clone());
            modify_field!(self.elementCount, read_field!(self.elementCount) + int!(1));
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Buffer.dfy(70,5)
        pub fn Reset(&self) -> () {
            modify_field!(self.data, {
                    let _initializer = {
                            Rc::new(move |_v2: &DafnyInt| -> u8{
            0
        }) as Rc<dyn ::std::ops::Fn(&_) -> _>
                        };
                    integer_range(Zero::zero(), read_field!(self.maxSize)).map(move |i| _initializer(&i)).collect::<Sequence<_>>()
                });
            modify_field!(self.len, int!(0));
            modify_field!(self.elementCount, int!(0));
            return ();
        }
        /// src/Buffer.dfy(82,5)
        pub fn IsEmpty(&self) -> bool {
            read_field!(self.len) == int!(0)
        }
        /// src/Buffer.dfy(89,5)
        pub fn Bytes(&self) -> Sequence<u8> {
            read_field!(self.data).take(&read_field!(self.len))
        }
    }

    impl UpcastObject<DynAny>
        for Buffer {
        UpcastObjectFn!(DynAny);
    }
}
/// module Client
/// src/Client.dfy(10,1)
pub mod Client {
    pub use ::std::fmt::Debug;
    pub use ::std::fmt::Formatter;
    pub use ::dafny_runtime::DafnyPrint;
    pub use ::dafny_runtime::SequenceIter;
    pub use ::std::rc::Rc;
    pub use ::dafny_runtime::seq;
    pub use ::std::cmp::PartialEq;
    pub use ::std::cmp::Eq;
    pub use ::std::hash::Hash;
    pub use ::std::hash::Hasher;
    pub use ::std::convert::AsRef;
    pub use ::dafny_runtime::Object;
    pub use ::dafny_runtime::allocate_object;
    pub use ::dafny_runtime::UpcastObject;
    pub use ::dafny_runtime::DynAny;
    pub use ::dafny_runtime::UpcastObjectFn;
    pub use crate::Sender::Transport;
    pub use ::dafny_runtime::Sequence;
    pub use ::dafny_runtime::_System::nat;
    pub use ::dafny_runtime::int;
    pub use crate::Types::DogStatsDConfig;
    pub use crate::Aggregator::Aggregator;
    pub use crate::Sender::Sender;
    pub use crate::Singletons::ContainerID;
    pub use crate::Singletons::ExternalEnv;
    pub use ::dafny_runtime::update_field_mut_uninit_object;
    pub use crate::Types::MetricContext;
    pub use ::dafny_runtime::BigRational;
    pub use crate::Buffer::Unit;
    pub use ::dafny_runtime::MaybePlacebo;
    pub use ::dafny_runtime::read_field;
    pub use crate::Errors::DogStatsDError;
    pub use ::dafny_runtime::rd;
    pub use ::dafny_runtime::DafnyChar;
    pub use crate::WireFormat::WireMetric;
    pub use ::dafny_runtime::upcast_object;
    pub use ::dafny_runtime::modify_field;

    /// src/Client.dfy(19,3)
    #[derive(Clone)]
    pub enum ClientState {
        Open {},
        Closed {}
    }

    impl ClientState {}

    impl Debug
        for ClientState {
        fn fmt(&self, f: &mut Formatter) -> ::std::fmt::Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for ClientState {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                ClientState::Open{} => {
                    write!(_formatter, "Client.ClientState.Open")?;
                    Ok(())
                },
                ClientState::Closed{} => {
                    write!(_formatter, "Client.ClientState.Closed")?;
                    Ok(())
                },
            }
        }
    }

    impl ClientState {
        /// Enumerates all possible values of ClientState
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<ClientState>> {
            seq![Rc::new(ClientState::Open {}), Rc::new(ClientState::Closed {})].iter()
        }
    }

    impl PartialEq
        for ClientState {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (ClientState::Open{}, ClientState::Open{}) => {
                    true
                },
                (ClientState::Closed{}, ClientState::Closed{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for ClientState {}

    impl Hash
        for ClientState {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                ClientState::Open{} => {
                    
                },
                ClientState::Closed{} => {
                    
                },
            }
        }
    }

    impl AsRef<ClientState>
        for ClientState {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Client.dfy(22,3)
    pub struct NullTransport {}

    impl NullTransport {
        /// Allocates an UNINITIALIZED instance. Only the Dafny compiler should use that.
        pub fn _allocate_object() -> Object<Self> {
            allocate_object::<Self>()
        }
        /// src/Client.dfy(24,5)
        pub fn _ctor(this: &Object<NullTransport>) -> () {
            return ();
        }
    }

    impl UpcastObject<DynAny>
        for NullTransport {
        UpcastObjectFn!(DynAny);
    }

    impl Transport
        for NullTransport {
        /// src/Client.dfy(34,5)
        fn Write(&self, data: &Sequence<u8>) -> Rc<crate::Errors::Result<nat>> {
            let mut r: Rc<crate::Errors::Result<nat>> = Rc::new(crate::Errors::Result::Ok::<nat> {
                        value: int!(0)
                    });
            return r.clone();
        }
        /// src/Client.dfy(45,5)
        fn Close(&self) -> () {
            return ();
        }
    }

    impl UpcastObject<dyn Transport>
        for NullTransport {
        UpcastObjectFn!(dyn Transport);
    }

    /// class Client
    /// src/Client.dfy(57,3)
    pub struct Client {
        pub state: ::dafny_runtime::Field<Rc<ClientState>>,
        pub aggregator: ::dafny_runtime::Field<Object<Aggregator>>,
        pub sender: ::dafny_runtime::Field<Object<Sender>>,
        pub config: ::dafny_runtime::Field<Rc<DogStatsDConfig>>,
        pub containerID: ::dafny_runtime::Field<Object<ContainerID>>,
        pub externalEnv: ::dafny_runtime::Field<Object<ExternalEnv>>
    }

    impl Client {
        /// Allocates an UNINITIALIZED instance. Only the Dafny compiler should use that.
        pub fn _allocate_object() -> Object<Self> {
            allocate_object::<Self>()
        }
        /// src/Client.dfy(86,5)
        pub fn New(this: &Object<Client>, cfg: &Rc<DogStatsDConfig>) -> () {
            let mut _set_state: bool = false;
            let mut _set_aggregator: bool = false;
            let mut _set_sender: bool = false;
            let mut _set_config: bool = false;
            let mut _set_containerID: bool = false;
            let mut _set_externalEnv: bool = false;
            let mut agg: Object<Aggregator>;
            let mut _nw0: Object<Aggregator> = Aggregator::_allocate_object();
            Aggregator::New(&_nw0, &int!(4));
            agg = _nw0.clone();
            let mut snd: Object<Sender>;
            let mut _nw1: Object<Sender> = Sender::_allocate_object();
            Sender::New(&_nw1, cfg.senderQueueSize());
            snd = _nw1.clone();
            let mut cid: Object<ContainerID>;
            let mut _nw2: Object<ContainerID> = ContainerID::_allocate_object();
            ContainerID::_ctor(&_nw2);
            cid = _nw2.clone();
            let mut env: Object<ExternalEnv>;
            let mut _nw3: Object<ExternalEnv> = ExternalEnv::_allocate_object();
            ExternalEnv::_ctor(&_nw3);
            env = _nw3.clone();
            update_field_mut_uninit_object!(this.clone(), config, _set_config, cfg.clone());
            update_field_mut_uninit_object!(this.clone(), aggregator, _set_aggregator, agg.clone());
            update_field_mut_uninit_object!(this.clone(), sender, _set_sender, snd.clone());
            update_field_mut_uninit_object!(this.clone(), containerID, _set_containerID, cid.clone());
            update_field_mut_uninit_object!(this.clone(), externalEnv, _set_externalEnv, env.clone());
            update_field_mut_uninit_object!(this.clone(), state, _set_state, Rc::new(ClientState::Open {}));
            return ();
        }
        /// src/Client.dfy(113,5)
        pub fn SubmitGauge(&self, ctx: &Rc<MetricContext>, value: &BigRational, rate: &BigRational) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.state) == Rc::new(ClientState::Closed {}) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrNoClient {})
                            }));
                return r.read();
            };
            if read_field!(self.config).aggregationEnabled().clone() {
                rd!(read_field!(self.aggregator)).SampleGauge(ctx, value)
            };
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Client.dfy(139,5)
        pub fn SubmitCount(&self, ctx: &Rc<MetricContext>, value: &nat, rate: &BigRational) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.state) == Rc::new(ClientState::Closed {}) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrNoClient {})
                            }));
                return r.read();
            };
            if read_field!(self.config).aggregationEnabled().clone() {
                rd!(read_field!(self.aggregator)).SampleCount(ctx, value)
            };
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Client.dfy(165,5)
        pub fn SubmitSet(&self, ctx: &Rc<MetricContext>, value: &Sequence<DafnyChar>, rate: &BigRational) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.state) == Rc::new(ClientState::Closed {}) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrNoClient {})
                            }));
                return r.read();
            };
            if read_field!(self.config).aggregationEnabled().clone() {
                rd!(read_field!(self.aggregator)).SampleSet(ctx, value)
            };
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Client.dfy(192,5)
        pub fn SubmitHistogram(&self, ctx: &Rc<MetricContext>, value: &BigRational, rate: &BigRational) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.state) == Rc::new(ClientState::Closed {}) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrNoClient {})
                            }));
                return r.read();
            };
            if read_field!(self.config).extendedAggregation().clone() {
                rd!(read_field!(self.aggregator)).SampleBuffered(ctx, value, read_field!(self.config).maxSamplesPerContext())
            };
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Client.dfy(219,5)
        pub fn SubmitDistribution(&self, ctx: &Rc<MetricContext>, value: &BigRational, rate: &BigRational) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.state) == Rc::new(ClientState::Closed {}) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrNoClient {})
                            }));
                return r.read();
            };
            if read_field!(self.config).extendedAggregation().clone() {
                rd!(read_field!(self.aggregator)).SampleBuffered(ctx, value, read_field!(self.config).maxSamplesPerContext())
            };
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Client.dfy(246,5)
        pub fn SubmitTiming(&self, ctx: &Rc<MetricContext>, value: &BigRational, rate: &BigRational) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.state) == Rc::new(ClientState::Closed {}) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrNoClient {})
                            }));
                return r.read();
            };
            if read_field!(self.config).extendedAggregation().clone() {
                rd!(read_field!(self.aggregator)).SampleBuffered(ctx, value, read_field!(self.config).maxSamplesPerContext())
            };
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Client.dfy(274,5)
        pub fn Flush(&self) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.state) == Rc::new(ClientState::Closed {}) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrNoClient {})
                            }));
                return r.read();
            };
            let mut _v0: Sequence<Rc<WireMetric>>;
            let mut _out0: Sequence<Rc<WireMetric>> = rd!(read_field!(self.aggregator)).Flush();
            _v0 = _out0.clone();
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Client.dfy(297,5)
        pub fn Close(&self) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.state) == Rc::new(ClientState::Closed {}) {
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrNoClient {})
                            }));
                return r.read();
            };
            let mut _v1: Sequence<Rc<WireMetric>>;
            let mut _out0: Sequence<Rc<WireMetric>> = rd!(read_field!(self.aggregator)).Flush();
            _v1 = _out0.clone();
            rd!(read_field!(self.aggregator)).Stop();
            let mut t: Object<NullTransport>;
            let mut _nw0: Object<NullTransport> = NullTransport::_allocate_object();
            NullTransport::_ctor(&_nw0);
            t = _nw0.clone();
            rd!(read_field!(self.sender)).Stop(&upcast_object::<NullTransport, dyn Transport>()(t.clone()));
            modify_field!(self.state, Rc::new(ClientState::Closed {}));
            r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                            value: Rc::new(Unit::Unit {})
                        }));
            return r.read();
        }
        /// src/Client.dfy(339,5)
        pub fn IsClosed(&self) -> bool {
            read_field!(self.state) == Rc::new(ClientState::Closed {})
        }
    }

    impl UpcastObject<DynAny>
        for Client {
        UpcastObjectFn!(DynAny);
    }
}
/// src/Errors.dfy(2,1)
pub mod Errors {
    pub use ::std::rc::Rc;
    pub use ::dafny_runtime::Sequence;
    pub use ::dafny_runtime::DafnyChar;
    pub use crate::Errors::DogStatsDError::ErrNoClient;
    pub use ::dafny_runtime::string_of;
    pub use crate::Errors::DogStatsDError::ErrorInputChannelFull;
    pub use crate::Errors::DogStatsDError::ErrorSenderChannelFull;
    pub use ::std::fmt::Debug;
    pub use ::std::fmt::Formatter;
    pub use ::dafny_runtime::DafnyPrint;
    pub use ::dafny_runtime::SequenceIter;
    pub use ::dafny_runtime::seq;
    pub use ::std::cmp::PartialEq;
    pub use ::std::cmp::Eq;
    pub use ::std::hash::Hash;
    pub use ::std::hash::Hasher;
    pub use ::std::convert::AsRef;
    pub use ::dafny_runtime::DafnyType;

    pub struct _default {}

    impl _default {
        /// src/Errors.dfy(12,3)
        pub fn ErrorMessage(e: &Rc<DogStatsDError>) -> Sequence<DafnyChar> {
            let mut _source0: Rc<DogStatsDError> = e.clone();
            if matches!((&_source0).as_ref(), ErrNoClient{ .. }) {
                string_of("operation on nil or closed client")
            } else {
                if matches!((&_source0).as_ref(), ErrorInputChannelFull{ .. }) {
                    string_of("worker input channel full")
                } else {
                    if matches!((&_source0).as_ref(), ErrorSenderChannelFull{ .. }) {
                        string_of("sender channel full")
                    } else {
                        string_of("metric exceeds max bytes per payload")
                    }
                }
            }
        }
    }

    /// src/Errors.dfy(5,3)
    #[derive(Clone)]
    pub enum DogStatsDError {
        /// operation on nil or closed client
        ErrNoClient {},
        /// worker input channel full (channel mode)
        ErrorInputChannelFull {},
        /// sender queue full
        ErrorSenderChannelFull {},
        /// single metric exceeds maxBytesPerPayload
        MessageTooLongError {}
    }

    impl DogStatsDError {}

    impl Debug
        for DogStatsDError {
        fn fmt(&self, f: &mut Formatter) -> ::std::fmt::Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for DogStatsDError {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                DogStatsDError::ErrNoClient{} => {
                    write!(_formatter, "Errors.DogStatsDError.ErrNoClient")?;
                    Ok(())
                },
                DogStatsDError::ErrorInputChannelFull{} => {
                    write!(_formatter, "Errors.DogStatsDError.ErrorInputChannelFull")?;
                    Ok(())
                },
                DogStatsDError::ErrorSenderChannelFull{} => {
                    write!(_formatter, "Errors.DogStatsDError.ErrorSenderChannelFull")?;
                    Ok(())
                },
                DogStatsDError::MessageTooLongError{} => {
                    write!(_formatter, "Errors.DogStatsDError.MessageTooLongError")?;
                    Ok(())
                },
            }
        }
    }

    impl DogStatsDError {
        /// Enumerates all possible values of DogStatsDError
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<DogStatsDError>> {
            seq![Rc::new(DogStatsDError::ErrNoClient {}), Rc::new(DogStatsDError::ErrorInputChannelFull {}), Rc::new(DogStatsDError::ErrorSenderChannelFull {}), Rc::new(DogStatsDError::MessageTooLongError {})].iter()
        }
    }

    impl PartialEq
        for DogStatsDError {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (DogStatsDError::ErrNoClient{}, DogStatsDError::ErrNoClient{}) => {
                    true
                },
                (DogStatsDError::ErrorInputChannelFull{}, DogStatsDError::ErrorInputChannelFull{}) => {
                    true
                },
                (DogStatsDError::ErrorSenderChannelFull{}, DogStatsDError::ErrorSenderChannelFull{}) => {
                    true
                },
                (DogStatsDError::MessageTooLongError{}, DogStatsDError::MessageTooLongError{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for DogStatsDError {}

    impl Hash
        for DogStatsDError {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                DogStatsDError::ErrNoClient{} => {
                    
                },
                DogStatsDError::ErrorInputChannelFull{} => {
                    
                },
                DogStatsDError::ErrorSenderChannelFull{} => {
                    
                },
                DogStatsDError::MessageTooLongError{} => {
                    
                },
            }
        }
    }

    impl AsRef<DogStatsDError>
        for DogStatsDError {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Errors.dfy(22,3)
    #[derive(Clone)]
    pub enum Result<T: DafnyType> {
        Ok {
            value: T
        },
        Err {
            error: Rc<DogStatsDError>
        }
    }

    impl<T: DafnyType> Result<T> {
        /// Gets the field value for all enum members which have it
        pub fn value(&self) -> &T {
            match self {
                Result::Ok{value, } => value,
                Result::Err{error, } => panic!("field does not exist on this variant"),
            }
        }
        /// Gets the field error for all enum members which have it
        pub fn error(&self) -> &Rc<DogStatsDError> {
            match self {
                Result::Ok{value, } => panic!("field does not exist on this variant"),
                Result::Err{error, } => error,
            }
        }
    }

    impl<T: DafnyType> Debug
        for Result<T> {
        fn fmt(&self, f: &mut Formatter) -> ::std::fmt::Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl<T: DafnyType> DafnyPrint
        for Result<T> {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                Result::Ok{value, } => {
                    write!(_formatter, "Errors.Result.Ok(")?;
                    DafnyPrint::fmt_print(value, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
                Result::Err{error, } => {
                    write!(_formatter, "Errors.Result.Err(")?;
                    DafnyPrint::fmt_print(error, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
            }
        }
    }

    impl<T: DafnyType + Eq + Hash> PartialEq
        for Result<T> {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (Result::Ok{value, }, Result::Ok{value: _2_value, }) => {
                    value == _2_value
                },
                (Result::Err{error, }, Result::Err{error: _2_error, }) => {
                    error == _2_error
                },
                _ => {
                    false
                },
            }
        }
    }

    impl<T: DafnyType + Eq + Hash> Eq
        for Result<T> {}

    impl<T: DafnyType + Hash> Hash
        for Result<T> {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                Result::Ok{value, } => {
                    Hash::hash(value, _state)
                },
                Result::Err{error, } => {
                    Hash::hash(error, _state)
                },
            }
        }
    }

    impl<T: DafnyType> AsRef<Result<T>>
        for Result<T> {
        fn as_ref(&self) -> &Self {
            self
        }
    }
}
/// src/Sender.dfy(7,1)
pub mod Sender {
    pub use ::dafny_runtime::DafnyTypeEq;
    pub use ::dafny_runtime::Sequence;
    pub use ::dafny_runtime::_System::nat;
    pub use ::dafny_runtime::int;
    pub use ::std::fmt::Debug;
    pub use ::std::fmt::Formatter;
    pub use ::dafny_runtime::DafnyPrint;
    pub use ::dafny_runtime::SequenceIter;
    pub use ::std::rc::Rc;
    pub use ::dafny_runtime::seq;
    pub use ::std::cmp::PartialEq;
    pub use ::std::cmp::Eq;
    pub use ::std::hash::Hash;
    pub use ::std::hash::Hasher;
    pub use ::std::convert::AsRef;
    pub use ::dafny_runtime::Any;
    pub use ::dafny_runtime::UpcastObject;
    pub use ::dafny_runtime::Object;
    pub use ::dafny_runtime::allocate_object;
    pub use ::dafny_runtime::update_field_mut_uninit_object;
    pub use crate::Buffer::Buffer;
    pub use crate::Buffer::Unit;
    pub use ::dafny_runtime::MaybePlacebo;
    pub use ::dafny_runtime::read_field;
    pub use ::dafny_runtime::modify_field;
    pub use ::dafny_runtime::rd;
    pub use crate::Errors::DogStatsDError;
    pub use crate::Errors::Result::Ok;
    pub use ::dafny_runtime::DynAny;
    pub use ::dafny_runtime::UpcastObjectFn;

    pub struct _default {}

    impl _default {
        /// src/Sender.dfy(15,3)
        pub fn FirstIndexOf<_T: DafnyTypeEq>(s: &Sequence<_T>, x: &_T) -> nat {
            let mut _accumulator: nat = int!(0);
            let mut _r0 = s.clone();
            let mut _r1 = x.clone();
            'TAIL_CALL_START: loop {
                let s = _r0;
                let x = _r1;
                if s.get(&int!(0)) == x.clone() {
                    return int!(0) + _accumulator.clone();
                } else {
                    _accumulator = _accumulator.clone() + int!(1);
                    let mut _in0: Sequence<_T> = s.drop(&int!(1));
                    let mut _in1: _T = x.clone();
                    _r0 = _in0.clone();
                    _r1 = _in1.clone();
                    continue 'TAIL_CALL_START;
                }
            }
        }
    }

    /// src/Sender.dfy(26,3)
    #[derive(Clone)]
    pub enum SenderState {
        Running {},
        Stopped {}
    }

    impl SenderState {}

    impl Debug
        for SenderState {
        fn fmt(&self, f: &mut Formatter) -> ::std::fmt::Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for SenderState {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                SenderState::Running{} => {
                    write!(_formatter, "Sender.SenderState.Running")?;
                    Ok(())
                },
                SenderState::Stopped{} => {
                    write!(_formatter, "Sender.SenderState.Stopped")?;
                    Ok(())
                },
            }
        }
    }

    impl SenderState {
        /// Enumerates all possible values of SenderState
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<SenderState>> {
            seq![Rc::new(SenderState::Running {}), Rc::new(SenderState::Stopped {})].iter()
        }
    }

    impl PartialEq
        for SenderState {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (SenderState::Running{}, SenderState::Running{}) => {
                    true
                },
                (SenderState::Stopped{}, SenderState::Stopped{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for SenderState {}

    impl Hash
        for SenderState {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                SenderState::Running{} => {
                    
                },
                SenderState::Stopped{} => {
                    
                },
            }
        }
    }

    impl AsRef<SenderState>
        for SenderState {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Sender.dfy(30,3)
    #[derive(Clone)]
    pub enum Telemetry {
        Telemetry {
            payloadsSent: nat,
            payloadsDroppedQueueFull: nat,
            payloadsDroppedWriter: nat,
            bytesSent: nat,
            bytesDroppedQueueFull: nat,
            bytesDroppedWriter: nat
        }
    }

    impl Telemetry {
        /// Returns a borrow of the field payloadsSent
        pub fn payloadsSent(&self) -> &nat {
            match self {
                Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, } => payloadsSent,
            }
        }
        /// Returns a borrow of the field payloadsDroppedQueueFull
        pub fn payloadsDroppedQueueFull(&self) -> &nat {
            match self {
                Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, } => payloadsDroppedQueueFull,
            }
        }
        /// Returns a borrow of the field payloadsDroppedWriter
        pub fn payloadsDroppedWriter(&self) -> &nat {
            match self {
                Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, } => payloadsDroppedWriter,
            }
        }
        /// Returns a borrow of the field bytesSent
        pub fn bytesSent(&self) -> &nat {
            match self {
                Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, } => bytesSent,
            }
        }
        /// Returns a borrow of the field bytesDroppedQueueFull
        pub fn bytesDroppedQueueFull(&self) -> &nat {
            match self {
                Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, } => bytesDroppedQueueFull,
            }
        }
        /// Returns a borrow of the field bytesDroppedWriter
        pub fn bytesDroppedWriter(&self) -> &nat {
            match self {
                Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, } => bytesDroppedWriter,
            }
        }
    }

    impl Debug
        for Telemetry {
        fn fmt(&self, f: &mut Formatter) -> ::std::fmt::Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for Telemetry {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, } => {
                    write!(_formatter, "Sender.Telemetry.Telemetry(")?;
                    DafnyPrint::fmt_print(payloadsSent, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(payloadsDroppedQueueFull, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(payloadsDroppedWriter, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(bytesSent, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(bytesDroppedQueueFull, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(bytesDroppedWriter, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
            }
        }
    }

    impl PartialEq
        for Telemetry {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, }, Telemetry::Telemetry{payloadsSent: _2_payloadsSent, payloadsDroppedQueueFull: _2_payloadsDroppedQueueFull, payloadsDroppedWriter: _2_payloadsDroppedWriter, bytesSent: _2_bytesSent, bytesDroppedQueueFull: _2_bytesDroppedQueueFull, bytesDroppedWriter: _2_bytesDroppedWriter, }) => {
                    payloadsSent == _2_payloadsSent && payloadsDroppedQueueFull == _2_payloadsDroppedQueueFull && payloadsDroppedWriter == _2_payloadsDroppedWriter && bytesSent == _2_bytesSent && bytesDroppedQueueFull == _2_bytesDroppedQueueFull && bytesDroppedWriter == _2_bytesDroppedWriter
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for Telemetry {}

    impl Hash
        for Telemetry {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                Telemetry::Telemetry{payloadsSent, payloadsDroppedQueueFull, payloadsDroppedWriter, bytesSent, bytesDroppedQueueFull, bytesDroppedWriter, } => {
                    Hash::hash(payloadsSent, _state);
                    Hash::hash(payloadsDroppedQueueFull, _state);
                    Hash::hash(payloadsDroppedWriter, _state);
                    Hash::hash(bytesSent, _state);
                    Hash::hash(bytesDroppedQueueFull, _state);
                    Hash::hash(bytesDroppedWriter, _state)
                },
            }
        }
    }

    impl AsRef<Telemetry>
        for Telemetry {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Sender.dfy(41,3)
    pub trait Transport: Any + UpcastObject<dyn Any> {
        /// src/Sender.dfy(46,5)
        fn Write(&self, data: &Sequence<u8>) -> Rc<crate::Errors::Result<nat>>;
        /// src/Sender.dfy(53,5)
        fn Close(&self) -> ();
    }

    /// src/Sender.dfy(62,3)
    pub struct Sender {
        pub state: ::dafny_runtime::Field<Rc<SenderState>>,
        pub queue: ::dafny_runtime::Field<Sequence<Object<Buffer>>>,
        pub maxQueueSize: ::dafny_runtime::Field<nat>,
        pub telemetry: ::dafny_runtime::Field<Rc<Telemetry>>
    }

    impl Sender {
        /// Allocates an UNINITIALIZED instance. Only the Dafny compiler should use that.
        pub fn _allocate_object() -> Object<Self> {
            allocate_object::<Self>()
        }
        /// src/Sender.dfy(78,5)
        pub fn New(this: &Object<Sender>, mqs: &nat) -> () {
            let mut _set_state: bool = false;
            let mut _set_queue: bool = false;
            let mut _set_maxQueueSize: bool = false;
            let mut _set_telemetry: bool = false;
            update_field_mut_uninit_object!(this.clone(), state, _set_state, Rc::new(SenderState::Running {}));
            update_field_mut_uninit_object!(this.clone(), queue, _set_queue, seq![] as Sequence<Object<Buffer>>);
            update_field_mut_uninit_object!(this.clone(), maxQueueSize, _set_maxQueueSize, mqs.clone());
            update_field_mut_uninit_object!(this.clone(), telemetry, _set_telemetry, Rc::new(Telemetry::Telemetry {
                        payloadsSent: int!(0),
                        payloadsDroppedQueueFull: int!(0),
                        payloadsDroppedWriter: int!(0),
                        bytesSent: int!(0),
                        bytesDroppedQueueFull: int!(0),
                        bytesDroppedWriter: int!(0)
                    }));
            return ();
        }
        /// src/Sender.dfy(98,5)
        pub fn Enqueue(&self, b: &Object<Buffer>) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            if read_field!(self.queue).cardinality() < read_field!(self.maxQueueSize) {
                modify_field!(self.queue, read_field!(self.queue).concat(&seq![b.clone()]));
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                                value: Rc::new(Unit::Unit {})
                            }));
            } else {
                let mut dropped: nat = read_field!(rd!(b.clone()).len);
                let mut _dt__update__tmp_h0: Rc<Telemetry> = read_field!(self.telemetry);
                let mut _dt__update_hbytesDroppedQueueFull_h0: nat = read_field!(self.telemetry).bytesDroppedQueueFull().clone() + dropped.clone();
                let mut _dt__update_hpayloadsDroppedQueueFull_h0: nat = read_field!(self.telemetry).payloadsDroppedQueueFull().clone() + int!(1);
                modify_field!(self.telemetry, Rc::new(Telemetry::Telemetry {
                            payloadsSent: _dt__update__tmp_h0.payloadsSent().clone(),
                            payloadsDroppedQueueFull: _dt__update_hpayloadsDroppedQueueFull_h0.clone(),
                            payloadsDroppedWriter: _dt__update__tmp_h0.payloadsDroppedWriter().clone(),
                            bytesSent: _dt__update__tmp_h0.bytesSent().clone(),
                            bytesDroppedQueueFull: _dt__update_hbytesDroppedQueueFull_h0.clone(),
                            bytesDroppedWriter: _dt__update__tmp_h0.bytesDroppedWriter().clone()
                        }));
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: Rc::new(DogStatsDError::ErrorSenderChannelFull {})
                            }));
            };
            return r.read();
        }
        /// src/Sender.dfy(137,5)
        pub fn Send(&self, transport: &Object<dyn Transport>) -> Rc<crate::Errors::Result<Rc<Unit>>> {
            let mut r = MaybePlacebo::<Rc<crate::Errors::Result<Rc<Unit>>>>::new();
            let mut buf: Object<Buffer> = read_field!(self.queue).get(&int!(0));
            modify_field!(self.queue, read_field!(self.queue).drop(&int!(1)));
            let mut bytes: Sequence<u8> = rd!(buf).Bytes();
            let mut wr: Rc<crate::Errors::Result<nat>>;
            let mut _out0: Rc<crate::Errors::Result<nat>> = Transport::Write(rd!(transport.clone()), &bytes);
            wr = _out0.clone();
            let mut _source0: Rc<crate::Errors::Result<nat>> = wr.clone();
            if matches!((&_source0).as_ref(), Ok{ .. }) {
                let mut ___mcc_h0: nat = _source0.value().clone();
                let mut _dt__update__tmp_h0: Rc<Telemetry> = read_field!(self.telemetry);
                let mut _dt__update_hbytesSent_h0: nat = read_field!(self.telemetry).bytesSent().clone() + bytes.cardinality();
                let mut _dt__update_hpayloadsSent_h0: nat = read_field!(self.telemetry).payloadsSent().clone() + int!(1);
                modify_field!(self.telemetry, Rc::new(Telemetry::Telemetry {
                            payloadsSent: _dt__update_hpayloadsSent_h0.clone(),
                            payloadsDroppedQueueFull: _dt__update__tmp_h0.payloadsDroppedQueueFull().clone(),
                            payloadsDroppedWriter: _dt__update__tmp_h0.payloadsDroppedWriter().clone(),
                            bytesSent: _dt__update_hbytesSent_h0.clone(),
                            bytesDroppedQueueFull: _dt__update__tmp_h0.bytesDroppedQueueFull().clone(),
                            bytesDroppedWriter: _dt__update__tmp_h0.bytesDroppedWriter().clone()
                        }));
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Ok::<Rc<Unit>> {
                                value: Rc::new(Unit::Unit {})
                            }));
            } else {
                let mut ___mcc_h1: Rc<DogStatsDError> = _source0.error().clone();
                let mut e: Rc<DogStatsDError> = ___mcc_h1.clone();
                let mut _dt__update__tmp_h1: Rc<Telemetry> = read_field!(self.telemetry);
                let mut _dt__update_hbytesDroppedWriter_h0: nat = read_field!(self.telemetry).bytesDroppedWriter().clone() + bytes.cardinality();
                let mut _dt__update_hpayloadsDroppedWriter_h0: nat = read_field!(self.telemetry).payloadsDroppedWriter().clone() + int!(1);
                modify_field!(self.telemetry, Rc::new(Telemetry::Telemetry {
                            payloadsSent: _dt__update__tmp_h1.payloadsSent().clone(),
                            payloadsDroppedQueueFull: _dt__update__tmp_h1.payloadsDroppedQueueFull().clone(),
                            payloadsDroppedWriter: _dt__update_hpayloadsDroppedWriter_h0.clone(),
                            bytesSent: _dt__update__tmp_h1.bytesSent().clone(),
                            bytesDroppedQueueFull: _dt__update__tmp_h1.bytesDroppedQueueFull().clone(),
                            bytesDroppedWriter: _dt__update_hbytesDroppedWriter_h0.clone()
                        }));
                r = MaybePlacebo::from(Rc::new(crate::Errors::Result::Err::<Rc<Unit>> {
                                error: e.clone()
                            }));
            };
            return r.read();
        }
        /// src/Sender.dfy(184,5)
        pub fn Stop(&self, transport: &Object<dyn Transport>) -> () {
            while int!(0) < read_field!(self.queue).cardinality() {
                let mut prevQueue: Sequence<Object<Buffer>> = read_field!(self.queue);
                let mut buf: Object<Buffer> = prevQueue.get(&int!(0));
                modify_field!(self.queue, prevQueue.drop(&int!(1)));
                let mut bytes: Sequence<u8> = rd!(buf).Bytes();
                let mut wr: Rc<crate::Errors::Result<nat>>;
                let mut _out0: Rc<crate::Errors::Result<nat>> = Transport::Write(rd!(transport.clone()), &bytes);
                wr = _out0.clone();
                let mut _source0: Rc<crate::Errors::Result<nat>> = wr.clone();
                if matches!((&_source0).as_ref(), Ok{ .. }) {
                    let mut ___mcc_h0: nat = _source0.value().clone();
                    let mut _dt__update__tmp_h0: Rc<Telemetry> = read_field!(self.telemetry);
                    let mut _dt__update_hbytesSent_h0: nat = read_field!(self.telemetry).bytesSent().clone() + bytes.cardinality();
                    let mut _dt__update_hpayloadsSent_h0: nat = read_field!(self.telemetry).payloadsSent().clone() + int!(1);
                    modify_field!(self.telemetry, Rc::new(Telemetry::Telemetry {
                                payloadsSent: _dt__update_hpayloadsSent_h0.clone(),
                                payloadsDroppedQueueFull: _dt__update__tmp_h0.payloadsDroppedQueueFull().clone(),
                                payloadsDroppedWriter: _dt__update__tmp_h0.payloadsDroppedWriter().clone(),
                                bytesSent: _dt__update_hbytesSent_h0.clone(),
                                bytesDroppedQueueFull: _dt__update__tmp_h0.bytesDroppedQueueFull().clone(),
                                bytesDroppedWriter: _dt__update__tmp_h0.bytesDroppedWriter().clone()
                            }))
                } else {
                    let mut ___mcc_h1: Rc<DogStatsDError> = _source0.error().clone();
                    let mut _dt__update__tmp_h1: Rc<Telemetry> = read_field!(self.telemetry);
                    let mut _dt__update_hbytesDroppedWriter_h0: nat = read_field!(self.telemetry).bytesDroppedWriter().clone() + bytes.cardinality();
                    let mut _dt__update_hpayloadsDroppedWriter_h0: nat = read_field!(self.telemetry).payloadsDroppedWriter().clone() + int!(1);
                    modify_field!(self.telemetry, Rc::new(Telemetry::Telemetry {
                                payloadsSent: _dt__update__tmp_h1.payloadsSent().clone(),
                                payloadsDroppedQueueFull: _dt__update__tmp_h1.payloadsDroppedQueueFull().clone(),
                                payloadsDroppedWriter: _dt__update_hpayloadsDroppedWriter_h0.clone(),
                                bytesSent: _dt__update__tmp_h1.bytesSent().clone(),
                                bytesDroppedQueueFull: _dt__update__tmp_h1.bytesDroppedQueueFull().clone(),
                                bytesDroppedWriter: _dt__update_hbytesDroppedWriter_h0.clone()
                            }))
                }
            };
            Transport::Close(rd!(transport.clone()));
            modify_field!(self.state, Rc::new(SenderState::Stopped {}));
            return ();
        }
    }

    impl UpcastObject<DynAny>
        for Sender {
        UpcastObjectFn!(DynAny);
    }
}
/// src/Singletons.dfy(4,1)
pub mod Singletons {
    pub use ::dafny_runtime::DafnyChar;
    pub use ::dafny_runtime::int;
    pub use ::std::primitive::char;
    pub use ::dafny_runtime::Sequence;
    pub use ::dafny_runtime::seq;
    pub use ::std::fmt::Debug;
    pub use ::std::fmt::Formatter;
    pub use ::std::fmt::Result;
    pub use ::dafny_runtime::DafnyPrint;
    pub use ::dafny_runtime::SequenceIter;
    pub use ::std::rc::Rc;
    pub use ::std::cmp::PartialEq;
    pub use ::std::cmp::Eq;
    pub use ::std::hash::Hash;
    pub use ::std::hash::Hasher;
    pub use ::std::convert::AsRef;
    pub use ::dafny_runtime::DafnyType;
    pub use ::dafny_runtime::Object;
    pub use ::dafny_runtime::allocate_object;
    pub use ::dafny_runtime::update_field_mut_uninit_object;
    pub use ::dafny_runtime::string_of;
    pub use ::dafny_runtime::modify_field;
    pub use crate::Types::Option;
    pub use ::dafny_runtime::read_field;
    pub use ::dafny_runtime::UpcastObject;
    pub use ::dafny_runtime::DynAny;
    pub use ::dafny_runtime::UpcastObjectFn;

    pub struct _default {}

    impl _default {
        /// src/Singletons.dfy(82,3)
        pub fn IsPrintableNonPipe(c: &DafnyChar) -> bool {
            int!(32) <= int!(c.clone().0) && int!(c.clone().0) <= int!(126) && c.clone() != DafnyChar(char::from_u32(124).unwrap())
        }
        /// src/Singletons.dfy(87,3)
        pub fn SanitizeExternalEnv(raw: &Sequence<DafnyChar>) -> Sequence<DafnyChar> {
            let mut _accumulator: Sequence<DafnyChar> = seq![] as Sequence<DafnyChar>;
            let mut _r0 = raw.clone();
            'TAIL_CALL_START: loop {
                let raw = _r0;
                if raw.cardinality() == int!(0) {
                    return _accumulator.concat(&(seq![] as Sequence<DafnyChar>));
                } else {
                    _accumulator = _accumulator.concat(&(if _default::IsPrintableNonPipe(&raw.get(&int!(0))) {
                                seq![raw.get(&int!(0))]
                            } else {
                                seq![] as Sequence<DafnyChar>
                            }));
                    let mut _in0: Sequence<DafnyChar> = raw.drop(&int!(1));
                    _r0 = _in0.clone();
                    continue 'TAIL_CALL_START;
                }
            }
        }
    }

    /// src/Singletons.dfy(8,3)
    #[derive(Clone)]
    pub enum InitState {
        Unset {},
        Set {}
    }

    impl InitState {}

    impl Debug
        for InitState {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for InitState {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                InitState::Unset{} => {
                    write!(_formatter, "Singletons.InitState.Unset")?;
                    Ok(())
                },
                InitState::Set{} => {
                    write!(_formatter, "Singletons.InitState.Set")?;
                    Ok(())
                },
            }
        }
    }

    impl InitState {
        /// Enumerates all possible values of InitState
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<InitState>> {
            seq![Rc::new(InitState::Unset {}), Rc::new(InitState::Set {})].iter()
        }
    }

    impl PartialEq
        for InitState {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (InitState::Unset{}, InitState::Unset{}) => {
                    true
                },
                (InitState::Set{}, InitState::Set{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for InitState {}

    impl Hash
        for InitState {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                InitState::Unset{} => {
                    
                },
                InitState::Set{} => {
                    
                },
            }
        }
    }

    impl AsRef<InitState>
        for InitState {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Singletons.dfy(11,3)
    #[derive(Clone)]
    pub enum Singleton<T: DafnyType> {
        SingletonVal {
            state: Rc<InitState>,
            value: T
        }
    }

    impl<T: DafnyType> Singleton<T> {
        /// Returns a borrow of the field state
        pub fn state(&self) -> &Rc<InitState> {
            match self {
                Singleton::SingletonVal{state, value, } => state,
            }
        }
        /// Returns a borrow of the field value
        pub fn value(&self) -> &T {
            match self {
                Singleton::SingletonVal{state, value, } => value,
            }
        }
    }

    impl<T: DafnyType> Debug
        for Singleton<T> {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl<T: DafnyType> DafnyPrint
        for Singleton<T> {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                Singleton::SingletonVal{state, value, } => {
                    write!(_formatter, "Singletons.Singleton.SingletonVal(")?;
                    DafnyPrint::fmt_print(state, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(value, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
            }
        }
    }

    impl<T: DafnyType> AsRef<Singleton<T>>
        for Singleton<T> {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Singletons.dfy(22,3)
    pub struct ContainerID {
        pub s: ::dafny_runtime::Field<Rc<Singleton<Sequence<DafnyChar>>>>
    }

    impl ContainerID {
        /// Allocates an UNINITIALIZED instance. Only the Dafny compiler should use that.
        pub fn _allocate_object() -> Object<Self> {
            allocate_object::<Self>()
        }
        /// src/Singletons.dfy(31,5)
        pub fn _ctor(this: &Object<ContainerID>) -> () {
            let mut _set_s: bool = false;
            update_field_mut_uninit_object!(this.clone(), s, _set_s, Rc::new(Singleton::SingletonVal::<Sequence<DafnyChar>> {
                        state: Rc::new(InitState::Unset {}),
                        value: string_of("")
                    }));
            return ();
        }
        /// src/Singletons.dfy(40,5)
        pub fn Init(&self, v: &Sequence<DafnyChar>) -> () {
            modify_field!(self.s, Rc::new(Singleton::SingletonVal::<Sequence<DafnyChar>> {
                        state: Rc::new(InitState::Set {}),
                        value: v.clone()
                    }));
            return ();
        }
        /// src/Singletons.dfy(53,5)
        pub fn Get(&self) -> Rc<Option<Sequence<DafnyChar>>> {
            if read_field!(self.s).state().clone() == Rc::new(InitState::Set {}) {
                Rc::new(Option::Some::<Sequence<DafnyChar>> {
                        value: read_field!(self.s).value().clone()
                    })
            } else {
                Rc::new(Option::None::<Sequence<DafnyChar>> {})
            }
        }
    }

    impl UpcastObject<DynAny>
        for ContainerID {
        UpcastObjectFn!(DynAny);
    }

    /// src/Singletons.dfy(120,3)
    pub struct ExternalEnv {
        pub s: ::dafny_runtime::Field<Rc<Singleton<Sequence<DafnyChar>>>>
    }

    impl ExternalEnv {
        /// Allocates an UNINITIALIZED instance. Only the Dafny compiler should use that.
        pub fn _allocate_object() -> Object<Self> {
            allocate_object::<Self>()
        }
        /// src/Singletons.dfy(129,5)
        pub fn _ctor(this: &Object<ExternalEnv>) -> () {
            let mut _set_s: bool = false;
            update_field_mut_uninit_object!(this.clone(), s, _set_s, Rc::new(Singleton::SingletonVal::<Sequence<DafnyChar>> {
                        state: Rc::new(InitState::Unset {}),
                        value: string_of("")
                    }));
            return ();
        }
        /// src/Singletons.dfy(138,5)
        pub fn Init(&self, raw: &Sequence<DafnyChar>) -> () {
            modify_field!(self.s, Rc::new(Singleton::SingletonVal::<Sequence<DafnyChar>> {
                        state: Rc::new(InitState::Set {}),
                        value: _default::SanitizeExternalEnv(raw)
                    }));
            return ();
        }
        /// src/Singletons.dfy(151,5)
        pub fn Get(&self) -> Sequence<DafnyChar> {
            if read_field!(self.s).state().clone() == Rc::new(InitState::Set {}) {
                read_field!(self.s).value().clone()
            } else {
                string_of("")
            }
        }
    }

    impl UpcastObject<DynAny>
        for ExternalEnv {
        UpcastObjectFn!(DynAny);
    }
}
/// src/Types.dfy(2,1)
pub mod Types {
    pub use ::std::rc::Rc;
    pub use ::dafny_runtime::Sequence;
    pub use ::dafny_runtime::DafnyChar;
    pub use crate::Types::MetricType::Gauge;
    pub use ::dafny_runtime::string_of;
    pub use crate::Types::MetricType::Count;
    pub use crate::Types::MetricType::Histogram;
    pub use crate::Types::MetricType::Distribution;
    pub use crate::Types::MetricType::Set;
    pub use crate::Types::TagCardinality::CardinalityNotSet;
    pub use crate::Types::TagCardinality::CardinalityNone;
    pub use crate::Types::TagCardinality::CardinalityLow;
    pub use crate::Types::TagCardinality::CardinalityOrchestrator;
    pub use ::dafny_runtime::int;
    pub use ::dafny_runtime::_System::nat;
    pub use ::dafny_runtime::DafnyType;
    pub use ::std::fmt::Debug;
    pub use ::std::fmt::Formatter;
    pub use ::std::fmt::Result;
    pub use ::dafny_runtime::DafnyPrint;
    pub use ::std::cmp::Eq;
    pub use ::std::hash::Hash;
    pub use ::std::cmp::PartialEq;
    pub use ::std::hash::Hasher;
    pub use ::std::convert::AsRef;
    pub use ::dafny_runtime::SequenceIter;
    pub use ::dafny_runtime::seq;
    pub use ::dafny_runtime::DafnyInt;

    pub struct _default {}

    impl _default {
        /// src/Types.dfy(14,3)
        pub fn MetricTypeSymbol(t: &Rc<MetricType>) -> Sequence<DafnyChar> {
            let mut _source0: Rc<MetricType> = t.clone();
            if matches!((&_source0).as_ref(), Gauge{ .. }) {
                string_of("g")
            } else {
                if matches!((&_source0).as_ref(), Count{ .. }) {
                    string_of("c")
                } else {
                    if matches!((&_source0).as_ref(), Histogram{ .. }) {
                        string_of("h")
                    } else {
                        if matches!((&_source0).as_ref(), Distribution{ .. }) {
                            string_of("d")
                        } else {
                            if matches!((&_source0).as_ref(), Set{ .. }) {
                                string_of("s")
                            } else {
                                string_of("ms")
                            }
                        }
                    }
                }
            }
        }
        /// src/Types.dfy(36,3)
        pub fn CardinalityString(c: &Rc<TagCardinality>) -> Rc<Option<Sequence<DafnyChar>>> {
            let mut _source0: Rc<TagCardinality> = c.clone();
            if matches!((&_source0).as_ref(), CardinalityNotSet{ .. }) {
                Rc::new(Option::None::<Sequence<DafnyChar>> {})
            } else {
                if matches!((&_source0).as_ref(), CardinalityNone{ .. }) {
                    Rc::new(Option::Some::<Sequence<DafnyChar>> {
                            value: string_of("none")
                        })
                } else {
                    if matches!((&_source0).as_ref(), CardinalityLow{ .. }) {
                        Rc::new(Option::Some::<Sequence<DafnyChar>> {
                                value: string_of("low")
                            })
                    } else {
                        if matches!((&_source0).as_ref(), CardinalityOrchestrator{ .. }) {
                            Rc::new(Option::Some::<Sequence<DafnyChar>> {
                                    value: string_of("orchestrator")
                                })
                        } else {
                            Rc::new(Option::Some::<Sequence<DafnyChar>> {
                                    value: string_of("high")
                                })
                        }
                    }
                }
            }
        }
        /// src/Types.dfy(71,3)
        pub fn DefaultConfig() -> Rc<DogStatsDConfig> {
            Rc::new(DogStatsDConfig::DogStatsDConfig {
                    maxBytesPerPayload: _default::UDP_MAX_BYTES(),
                    bufferFlushIntervalMs: _default::DEFAULT_BUFFER_FLUSH_INTERVAL_MS(),
                    aggregationFlushIntervalMs: _default::DEFAULT_AGGREGATION_FLUSH_INTERVAL_MS(),
                    senderQueueSize: _default::DEFAULT_SENDER_QUEUE_SIZE(),
                    bufferPoolCapacity: _default::DEFAULT_BUFFER_POOL_CAPACITY(),
                    aggregationEnabled: true,
                    extendedAggregation: false,
                    maxSamplesPerContext: int!(-1),
                    originDetection: true,
                    cardinality: Rc::new(TagCardinality::CardinalityNotSet {})
                })
        }
        /// src/Types.dfy(49,3)
        pub fn UDP_MAX_BYTES() -> nat {
            int!(1432)
        }
        /// src/Types.dfy(51,3)
        pub fn DEFAULT_BUFFER_FLUSH_INTERVAL_MS() -> nat {
            int!(100)
        }
        /// src/Types.dfy(52,3)
        pub fn DEFAULT_AGGREGATION_FLUSH_INTERVAL_MS() -> nat {
            int!(2000)
        }
        /// src/Types.dfy(53,3)
        pub fn DEFAULT_SENDER_QUEUE_SIZE() -> nat {
            int!(512)
        }
        /// src/Types.dfy(54,3)
        pub fn DEFAULT_BUFFER_POOL_CAPACITY() -> nat {
            int!(2048)
        }
        /// src/Types.dfy(50,3)
        pub fn UDS_MAX_BYTES() -> nat {
            int!(8192)
        }
    }

    /// src/Types.dfy(5,3)
    #[derive(Clone)]
    pub enum Option<T: DafnyType> {
        None {},
        Some {
            value: T
        }
    }

    impl<T: DafnyType> Option<T> {
        /// Gets the field value for all enum members which have it
        pub fn value(&self) -> &T {
            match self {
                Option::None{} => panic!("field does not exist on this variant"),
                Option::Some{value, } => value,
            }
        }
    }

    impl<T: DafnyType> Debug
        for Option<T> {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl<T: DafnyType> DafnyPrint
        for Option<T> {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                Option::None{} => {
                    write!(_formatter, "Types.Option.None")?;
                    Ok(())
                },
                Option::Some{value, } => {
                    write!(_formatter, "Types.Option.Some(")?;
                    DafnyPrint::fmt_print(value, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
            }
        }
    }

    impl<T: DafnyType + Eq + Hash> PartialEq
        for Option<T> {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (Option::None{}, Option::None{}) => {
                    true
                },
                (Option::Some{value, }, Option::Some{value: _2_value, }) => {
                    value == _2_value
                },
                _ => {
                    false
                },
            }
        }
    }

    impl<T: DafnyType + Eq + Hash> Eq
        for Option<T> {}

    impl<T: DafnyType + Hash> Hash
        for Option<T> {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                Option::None{} => {
                    
                },
                Option::Some{value, } => {
                    Hash::hash(value, _state)
                },
            }
        }
    }

    impl<T: DafnyType> AsRef<Option<T>>
        for Option<T> {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Types.dfy(11,3)
    #[derive(Clone)]
    pub enum MetricType {
        Gauge {},
        Count {},
        Histogram {},
        Distribution {},
        Set {},
        Timing {}
    }

    impl MetricType {}

    impl Debug
        for MetricType {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for MetricType {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                MetricType::Gauge{} => {
                    write!(_formatter, "Types.MetricType.Gauge")?;
                    Ok(())
                },
                MetricType::Count{} => {
                    write!(_formatter, "Types.MetricType.Count")?;
                    Ok(())
                },
                MetricType::Histogram{} => {
                    write!(_formatter, "Types.MetricType.Histogram")?;
                    Ok(())
                },
                MetricType::Distribution{} => {
                    write!(_formatter, "Types.MetricType.Distribution")?;
                    Ok(())
                },
                MetricType::Set{} => {
                    write!(_formatter, "Types.MetricType.Set")?;
                    Ok(())
                },
                MetricType::Timing{} => {
                    write!(_formatter, "Types.MetricType.Timing")?;
                    Ok(())
                },
            }
        }
    }

    impl MetricType {
        /// Enumerates all possible values of MetricType
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<MetricType>> {
            seq![Rc::new(MetricType::Gauge {}), Rc::new(MetricType::Count {}), Rc::new(MetricType::Histogram {}), Rc::new(MetricType::Distribution {}), Rc::new(MetricType::Set {}), Rc::new(MetricType::Timing {})].iter()
        }
    }

    impl PartialEq
        for MetricType {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (MetricType::Gauge{}, MetricType::Gauge{}) => {
                    true
                },
                (MetricType::Count{}, MetricType::Count{}) => {
                    true
                },
                (MetricType::Histogram{}, MetricType::Histogram{}) => {
                    true
                },
                (MetricType::Distribution{}, MetricType::Distribution{}) => {
                    true
                },
                (MetricType::Set{}, MetricType::Set{}) => {
                    true
                },
                (MetricType::Timing{}, MetricType::Timing{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for MetricType {}

    impl Hash
        for MetricType {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                MetricType::Gauge{} => {
                    
                },
                MetricType::Count{} => {
                    
                },
                MetricType::Histogram{} => {
                    
                },
                MetricType::Distribution{} => {
                    
                },
                MetricType::Set{} => {
                    
                },
                MetricType::Timing{} => {
                    
                },
            }
        }
    }

    impl AsRef<MetricType>
        for MetricType {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Types.dfy(25,3)
    #[derive(Clone)]
    pub enum TransportMode {
        UDP {},
        UDS {},
        Pipe {}
    }

    impl TransportMode {}

    impl Debug
        for TransportMode {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for TransportMode {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                TransportMode::UDP{} => {
                    write!(_formatter, "Types.TransportMode.UDP")?;
                    Ok(())
                },
                TransportMode::UDS{} => {
                    write!(_formatter, "Types.TransportMode.UDS")?;
                    Ok(())
                },
                TransportMode::Pipe{} => {
                    write!(_formatter, "Types.TransportMode.Pipe")?;
                    Ok(())
                },
            }
        }
    }

    impl TransportMode {
        /// Enumerates all possible values of TransportMode
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<TransportMode>> {
            seq![Rc::new(TransportMode::UDP {}), Rc::new(TransportMode::UDS {}), Rc::new(TransportMode::Pipe {})].iter()
        }
    }

    impl PartialEq
        for TransportMode {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (TransportMode::UDP{}, TransportMode::UDP{}) => {
                    true
                },
                (TransportMode::UDS{}, TransportMode::UDS{}) => {
                    true
                },
                (TransportMode::Pipe{}, TransportMode::Pipe{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for TransportMode {}

    impl Hash
        for TransportMode {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                TransportMode::UDP{} => {
                    
                },
                TransportMode::UDS{} => {
                    
                },
                TransportMode::Pipe{} => {
                    
                },
            }
        }
    }

    impl AsRef<TransportMode>
        for TransportMode {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Types.dfy(28,3)
    #[derive(Clone)]
    pub enum TagCardinality {
        CardinalityNotSet {},
        CardinalityNone {},
        CardinalityLow {},
        CardinalityOrchestrator {},
        CardinalityHigh {}
    }

    impl TagCardinality {}

    impl Debug
        for TagCardinality {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for TagCardinality {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                TagCardinality::CardinalityNotSet{} => {
                    write!(_formatter, "Types.TagCardinality.CardinalityNotSet")?;
                    Ok(())
                },
                TagCardinality::CardinalityNone{} => {
                    write!(_formatter, "Types.TagCardinality.CardinalityNone")?;
                    Ok(())
                },
                TagCardinality::CardinalityLow{} => {
                    write!(_formatter, "Types.TagCardinality.CardinalityLow")?;
                    Ok(())
                },
                TagCardinality::CardinalityOrchestrator{} => {
                    write!(_formatter, "Types.TagCardinality.CardinalityOrchestrator")?;
                    Ok(())
                },
                TagCardinality::CardinalityHigh{} => {
                    write!(_formatter, "Types.TagCardinality.CardinalityHigh")?;
                    Ok(())
                },
            }
        }
    }

    impl TagCardinality {
        /// Enumerates all possible values of TagCardinality
        pub fn _AllSingletonConstructors() -> SequenceIter<Rc<TagCardinality>> {
            seq![Rc::new(TagCardinality::CardinalityNotSet {}), Rc::new(TagCardinality::CardinalityNone {}), Rc::new(TagCardinality::CardinalityLow {}), Rc::new(TagCardinality::CardinalityOrchestrator {}), Rc::new(TagCardinality::CardinalityHigh {})].iter()
        }
    }

    impl PartialEq
        for TagCardinality {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (TagCardinality::CardinalityNotSet{}, TagCardinality::CardinalityNotSet{}) => {
                    true
                },
                (TagCardinality::CardinalityNone{}, TagCardinality::CardinalityNone{}) => {
                    true
                },
                (TagCardinality::CardinalityLow{}, TagCardinality::CardinalityLow{}) => {
                    true
                },
                (TagCardinality::CardinalityOrchestrator{}, TagCardinality::CardinalityOrchestrator{}) => {
                    true
                },
                (TagCardinality::CardinalityHigh{}, TagCardinality::CardinalityHigh{}) => {
                    true
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for TagCardinality {}

    impl Hash
        for TagCardinality {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                TagCardinality::CardinalityNotSet{} => {
                    
                },
                TagCardinality::CardinalityNone{} => {
                    
                },
                TagCardinality::CardinalityLow{} => {
                    
                },
                TagCardinality::CardinalityOrchestrator{} => {
                    
                },
                TagCardinality::CardinalityHigh{} => {
                    
                },
            }
        }
    }

    impl AsRef<TagCardinality>
        for TagCardinality {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Types.dfy(46,3)
    #[derive(Clone)]
    pub enum MetricContext {
        MetricContext {
            name: Sequence<DafnyChar>,
            tags: Sequence<Sequence<DafnyChar>>
        }
    }

    impl MetricContext {
        /// Returns a borrow of the field name
        pub fn name(&self) -> &Sequence<DafnyChar> {
            match self {
                MetricContext::MetricContext{name, tags, } => name,
            }
        }
        /// Returns a borrow of the field tags
        pub fn tags(&self) -> &Sequence<Sequence<DafnyChar>> {
            match self {
                MetricContext::MetricContext{name, tags, } => tags,
            }
        }
    }

    impl Debug
        for MetricContext {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for MetricContext {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                MetricContext::MetricContext{name, tags, } => {
                    write!(_formatter, "Types.MetricContext.MetricContext(")?;
                    DafnyPrint::fmt_print(name, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(tags, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
            }
        }
    }

    impl PartialEq
        for MetricContext {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (MetricContext::MetricContext{name, tags, }, MetricContext::MetricContext{name: _2_name, tags: _2_tags, }) => {
                    name == _2_name && tags == _2_tags
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for MetricContext {}

    impl Hash
        for MetricContext {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                MetricContext::MetricContext{name, tags, } => {
                    Hash::hash(name, _state);
                    Hash::hash(tags, _state)
                },
            }
        }
    }

    impl AsRef<MetricContext>
        for MetricContext {
        fn as_ref(&self) -> &Self {
            self
        }
    }

    /// src/Types.dfy(57,3)
    #[derive(Clone)]
    pub enum DogStatsDConfig {
        DogStatsDConfig {
            maxBytesPerPayload: nat,
            bufferFlushIntervalMs: nat,
            aggregationFlushIntervalMs: nat,
            senderQueueSize: nat,
            bufferPoolCapacity: nat,
            aggregationEnabled: bool,
            extendedAggregation: bool,
            maxSamplesPerContext: DafnyInt,
            originDetection: bool,
            cardinality: Rc<TagCardinality>
        }
    }

    impl DogStatsDConfig {
        /// Returns a borrow of the field maxBytesPerPayload
        pub fn maxBytesPerPayload(&self) -> &nat {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => maxBytesPerPayload,
            }
        }
        /// Returns a borrow of the field bufferFlushIntervalMs
        pub fn bufferFlushIntervalMs(&self) -> &nat {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => bufferFlushIntervalMs,
            }
        }
        /// Returns a borrow of the field aggregationFlushIntervalMs
        pub fn aggregationFlushIntervalMs(&self) -> &nat {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => aggregationFlushIntervalMs,
            }
        }
        /// Returns a borrow of the field senderQueueSize
        pub fn senderQueueSize(&self) -> &nat {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => senderQueueSize,
            }
        }
        /// Returns a borrow of the field bufferPoolCapacity
        pub fn bufferPoolCapacity(&self) -> &nat {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => bufferPoolCapacity,
            }
        }
        /// Returns a borrow of the field aggregationEnabled
        pub fn aggregationEnabled(&self) -> &bool {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => aggregationEnabled,
            }
        }
        /// Returns a borrow of the field extendedAggregation
        pub fn extendedAggregation(&self) -> &bool {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => extendedAggregation,
            }
        }
        /// Returns a borrow of the field maxSamplesPerContext
        pub fn maxSamplesPerContext(&self) -> &DafnyInt {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => maxSamplesPerContext,
            }
        }
        /// Returns a borrow of the field originDetection
        pub fn originDetection(&self) -> &bool {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => originDetection,
            }
        }
        /// Returns a borrow of the field cardinality
        pub fn cardinality(&self) -> &Rc<TagCardinality> {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => cardinality,
            }
        }
    }

    impl Debug
        for DogStatsDConfig {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for DogStatsDConfig {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => {
                    write!(_formatter, "Types.DogStatsDConfig.DogStatsDConfig(")?;
                    DafnyPrint::fmt_print(maxBytesPerPayload, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(bufferFlushIntervalMs, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(aggregationFlushIntervalMs, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(senderQueueSize, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(bufferPoolCapacity, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(aggregationEnabled, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(extendedAggregation, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(maxSamplesPerContext, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(originDetection, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(cardinality, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
            }
        }
    }

    impl PartialEq
        for DogStatsDConfig {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, }, DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload: _2_maxBytesPerPayload, bufferFlushIntervalMs: _2_bufferFlushIntervalMs, aggregationFlushIntervalMs: _2_aggregationFlushIntervalMs, senderQueueSize: _2_senderQueueSize, bufferPoolCapacity: _2_bufferPoolCapacity, aggregationEnabled: _2_aggregationEnabled, extendedAggregation: _2_extendedAggregation, maxSamplesPerContext: _2_maxSamplesPerContext, originDetection: _2_originDetection, cardinality: _2_cardinality, }) => {
                    maxBytesPerPayload == _2_maxBytesPerPayload && bufferFlushIntervalMs == _2_bufferFlushIntervalMs && aggregationFlushIntervalMs == _2_aggregationFlushIntervalMs && senderQueueSize == _2_senderQueueSize && bufferPoolCapacity == _2_bufferPoolCapacity && aggregationEnabled == _2_aggregationEnabled && extendedAggregation == _2_extendedAggregation && maxSamplesPerContext == _2_maxSamplesPerContext && originDetection == _2_originDetection && cardinality == _2_cardinality
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for DogStatsDConfig {}

    impl Hash
        for DogStatsDConfig {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                DogStatsDConfig::DogStatsDConfig{maxBytesPerPayload, bufferFlushIntervalMs, aggregationFlushIntervalMs, senderQueueSize, bufferPoolCapacity, aggregationEnabled, extendedAggregation, maxSamplesPerContext, originDetection, cardinality, } => {
                    Hash::hash(maxBytesPerPayload, _state);
                    Hash::hash(bufferFlushIntervalMs, _state);
                    Hash::hash(aggregationFlushIntervalMs, _state);
                    Hash::hash(senderQueueSize, _state);
                    Hash::hash(bufferPoolCapacity, _state);
                    Hash::hash(aggregationEnabled, _state);
                    Hash::hash(extendedAggregation, _state);
                    Hash::hash(maxSamplesPerContext, _state);
                    Hash::hash(originDetection, _state);
                    Hash::hash(cardinality, _state)
                },
            }
        }
    }

    impl AsRef<DogStatsDConfig>
        for DogStatsDConfig {
        fn as_ref(&self) -> &Self {
            self
        }
    }
}
/// src/WireFormat.dfy(5,1)
pub mod WireFormat {
    pub use ::dafny_runtime::Sequence;
    pub use ::dafny_runtime::DafnyChar;
    pub use ::dafny_runtime::seq;
    pub use ::dafny_runtime::int;
    pub use ::dafny_runtime::DafnyInt;
    pub use ::dafny_runtime::truncate;
    pub use ::dafny_runtime::BigRational;
    pub use ::std::rc::Rc;
    pub use crate::Types::MetricType;
    pub use crate::Types::Option;
    pub use crate::Types::Option::None;
    pub use ::dafny_runtime::BigInt;
    pub use ::dafny_runtime::string_of;
    pub use crate::Types::TagCardinality;
    pub use ::std::primitive::char;
    pub use ::std::fmt::Debug;
    pub use ::std::fmt::Formatter;
    pub use ::std::fmt::Result;
    pub use ::dafny_runtime::DafnyPrint;
    pub use ::std::cmp::PartialEq;
    pub use ::std::cmp::Eq;
    pub use ::std::hash::Hash;
    pub use ::std::hash::Hasher;
    pub use ::std::convert::AsRef;

    pub struct _default {}

    impl _default {
        /// src/WireFormat.dfy(22,3)
        pub fn StringToBytes(s: &Sequence<DafnyChar>) -> Sequence<u8> {
            let mut _accumulator: Sequence<u8> = seq![] as Sequence<u8>;
            let mut _r0 = s.clone();
            'TAIL_CALL_START: loop {
                let s = _r0;
                if s.cardinality() == int!(0) {
                    return _accumulator.concat(&(seq![] as Sequence<u8>));
                } else {
                    let mut code: DafnyInt = int!(s.get(&int!(0)).0);
                    let mut bval: DafnyInt = if int!(0) <= code.clone() && code.clone() < int!(256) {
                            code.clone()
                        } else {
                            int!(0)
                        };
                    _accumulator = _accumulator.concat(&seq![truncate!(bval.clone(), u8)]);
                    let mut _in0: Sequence<DafnyChar> = s.drop(&int!(1));
                    _r0 = _in0.clone();
                    continue 'TAIL_CALL_START;
                }
            }
        }
        /// src/WireFormat.dfy(45,3)
        pub fn RealToDecimalBytes(r: &BigRational) -> Sequence<u8> {
            seq![] as Sequence<u8>
        }
        /// src/WireFormat.dfy(49,3)
        pub fn SerializeName(name: &Sequence<DafnyChar>) -> Sequence<u8> {
            _default::StringToBytes(name)
        }
        /// src/WireFormat.dfy(55,3)
        pub fn SerializeValue(value: &Sequence<DafnyChar>) -> Sequence<u8> {
            _default::StringToBytes(value)
        }
        /// src/WireFormat.dfy(61,3)
        pub fn SerializeType(t: &Rc<MetricType>) -> Sequence<u8> {
            _default::StringToBytes(&crate::Types::_default::MetricTypeSymbol(t))
        }
        /// src/WireFormat.dfy(67,3)
        pub fn SerializeRate(rate: &Rc<Option<BigRational>>) -> Sequence<u8> {
            if matches!(rate.as_ref(), None{ .. }) || rate.value().clone() >= BigRational::new(BigInt::parse_bytes(b"1", 10).unwrap(), BigInt::parse_bytes(b"1", 10).unwrap()) {
                seq![] as Sequence<u8>
            } else {
                _default::StringToBytes(&string_of("|@")).concat(&_default::RealToDecimalBytes(rate.value()))
            }
        }
        /// src/WireFormat.dfy(74,3)
        pub fn JoinTags(tags: &Sequence<Sequence<DafnyChar>>) -> Sequence<u8> {
            let mut _accumulator: Sequence<u8> = seq![] as Sequence<u8>;
            let mut _r0 = tags.clone();
            'TAIL_CALL_START: loop {
                let tags = _r0;
                if tags.cardinality() == int!(0) {
                    return _accumulator.concat(&(seq![] as Sequence<u8>));
                } else {
                    if tags.cardinality() == int!(1) {
                        return _accumulator.concat(&_default::StringToBytes(&tags.get(&int!(0))));
                    } else {
                        _accumulator = _accumulator.concat(&_default::StringToBytes(&tags.get(&int!(0))).concat(&_default::StringToBytes(&string_of(","))));
                        let mut _in0: Sequence<Sequence<DafnyChar>> = tags.drop(&int!(1));
                        _r0 = _in0.clone();
                        continue 'TAIL_CALL_START;
                    }
                }
            }
        }
        /// src/WireFormat.dfy(83,3)
        pub fn SerializeTags(tags: &Sequence<Sequence<DafnyChar>>) -> Sequence<u8> {
            if tags.cardinality() == int!(0) {
                seq![] as Sequence<u8>
            } else {
                _default::StringToBytes(&string_of("|#")).concat(&_default::JoinTags(tags))
            }
        }
        /// src/WireFormat.dfy(90,3)
        pub fn SerializeContainerID(cid: &Rc<Option<Sequence<DafnyChar>>>) -> Sequence<u8> {
            let mut _source0: Rc<Option<Sequence<DafnyChar>>> = cid.clone();
            if matches!((&_source0).as_ref(), None{ .. }) {
                seq![] as Sequence<u8>
            } else {
                let mut ___mcc_h0: Sequence<DafnyChar> = _source0.value().clone();
                let mut id: Sequence<DafnyChar> = ___mcc_h0.clone();
                _default::StringToBytes(&string_of("|c:")).concat(&_default::StringToBytes(&id))
            }
        }
        /// src/WireFormat.dfy(98,3)
        pub fn SerializeExternalEnv(env: &Rc<Option<Sequence<DafnyChar>>>) -> Sequence<u8> {
            let mut _source0: Rc<Option<Sequence<DafnyChar>>> = env.clone();
            if matches!((&_source0).as_ref(), None{ .. }) {
                seq![] as Sequence<u8>
            } else {
                let mut ___mcc_h0: Sequence<DafnyChar> = _source0.value().clone();
                let mut e: Sequence<DafnyChar> = ___mcc_h0.clone();
                if e.cardinality() == int!(0) {
                    seq![] as Sequence<u8>
                } else {
                    _default::StringToBytes(&string_of("|e:")).concat(&_default::StringToBytes(&e))
                }
            }
        }
        /// src/WireFormat.dfy(108,3)
        pub fn SerializeCardinality(c: &Rc<TagCardinality>) -> Sequence<u8> {
            let mut _source0: Rc<Option<Sequence<DafnyChar>>> = crate::Types::_default::CardinalityString(c);
            if matches!((&_source0).as_ref(), None{ .. }) {
                seq![] as Sequence<u8>
            } else {
                let mut ___mcc_h0: Sequence<DafnyChar> = _source0.value().clone();
                let mut s: Sequence<DafnyChar> = ___mcc_h0.clone();
                _default::StringToBytes(&string_of("|card:")).concat(&_default::StringToBytes(&s))
            }
        }
        /// src/WireFormat.dfy(117,3)
        pub fn SerializeWireFormat(m: &Rc<WireMetric>) -> Sequence<u8> {
            _default::SerializeName(m.name()).concat(&_default::StringToBytes(&string_of(":"))).concat(&_default::SerializeValue(m.value())).concat(&_default::StringToBytes(&string_of("|"))).concat(&_default::SerializeType(m.metricType())).concat(&_default::SerializeRate(m.rate())).concat(&_default::SerializeTags(m.tags())).concat(&_default::SerializeContainerID(m.containerID())).concat(&_default::SerializeExternalEnv(m.externalEnv())).concat(&_default::SerializeCardinality(m.cardinality())).concat(&seq![truncate!(int!(DafnyChar(char::from_u32(10).unwrap()).0), u8)])
        }
    }

    /// src/WireFormat.dfy(10,3)
    #[derive(Clone)]
    pub enum WireMetric {
        WireMetric {
            name: Sequence<DafnyChar>,
            value: Sequence<DafnyChar>,
            metricType: Rc<MetricType>,
            rate: Rc<Option<BigRational>>,
            tags: Sequence<Sequence<DafnyChar>>,
            containerID: Rc<Option<Sequence<DafnyChar>>>,
            externalEnv: Rc<Option<Sequence<DafnyChar>>>,
            cardinality: Rc<TagCardinality>
        }
    }

    impl WireMetric {
        /// Returns a borrow of the field name
        pub fn name(&self) -> &Sequence<DafnyChar> {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => name,
            }
        }
        /// Returns a borrow of the field value
        pub fn value(&self) -> &Sequence<DafnyChar> {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => value,
            }
        }
        /// Returns a borrow of the field metricType
        pub fn metricType(&self) -> &Rc<MetricType> {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => metricType,
            }
        }
        /// Returns a borrow of the field rate
        pub fn rate(&self) -> &Rc<Option<BigRational>> {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => rate,
            }
        }
        /// Returns a borrow of the field tags
        pub fn tags(&self) -> &Sequence<Sequence<DafnyChar>> {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => tags,
            }
        }
        /// Returns a borrow of the field containerID
        pub fn containerID(&self) -> &Rc<Option<Sequence<DafnyChar>>> {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => containerID,
            }
        }
        /// Returns a borrow of the field externalEnv
        pub fn externalEnv(&self) -> &Rc<Option<Sequence<DafnyChar>>> {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => externalEnv,
            }
        }
        /// Returns a borrow of the field cardinality
        pub fn cardinality(&self) -> &Rc<TagCardinality> {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => cardinality,
            }
        }
    }

    impl Debug
        for WireMetric {
        fn fmt(&self, f: &mut Formatter) -> Result {
            DafnyPrint::fmt_print(self, f, true)
        }
    }

    impl DafnyPrint
        for WireMetric {
        fn fmt_print(&self, _formatter: &mut Formatter, _in_seq: bool) -> std::fmt::Result {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => {
                    write!(_formatter, "WireFormat.WireMetric.WireMetric(")?;
                    DafnyPrint::fmt_print(name, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(value, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(metricType, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(rate, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(tags, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(containerID, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(externalEnv, _formatter, false)?;
                    write!(_formatter, ", ")?;
                    DafnyPrint::fmt_print(cardinality, _formatter, false)?;
                    write!(_formatter, ")")?;
                    Ok(())
                },
            }
        }
    }

    impl PartialEq
        for WireMetric {
        fn eq(&self, other: &Self) -> bool {
            match (
                    self,
                    other
                ) {
                (WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, }, WireMetric::WireMetric{name: _2_name, value: _2_value, metricType: _2_metricType, rate: _2_rate, tags: _2_tags, containerID: _2_containerID, externalEnv: _2_externalEnv, cardinality: _2_cardinality, }) => {
                    name == _2_name && value == _2_value && metricType == _2_metricType && rate == _2_rate && tags == _2_tags && containerID == _2_containerID && externalEnv == _2_externalEnv && cardinality == _2_cardinality
                },
                _ => {
                    false
                },
            }
        }
    }

    impl Eq
        for WireMetric {}

    impl Hash
        for WireMetric {
        fn hash<_H: Hasher>(&self, _state: &mut _H) {
            match self {
                WireMetric::WireMetric{name, value, metricType, rate, tags, containerID, externalEnv, cardinality, } => {
                    Hash::hash(name, _state);
                    Hash::hash(value, _state);
                    Hash::hash(metricType, _state);
                    Hash::hash(rate, _state);
                    Hash::hash(tags, _state);
                    Hash::hash(containerID, _state);
                    Hash::hash(externalEnv, _state);
                    Hash::hash(cardinality, _state)
                },
            }
        }
    }

    impl AsRef<WireMetric>
        for WireMetric {
        fn as_ref(&self) -> &Self {
            self
        }
    }
}