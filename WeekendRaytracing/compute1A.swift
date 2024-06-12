///
func compute1A(scene: borrowing Scene, into memory: inout ContiguousArray<Pixel>) {
    var randomMachine = scene.randomMachine
    let uint8MaxInScalar = Scalar(UInt8.max)
    let viewportSize = Vector2(Scalar(scene.viewport.width), Scalar(scene.viewport.height))
    let pixelBoxWidthInFilm = 1 / viewportSize.x
    let pixelBoxHeightInFilm = 1 / viewportSize.y
    let pixelBoxSizeInFilm = Vector3(pixelBoxWidthInFilm, pixelBoxHeightInFilm, 0)
   
    var pixelColors = ContiguousArray<Color>(repeating: .zero, count: memory.count)
    accumulateSamples()
    projectColorsOntoPixels()
    
    func accumulateSamples() {
        for i in 0..<scene.quality.sampleCount {
            let baseColorMixRate = Scalar(i) / Scalar(i + 1)
            let additionColorMixRate = Scalar(1) / Scalar(i + 1)
            for y in 0..<scene.viewport.height {
                for x in 0..<scene.viewport.width {
                    let p = (x, y)
                    let c = color(at: p)
                    let k = y * scene.viewport.width + x
                    pixelColors[k] = (pixelColors[k] * baseColorMixRate) + (c * additionColorMixRate)
                }
            }
        }
    }
    
    func projectColorsOntoPixels() {
        for y in 0..<scene.viewport.height {
            for x in 0..<scene.viewport.width {
                let c = pixelColors[y * scene.viewport.width + x]
                memory[y * scene.viewport.width + x] = makePixel(from: c)
                func makePixel(from color: Color) -> Pixel {
                    let c1 = color.clamped(lowerBound: .zero, upperBound: .one) * uint8MaxInScalar
                    return Pixel(UInt8(c1.x), UInt8(c1.y), UInt8(c1.z), .max)
                }
            }
        }
    }
    
    func color(at point: (x: Int, y: Int)) -> Color {
        let pixelOrigin = Vector2(
            Scalar(point.x),
            Scalar(point.y))
        let pixelCenterInFilm = Vector3(
            pixelOrigin.x / viewportSize.x - 0.5,
            pixelOrigin.y / viewportSize.y - 0.5,
            +10)
        let pixelBoxInFilm = AABB3(
            min: pixelCenterInFilm - pixelBoxSizeInFilm,
            max: pixelCenterInFilm + pixelBoxSizeInFilm)
        let r = Ray(
            origin: randomMachine.randomPointVector3(in: pixelBoxInFilm),
            direction: Vector3(0, 0, -1).unit)
        let t = scene.time.point
        let q = t + (randomMachine.randomScalar() - 0.5) * scene.quality.motionBlurTime
        let c = color(for: r, at: Time(point: q))
        return c
        
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
            case .zero:
                return .zero
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
