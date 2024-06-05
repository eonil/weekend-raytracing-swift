import MetalKit

struct Scene {
    var randomMachine = PCG.PRNG()
    
    var viewport: Viewport
    struct Viewport {
        var width: Int
        var height: Int
    }
    
    var quality: Quality
    struct Quality {
        var sampleCount: Int
        var reflectionLimit: Int
        var motionBlurTime: Scalar
    }
    
    var space: Space
    var time: Time
}

struct Space {
    var spheres: [Sphere]
}

struct Time {
    var point: Scalar
}


struct Sphere {
    var motion: Motion
    enum Motion {
        case stopped(Vector3)
        case vibrateOnXYAxis(center: Vector3, width: Scalar, height: Scalar, speed: Scalar)
        
        func sample(at time: Time) -> Vector3 {
            switch self {
            case let .stopped(p): p
            case let .vibrateOnXYAxis(center, width, height, speed):
                center + Vector3(
                    Scalar(cos(time.point * speed)) * width * 0.5,
                    Scalar(sin(time.point * speed * 5)) * height * 0.5,
                    0)
            }
        }
    }
    var radius: Scalar
    var material: Material
}

enum Material {
    case constant(Color)
    case distance
    case normal
    case diffuse
    case mirror
}
