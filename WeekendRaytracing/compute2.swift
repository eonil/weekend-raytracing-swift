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
//    var shadings = [Shade]()
//    for y in 0..<scene.viewport.height {
//        for x in 0..<scene.viewport.width {
//            let p = pointOnFilmForPixelIndex(at: Vector2(Scalar(x), Scalar(y)))
//            func pointOnFilmForPixelIndex(at pixelIndex: Vector2) -> Vector3 {
//                Vector3(
//                    pixelIndex.x / viewportSize.x - 0.5,
//                    pixelIndex.y / viewportSize.y - 0.5,
//                    0)
//            }
//            let o = Vector3(p.x, p.y, +10)
//            let d = Vector3(0, 0, -1).unit
//            let r = Ray(origin: o, direction: d)
//            let s = Shade(
//                location: (x, y),
//                intensity: 1,
//                ray: r,
//                time: scene.time,
//                reflectionLimit: scene.quality.reflectionLimit,
//                energyKeepRate: 1)
//            shadings.append(s)
//            
//            color(at: p)
//            func color(at point: (x: Int, y: Int)) {
//                switch scene.quality.sampleCount {
//                case 0:
//                    break
//                case 1:
//                    /// Single sampling.
//                    let p = pointOnFilmForPixelIndex(at: Vector2(Scalar(point.x), Scalar(point.y)))
//                    let o = Vector3(p.x, p.y, +10)
//                    let d = Vector3(0, 0, -1).unit
//                    let r = Ray(origin: o, direction: d)
//                    let s = Shade(
//                        location: point,
//                        intensity: 1,
//                        ray: r,
//                        time: scene.time,
//                        reflectionLimit: scene.quality.reflectionLimit,
//                        energyKeepRate: 1)
//                    shadings.append(s)
//                default:
//                    let p = pointOnFilmForPixelIndex(at: Vector2(Scalar(point.x), Scalar(point.y)))
//                    let t = scene.time.point
//                    /// Multi-sampled for anti-aliasing & motion blur.
//                    for _ in 0..<scene.quality.sampleCount {
//                        let x = p.x + (randomMachine.randomScalar() - 0.5) * pixelBoxWidthInFilm
//                        let y = p.y + (randomMachine.randomScalar() - 0.5) * pixelBoxHeightInFilm
//                        let o = Vector3(x, y, +10)
//                        let d = Vector3(0, 0, -1).unit
//                        let r = Ray(origin: o, direction: d)
//                        let q = t + (randomMachine.randomScalar() - 0.5) * scene.quality.motionBlurTime
//                        let s = Shade(
//                            location: point,
//                            intensity: sampleIntensity,
//                            ray: r,
//                            time: Time(point: q),
//                            reflectionLimit: scene.quality.reflectionLimit,
//                            energyKeepRate: 1)
//                        shadings.append(s)
//                    }
//                }
//                
//                func pointOnFilmForPixelIndex(at pixelIndex: Vector2) -> Vector3 {
//                    Vector3(
//                        pixelIndex.x / viewportSize.x - 0.5,
//                        pixelIndex.y / viewportSize.y - 0.5,
//                        0)
//                }
//            }
//            
//            memory[y * scene.viewport.width + x] = makePixel(from: c)
//            func makePixel(from color: Color) -> Pixel {
//                let c1 = color.clamped(lowerBound: .zero, upperBound: .one) * uint8MaxInScalar
//                return Pixel(UInt8(c1.x), UInt8(c1.y), UInt8(c1.z), .max)
//            }
//        }
//    }
//    
//    let priorShadings = shadings
//    var nextShadings = [Shade]()
//    for s in priorShadings {
//        func collect(_ s: Shade) {
//            nextShadings.append(s)
//        }
//        func accumulate(_ p: (x: Int, y: Int), _ c: Color) {
//            let (x, y) = p
//            memory[y * scene.viewport.width + x] = makePixel(from: c)
//        }
//        s.run(with: scene, random: &randomMachine, collect: collect, accumulate: accumulate)
//    }
//    
//    
//    
//    struct Shade {
//        var location: Location
//        typealias Location = (x: Int, y: Int)
//        var intensity: Scalar
//        var ray: Ray
//        var time: Time
//        var reflectionLimit: Int
//        var energyKeepRate: Scalar
//        
//        func run(with scene: Scene, random randomMachine: inout PCG.PRNG, collect: (Shade) -> Void, accumulate: (Location, Color) -> Void) {
//            guard reflectionLimit > 0 else { return }
//            guard let hit = ray.nearestHitWithAnything(in: scene.space, at: time) else {
//                let c = skyColor(for: ray) * energyKeepRate
//                accumulate(location, c)
//                return
//            }
//            
//            switch hit.material {
//            case .zero:
//                accumulate(location, .zero)
//            case .constant(let color):
//                accumulate(location, color)
//            case .distance:
//                let d = hit.distance / 10
//                accumulate(location, Color(d, d, d))
//            case .normal:
//                let c = (hit.normal.vector + Vector3(1, 1, 1)) * 0.5
//                accumulate(location, c)
//            case .diffuse:
//                let randomDirection = ((randomMachine.randomVector3() * 2) - Vector3(1, 1, 1)).unit
//                let reflectionDirection = if randomDirection.isOnHemisphereDefined(by: hit.normal) { randomDirection } else { -randomDirection }
//                let reflectionRay = Ray(origin: hit.point, direction: reflectionDirection)
//                let s = Shade(
//                    location: location,
//                    intensity: intensity,
//                    ray: reflectionRay,
//                    time: time,
//                    reflectionLimit: reflectionLimit - 1,
//                    energyKeepRate: 0.5)
//                collect(s)
//            case .mirror:
//                let reflectionDirection = (ray.direction.vector - (2 * Vector3.dot(ray.direction.vector, hit.normal.vector) * hit.normal.vector)).unit
//                let reflectionRay = Ray(origin: hit.point, direction: reflectionDirection)
//                let s = Shade(
//                    location: location,
//                    intensity: intensity,
//                    ray: reflectionRay,
//                    time: time,
//                    reflectionLimit: reflectionLimit - 1,
//                    energyKeepRate: 0.5)
//                collect(s)
//            }
//            
//            func skyColor(for ray: Ray) -> Color {
//                let u = ray.direction.vector
//                let a = 0.5 * (u.y + 1)
//                return (1-a) * Color(1, 1, 1) + (a * Color(0.5, 0.7, 1.0))
//            }
//        }
//    }
//}
