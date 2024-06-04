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
    }
    var space: Space
}

struct Space {
    var spheres: [Sphere]
}

struct Sphere {
    var center: Vector3
    var radius: Float32
    var material: Material
}

enum Material {
    case constant(Color)
    case distance
    case normal
    case diffuse
    case mirror
}
