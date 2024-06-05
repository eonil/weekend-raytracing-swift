///
/// Computes final pixel colors.
///
/// - Do not try to span calculations over multiple cores.
///     - It doesn't help.
///     - Because parallelism is already been handled by `Accelerate.framework`.
///     - If we span workload over multiple threads, it just makes `Accelrate.framework` to work harder as now they have to collect and synchronize all the data coming from different cores.
///     - Most of floating-point calculations are done by AMX coprocessor. (not by CPU cores).
///     - And AMX coprocessor is not attached to all CPU cores.
///     - Therefore, if we run tasks on multiple cores, the cores will fight for (likely) single AMX coprocessor.
///     - Very well explained [here](https://stackoverflow.com/a/69459361/246776).
func compute(scene: borrowing Scene, into memory: inout ContiguousArray<Pixel>) {
    var randomMachine = scene.randomMachine
    let uint8MaxInScalar = Scalar(UInt8.max)
    let viewportSize = Vector2(Scalar(scene.viewport.width), Scalar(scene.viewport.height))
    let pixelBoxWidthInFilm = 1 / viewportSize.x
    let pixelBoxHeightInFilm = 1 / viewportSize.y
    let sampleIntensity = 1 / Scalar(scene.quality.sampleCount)
    
    for y in 0..<scene.viewport.height {
        for x in 0..<scene.viewport.width {
            let p = (x, y)
            let c = color(at: p)
            memory[y * scene.viewport.width + x] = makePixel(from: c)
            func makePixel(from color: Color) -> Pixel {
                let c1 = color.clamped(lowerBound: .zero, upperBound: .one) * uint8MaxInScalar
                return Pixel(UInt8(c1.x), UInt8(c1.y), UInt8(c1.z), .max)
            }
        }
    }
    
    func color(at point: (x: Int, y: Int)) -> Color {
        switch scene.quality.sampleCount {
        case 0:
            return .zero
        case 1:
            /// Single sampling.
            let p = pointOnFilmForPixelIndex(at: Vector2(Scalar(point.x), Scalar(point.y)))
            let o = Vector3(p.x, p.y, +10)
            let d = Vector3(0, 0, -1).unit
            let r = Ray(origin: o, direction: d)
            let c = color(for: r, at: scene.time)
            return c
        default:
            let p = pointOnFilmForPixelIndex(at: Vector2(Scalar(point.x), Scalar(point.y)))
            let t = scene.time.point
            /// Multi-sampled anti-aliasing.
            var accumulatedColor = Color(0, 0, 0)
            for _ in 0..<scene.quality.sampleCount {
                let x = p.x + (randomMachine.randomScalar() - 0.5) * pixelBoxWidthInFilm
                let y = p.y + (randomMachine.randomScalar() - 0.5) * pixelBoxHeightInFilm
                let o = Vector3(x, y, +10)
                let d = Vector3(0, 0, -1).unit
                let r = Ray(origin: o, direction: d)
                let q = t + (randomMachine.randomScalar() - 0.5) * scene.quality.motionBlurTime
                let c = color(for: r, at: Time(point: q))
                accumulatedColor += c * sampleIntensity
            }
            return accumulatedColor
        }
        
        func pointOnFilmForPixelIndex(at pixelIndex: Vector2) -> Vector3 {
            Vector3(
                pixelIndex.x / viewportSize.x - 0.5,
                pixelIndex.y / viewportSize.y - 0.5,
                0)
        }
        
        func color(for ray: Ray, at time: Time) -> Color {
            colorWithLimit(for: ray, at: time, maxDepth: scene.quality.reflectionLimit)
        }
        func colorWithLimit(for ray: Ray, at time: Time, maxDepth: Int) -> Color {
            guard maxDepth > 0 else { return .zero }
            guard let hit = ray.nearestHitWithAnything(in: scene.space, at: time) else { return skyColor(for: ray) }
            switch hit.material {
            case .constant(let color):
                return color
            case .distance:
                let d = hit.distance / 10
                return Color(d, d, d)
            case .normal:
                return (hit.normal.vector + Vector3(1, 1, 1)) * 0.5
            case .diffuse:
                let randomDirection = ((randomMachine.randomVector3() * 2) - Vector3(1, 1, 1)).unit
                let reflectionDirection = if randomDirection.isOnHemisphereDefined(by: hit.normal) { randomDirection } else { -randomDirection }
                let reflectionRay = Ray(origin: hit.point, direction: reflectionDirection)
                let lightAbsorption = 0.5 as Scalar
                let reflectionColor = colorWithLimit(for: reflectionRay, at: time, maxDepth: maxDepth - 1)
                return lightAbsorption * reflectionColor
            case .mirror:
                let reflectionDirection = (ray.direction.vector - (2 * Vector3.dot(ray.direction.vector, hit.normal.vector) * hit.normal.vector)).unit
                let reflectionRay = Ray(origin: hit.point, direction: reflectionDirection)
                let lightAbsorption = 0.85 as Scalar
                let reflectionColor = colorWithLimit(for: reflectionRay, at: time, maxDepth: maxDepth - 1)
                return lightAbsorption * reflectionColor
            }
        }
    }
    
    func skyColor(for ray: Ray) -> Color {
        let u = ray.direction.vector
        let a = 0.5 * (u.y + 1)
        return (1-a) * Color(1, 1, 1) + (a * Color(0.5, 0.7, 1.0))
    }
}
