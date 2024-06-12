import Accelerate

/// Collection of flat 1D scalar values.
struct ScalarBucket {
    typealias Scalars = ContiguousArray<Scalar>
    var scalars = Scalars()
}

extension ScalarBucket {
    static func + (_ a: Self, _ b: Self) -> Self {
        var c = Scalars()
        vDSP.add(a.scalars, b.scalars, result: &c)
        return ScalarBucket(scalars: c)
    }
    static func + (_ a: Self, _ b: Scalar) -> Self {
        var c = Scalars()
        vDSP.add(a.scalars, [b], result: &c)
        return ScalarBucket(scalars: c)
    }
    
    static func - (_ a: Self, _ b: Self) -> Self {
        var c = Scalars()
        vDSP.subtract(a.scalars, b.scalars, result: &c)
        return ScalarBucket(scalars: c)
    }
    static func - (_ a: Self, _ b: Scalar) -> Self {
        var c = Scalars()
        vDSP.subtract(a.scalars, [b], result: &c)
        return ScalarBucket(scalars: c)
    }
    
    static func * (_ a: Self, _ b: Self) -> Self {
        var c = Scalars()
        vDSP.multiply(a.scalars, b.scalars, result: &c)
        return ScalarBucket(scalars: c)
    }
    static func * (_ a: Self, _ b: Scalar) -> Self {
        var c = Scalars()
        vDSP.multiply(a.scalars, [b], result: &c)
        return ScalarBucket(scalars: c)
    }
    
    static func / (_ a: Self, _ b: Self) -> Self {
        var c = Scalars()
        vDSP.divide(a.scalars, b.scalars, result: &c)
        return ScalarBucket(scalars: c)
    }
    static func / (_ a: Self, _ b: Scalar) -> Self {
        var c = Scalars()
        vDSP.divide(a.scalars, [b], result: &c)
        return ScalarBucket(scalars: c)
    }
}

extension ScalarBucket {
    func squareRoot() -> ScalarBucket {
        var c = Scalars()
        vForce.sqrt(scalars, result: &c)
        return ScalarBucket(scalars: c)
    }
}
