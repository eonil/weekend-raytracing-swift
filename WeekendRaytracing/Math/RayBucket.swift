struct RayBucket: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
    var origin = Vector3Bucket()
    /// Should always be normalized.
    var direction = UnitVector3Bucket()
    
    var startIndex: Int { 0 }
    var endIndex: Int { origin.vectors.count }
    subscript(_ i: Int) -> Ray {
        get {
            Ray(
                origin: origin.vectors[i],
                direction: UnitVector3(direction.vector.vectors[i]))
        }
        set {
            origin.vectors[i] = newValue.origin
            direction.unitVectors[i] = newValue.direction
        }
    }
    mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, Ray == C.Element {
        origin.vectors.replaceSubrange(subrange, with: newElements.lazy.map(\.origin))
        direction.unitVectors.replaceSubrange(subrange, with: newElements.lazy.map(\.direction))
    }
}

extension RayBucket {
    /// Produces same count of hits.
    /// - Returns: Hits in bucket. Rays with no hit will result `distance == .nan` at its index. All other values are undefined in this case.
    func hit(with sphere: Sphere, at time: Time) -> HitBucket {
        let ct = sphere.motion.sample(at: time)
        let oc = origin + -ct
        let a = direction.vector.lengthSquared
        let h = Vector3Bucket.dot(direction.vector, oc)
        let c = oc.lengthSquared - (sphere.radius * sphere.radius)
        let discriminant = (h * h) - (a * c)
        var t = (h - discriminant.squareRoot()) / a
        for i in discriminant.scalars.indices {
            t.scalars[i] = discriminant.scalars[i] >= 0 ? t.scalars[i] : Scalar.nan
        }
        /// We consider hitting only on forward direction of the ray.
        for i in t.scalars.indices {
            t.scalars[i] = t.scalars[i] > 0 ? t.scalars[i] : Scalar.nan
        }
        let p = origin + (direction.vector * t)
        let n = (-p + ct).unit
        return HitBucket(distance: t, point: p, normal: n, material: sphere.material)
    }
}

extension RayBucket {
    typealias Hit = HitBucket
}

struct HitBucket {
    /// Distance from `Ray.origin` to `Intersection.point`.
    /// Container `NaN` (silent) if nothing hit at the index.
    var distance = ScalarBucket()
    var point = Vector3Bucket()
    /// Surface normal direction vector. Always a unit vector.
    var normal = UnitVector3Bucket()
    var material: Material
}

