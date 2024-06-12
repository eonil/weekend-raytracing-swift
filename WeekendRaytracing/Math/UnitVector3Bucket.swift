import Accelerate

struct UnitVector3Bucket {
    var vector = Vector3Bucket()
    var unitVectors: UnitVectors {
        get {
            UnitVectors(base: self)
        }
        set {
            self = newValue.base
        }
    }
    struct UnitVectors: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
        var base = UnitVector3Bucket()
        var startIndex: Int { base.vector.vectors.startIndex }
        var endIndex: Int { base.vector.vectors.endIndex }
        subscript(_ i: Int) -> UnitVector3 {
            get {
                UnitVector3(base.vector.vectors[i])
            }
            set {
                base.vector.vectors[i] = newValue.vector
            }
        }
        mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, UnitVector3 == C.Element {
            base.vector.vectors.replaceSubrange(subrange, with: newElements.lazy.map { $0.vector })
        }
    }
}

extension UnitVector3Bucket {
    static func + (_ a: Self, _ b: Self) -> Self {
        UnitVector3Bucket(vector: a.vector + b.vector)
    }
    
    static func - (_ a: Self, _ b: Self) -> Self {
        UnitVector3Bucket(vector: a.vector - b.vector)
    }
    
    static func * (_ a: Self, _ b: Self) -> Self {
        UnitVector3Bucket(vector: a.vector * b.vector)
    }
    
    static func / (_ a: Self, _ b: Self) -> Self {
        UnitVector3Bucket(vector: a.vector / b.vector)
    }
}

extension UnitVector3Bucket {
    static func dot (_ a: Self, _ b: Self) -> ScalarBucket {
        Vector3Bucket.dot(a.vector, b.vector)
    }
}
