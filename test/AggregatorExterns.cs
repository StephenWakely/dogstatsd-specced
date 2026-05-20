using System.Numerics;
namespace Aggregator {
    public partial class __default {
        public static Dafny.ISequence<Dafny.Rune> IntToString(BigInteger n) {
            return Dafny.Sequence<Dafny.Rune>.UnicodeFromString(n.ToString());
        }
        public static Dafny.ISequence<Dafny.Rune> RealToString(Dafny.BigRational r) {
            return Dafny.Sequence<Dafny.Rune>.UnicodeFromString(r.ToString());
        }
    }
}
