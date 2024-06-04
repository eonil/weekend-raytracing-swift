func compute(scene: Scene, into memory: UnsafeMutablePointer<Pixel>) {
    var randomMachine = scene.randomMachine
    let uint8MaxInScalar = Scalar(UInt8.max)
    let viewportSize = Vector2(Scalar(scene.viewport.width), Scalar(scene.viewport.height))
    let pixelBoxWidthInFilm = 1 / viewportSize.x
    let pixelBoxHeightInFilm = 1 / viewportSize.y
    let sampleIntensity = 1 / Float32(scene.quality.sampleCount)
    
    for y in 0..<scene.viewport.height {
        for x in 0..<scene.viewport.width {
            let p = (x, y)
            let c = color(at: p)
            memory[y * scene.viewport.width + x] = makePixel(from: c)
            func makePixel(from color: Color) -> Pixel {
                let c1 = color.clamped(lowerBound: .zero, upperBound: .one) * uint8MaxInScalar
                return Pixel(.max, UInt8(c1.x), UInt8(c1.y), UInt8(c1.z))
            }
        }
    }
    
    func color(at point: (x: Int, y: Int)) -> Color {
        switch scene.quality.sampleCount {
        case 0:
            return .zero
        case 1:
            /// Single sampling.
            let p = pointOnFilmForPixelIndex(at: Vector2(Float32(point.x), Float32(point.y)))
            let o = Vector3(p.x, p.y, +10)
            let d = Vector3(0, 0, -1).unit
            let r = Ray(origin: o, direction: d)
            let c = color(for: r)
            return c
        default:
            let p = pointOnFilmForPixelIndex(at: Vector2(Float32(point.x), Float32(point.y)))
            /// Multi-sampled anti-aliasing.
            var accumulatedColor = Color(0, 0, 0)
            for _ in 0..<scene.quality.sampleCount {
                let x = p.x + (randomMachine.randomFloat32() - 0.5) * pixelBoxWidthInFilm
                let y = p.y + (randomMachine.randomFloat32() - 0.5) * pixelBoxHeightInFilm
                let o = Vector3(x, y, +10)
                let d = Vector3(0, 0, -1).unit
                let r = Ray(origin: o, direction: d)
                let c = color(for: r)
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
        
        func color(for ray: Ray) -> Color {
            colorWithLimit(for: ray, maxDepth: scene.quality.reflectionLimit)
        }
        func colorWithLimit(for ray: Ray, maxDepth: Int) -> Color {
            guard maxDepth > 0 else { return .zero }
            guard let hit = ray.nearestHitWithAnything(in: scene.space) else { return skyColor(for: ray) }
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
                let lightAbsorption = 0.5 as Float32
                let reflectionColor = colorWithLimit(for: reflectionRay, maxDepth: maxDepth - 1)
                return lightAbsorption * reflectionColor
            case .mirror:
                let reflectionDirection = (ray.direction.vector - (2 * dot(ray.direction.vector, hit.normal.vector) * hit.normal.vector)).unit
                let reflectionRay = Ray(origin: hit.point, direction: reflectionDirection)
                let lightAbsorption = 0.85 as Float32
                let reflectionColor = colorWithLimit(for: reflectionRay, maxDepth: maxDepth - 1)
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
