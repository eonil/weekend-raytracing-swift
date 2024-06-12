import Accelerate

/// Collection of 3D vectors composed of designated `Scalar` type.
struct Vector3Bucket {
    typealias Scalars = ContiguousArray<Scalar>
    var scalars = Scalars()
}

extension Vector3Bucket {
    var vectors: Vectors {
        get { Vectors(base: self) }
        set { self = newValue.base }
    }
    struct Vectors: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
        var base = Vector3Bucket()
        typealias Index = Int
        typealias Element = Vector3
        var startIndex: Int { 0 }
        var endIndex: Int { base.scalars.count / 3 }
        subscript(_ position: Index) -> Element {
            get {
                Vector3(
                    base.scalars[position * 3 + 0],
                    base.scalars[position * 3 + 1],
                    base.scalars[position * 3 + 2])
            }
            set {
                base.scalars[position * 3 + 0] = newValue.x
                base.scalars[position * 3 + 1] = newValue.y
                base.scalars[position * 3 + 2] = newValue.z
            }
        }
        mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, Vector3 == C.Element {
            for (i, x) in zip(subrange, newElements) {
                self[i] = x
            }
        }
    }
}

extension Vector3Bucket {
    static func + (_ a: Self, _ b: Self) -> Self {
        var c = Scalars()
        vDSP.add(a.scalars, b.scalars, result: &c)
        return Vector3Bucket(scalars: c)
    }
    static func + (_ a: Self, _ b: Vector3) -> Self {
        // TODO: Optimize this.
        var c = a
        for i in c.vectors.indices {
            c.vectors[i] += b
        }
        return c
    }
    static func + (_ a: Self, _ b: Scalar) -> Self {
        var c = Scalars()
        /// https://developer.apple.com/documentation/accelerate/vdsp/3240827-add
        vDSP.add(b, a.scalars, result: &c)
        return Vector3Bucket(scalars: c)
    
    }
    
    static func - (_ a: Self, _ b: Self) -> Self {
        var c = Scalars()
        vDSP.subtract(a.scalars, b.scalars, result: &c)
        return Vector3Bucket(scalars: c)
    }
    static func - (_ a: Self, _ b: Vector3) -> Self {
        // TODO: Optimize this.
        var c = a
        for i in c.vectors.indices {
            c.vectors[i] -= b
        }
        return c
    }
    static prefix func - (_ a: Self) -> Self {
        a * Vector3(-1, -1, -1)
    }
    
    /// Per-element multiplication. Not dot/cross product.
    static func * (_ a: Self, _ b: Self) -> Self {
        var c = Scalars()
        vDSP.multiply(a.scalars, b.scalars, result: &c)
        return Vector3Bucket(scalars: c)
    }
    /// Per-element multiplication. Not dot/cross product.
    static func * (_ a: Self, _ b: Vector3) -> Self {
        // TODO: Optimize this.
        var c = a
        for i in c.vectors.indices {
            c.vectors[i] *= b
        }
        return c
    }
    /// Per-element multiplication. Not dot/cross product.
    static func * (_ a: Self, _ b: ScalarBucket) -> Self {
        var c = Scalars()
        /// https://developer.apple.com/documentation/accelerate/vdsp/3241041-multiply
        vDSP.multiply(a.scalars, b.scalars, result: &c)
        return Vector3Bucket(scalars: c)
    }
    static func * (_ a: Self, _ b: Scalar) -> Self {
        // TODO: Optimize this.
        var c = a
        for i in c.vectors.indices {
            c.vectors[i] *= b
        }
        return c
    }
    
    static func / (_ a: Self, _ b: Self) -> Self {
        var c = Scalars()
        vDSP.divide(a.scalars, b.scalars, result: &c)
        return Vector3Bucket(scalars: c)
    }
    static func / (_ a: Self, _ b: Vector3) -> Self {
        // TODO: Optimize this.
        var c = a
        for i in c.vectors.indices {
            c.vectors[i] /= b
        }
        return c
    }
}

extension Vector3Bucket {
    static func dot (_ a: Self, _ b: Self) -> ScalarBucket {
        // TODO: Optimize more...
        var c = Scalars()
        for (aa, bb) in zip(a.vectors, b.vectors) {
            let cc = Vector3.dot(aa, bb)
            c.append(cc)
        }
        return ScalarBucket(scalars: c)
    }
    
    static func dot (_ a: Self, _ b: Vector3) -> ScalarBucket {
        // TODO: Optimize more...
        var c = Scalars()
        for aa in a.vectors {
            let cc = Vector3.dot(aa, b)
            c.append(cc)
        }
        return ScalarBucket(scalars: c)
    }
}

extension Vector3Bucket {
    var unit: UnitVector3Bucket {
        var bucket = UnitVector3Bucket()
        bucket.unitVectors.append(contentsOf: vectors.lazy.map(\.unit))
        return bucket
    }
    
    var lengthSquared: ScalarBucket {
        // TODO: Optimize this.
        var c = Scalars()
        for aa in vectors {
            let cc = aa.lengthSquared
            c.append(cc)
        }
        return ScalarBucket(scalars: c)
    }
}
