import Accelerate
import simd

typealias Pixel = SIMD4<UInt8>
typealias Scalar = Float32
typealias Vector2 = SIMD2<Scalar>
typealias Vector3 = SIMD3<Scalar>
typealias Point3 = SIMD3<Scalar>
typealias Color = Vector3
typealias Vector4 = SIMD4<Scalar>

struct Ray {
    var origin: Vector3
    /// Should always be normalized.
    var direction: UnitVector3
    
    func at(_ time: Scalar) -> Vector3 {
        origin + (direction.vector * time)
    }
}

extension Ray {
    func nearestHitWithAnything(in space: borrowing Space, at time: Time) -> Hit? {
        var nearestHit: Hit?
        for sphere in space.spheres {
            if let newHit = hit(with: sphere, at: time) {
                if let oldHit = nearestHit {
                    if abs(newHit.distance) < abs(oldHit.distance) {
                        nearestHit = newHit
                    }
                }
                else {
                    nearestHit = newHit
                }
            }
        }
        return nearestHit
    }
    func hit(with sphere: Sphere, at time: Time) -> Hit? {
        let ct = sphere.motion.sample(at: time)
        let oc = ct - origin
        let a = direction.vector.lengthSquared
        let h = dot(direction.vector, oc)
        let c = oc.lengthSquared - (sphere.radius * sphere.radius)
        let discriminant = (h * h) - (a * c)
        guard discriminant >= 0 else { return nil }
        let t = (h - discriminant.squareRoot()) / a;
        /// We consider hitting only on forward direction of th ray.
        guard t > 0 else { return nil }
        let p = origin + (direction.vector * t)
        let n = (p - ct).unit
        return Hit(distance: t, point: p, normal: n, material: sphere.material)
    }
}

struct Hit {
    /// Distance from `Ray.origin` to `Intersection.point`.
    var distance: Scalar
    var point: Vector3
    /// Surface normal direction vector. Always a unit vector.
    var normal: UnitVector3
    var material: Material
}

struct UnitVector3 {
    var vector: Vector3
    init(_ vector: Vector3) {
        assert(abs(vector.lengthSquared.distance(to: 1)) < 0.001)
        self.vector = vector
    }
    
    func isOnHemisphereDefined(by normal: UnitVector3) -> Bool {
        dot(vector, normal.vector) > 0
    }
    
    static prefix func - (_ a: Self) -> Self {
        Self(-a.vector)
    }
}


extension Scalar {
    func clamped(in range: ClosedRange<Self>) -> Self {
        simd_clamp(self, range.lowerBound, range.upperBound)
    }
}

extension SIMD3 where Scalar == Float32 {
    var unit: UnitVector3 {
        UnitVector3(simd_fast_normalize(self))
    }
    
    var lengthSquared: Scalar {
        simd_length_squared(self)
    }

    static prefix func - (_ a: Self) -> Self {
        a * -1
    }
    
    static func dot(_ a: Self, _ b: Self) -> Scalar {
        simd.dot(a, b)
    }
}
