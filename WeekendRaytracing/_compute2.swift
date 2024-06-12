/////
///// Computes final pixel colors.
/////
///// - This is same with `compute1`, but performed with more batch-friendly datastructures.
/////
//func compute2(scene: borrowing Scene, into memory: inout ContiguousArray<Pixel>) {
//    var randomMachine = scene.randomMachine
//    let uint8MaxInScalar = Scalar(UInt8.max)
//    let viewportSize = Vector2(Scalar(scene.viewport.width), Scalar(scene.viewport.height))
//    let pixelBoxWidthInFilm = 1 / viewportSize.x
//    let pixelBoxHeightInFilm = 1 / viewportSize.y
//    let sampleIntensity = 1 / Scalar(scene.quality.sampleCount)
//    
//    var filmPixelSamples = SampleBucket()
//    var filmPixelColors = ContiguousArray<Color>()
//    for y in 0..<scene.viewport.height {
//        for x in 0..<scene.viewport.width {
//            appendFilmPixelSamplesInBox(at: (x, y))
//        }
//    }
//    
//    for sample in filmPixelSamples.samples {
//        accumulateFilmSampleColors(with: sample)
//    }
//    printOnMemory()
//    
//    func appendFilmPixelSamplesInBox(at index: (x: Int, y: Int)) {
//        let p = pointOnFilmForPixelIndex(at: Vector2(Scalar(index.x), Scalar(index.y)))
//        func pointOnFilmForPixelIndex(at pixelIndex: Vector2) -> Vector3 {
//            Vector3(
//                pixelIndex.x / viewportSize.x - 0.5,
//                pixelIndex.y / viewportSize.y - 0.5,
//                0)
//        }
//        let t = scene.time.point
//        /// Multi-sampled anti-aliasing.
//        for _ in 0..<scene.quality.sampleCount {
//            let x = p.x + (randomMachine.randomScalar() - 0.5) * pixelBoxWidthInFilm
//            let y = p.y + (randomMachine.randomScalar() - 0.5) * pixelBoxHeightInFilm
//            let o = Vector3(x, y, +10)
//            let d = Vector3(0, 0, -1).unit
//            let r = Ray(origin: o, direction: d)
//            let q = t + (randomMachine.randomScalar() - 0.5) * scene.quality.motionBlurTime
//            let s = Sample(pixel: index, ray: r, time: Time(point: q), intensity: sampleIntensity)
//            filmPixelSamples.samples.append(s)
//        }
//    }
//    
//    struct Shading {
//        var ray: Ray
//        var time: Time
//        /// Remaining reflection depth limit.
//        /// If this reaches to `0`, shader will just return zero color.
//        var limit: Int
//    }
//    
//    func accumulateFilmSampleColors(with sample: Sample) {
//        let c = shade(for: sample.ray, at: sample.time) * sample.intensity
//        filmPixelColors[sample.pixel.y * scene.viewport.width + sample.pixel.x] += c
//        
//        func shade(for ray: Ray, at time: Time) -> Color {
//            shadeWithLimit(for: ray, at: time, maxDepth: scene.quality.reflectionLimit)
//        }
//        func shadeWithLimit(for ray: Ray, at time: Time, maxDepth: Int) -> Color {
//            guard maxDepth > 0 else { return .zero }
//            guard let hit = ray.nearestHitWithAnything(in: scene.space, at: time) else { return skyColor(for: ray) }
//            func skyColor(for ray: Ray) -> Color {
//                let u = ray.direction.vector
//                let a = 0.5 * (u.y + 1)
//                return (1-a) * Color(1, 1, 1) + (a * Color(0.5, 0.7, 1.0))
//            }
//            
//            switch hit.material {
//            case .zero:
//                return .zero
//            case .constant(let color):
//                return color
//            case .distance:
//                let d = hit.distance / 10
//                return Color(d, d, d)
//            case .normal:
//                return (hit.normal.vector + Vector3(1, 1, 1)) * 0.5
//            case .diffuse:
//                let randomDirection = ((randomMachine.randomVector3() * 2) - Vector3(1, 1, 1)).unit
//                let reflectionDirection = if randomDirection.isOnHemisphereDefined(by: hit.normal) { randomDirection } else { -randomDirection }
//                let reflectionRay = Ray(origin: hit.point, direction: reflectionDirection)
//                let lightAbsorption = 0.5 as Scalar
//                let reflectionColor = shadeWithLimit(for: reflectionRay, at: time, maxDepth: maxDepth - 1)
//                return lightAbsorption * reflectionColor
//            case .mirror:
//                let reflectionDirection = (ray.direction.vector - (2 * Vector3.dot(ray.direction.vector, hit.normal.vector) * hit.normal.vector)).unit
//                let reflectionRay = Ray(origin: hit.point, direction: reflectionDirection)
//                let lightAbsorption = 0.85 as Scalar
//                let reflectionColor = shadeWithLimit(for: reflectionRay, at: time, maxDepth: maxDepth - 1)
//                return lightAbsorption * reflectionColor
//            }
//        }
//    }
//    
//    func printOnMemory() {
//        for i in filmPixelColors.indices {
//            memory[i] = makePixel(from: filmPixelColors[i])
//        }
//        func makePixel(from color: Color) -> Pixel {
//            let c1 = color.clamped(lowerBound: .zero, upperBound: .one) * uint8MaxInScalar
//            return Pixel(UInt8(c1.x), UInt8(c1.y), UInt8(c1.z), .max)
//        }
//    }
//}
