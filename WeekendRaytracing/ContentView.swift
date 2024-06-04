import SwiftUI
import MetalKit

struct ContentView: View {
    var body: some View {
        VStack {
            TimelineView(.animation) { context in
                Rep(timestamp: context.date)
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

private extension ContentView {
    struct Rep: NSViewRepresentable {
        var timestamp: Date
        func makeNSView(context: Context) -> Impl {
            Impl()
        }
        func updateNSView(_ impl: Impl, context: Context) {
            impl.updateScene(timestamp: timestamp)
            impl.drawScene()
        }
        
        final class Impl: NSView {
            private let filmWidth = 256
            private let filmHeight = 256
            private var buffers: (front: CVPixelBuffer, back: CVPixelBuffer)
            
            init() {
                buffers = (makeBuffer(filmWidth, filmHeight), makeBuffer(filmWidth, filmHeight))
                func makeBuffer(_ filmWidth: Int, _ filmHeight: Int) -> CVPixelBuffer {
                    let attrs = [
                        kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey: true as NSNumber,
                    ] as CFDictionary
                    
                    var bufferOutput: CVPixelBuffer?
                    let result = CVPixelBufferCreate(nil, filmWidth, filmHeight, kCVPixelFormatType_32ARGB, attrs, &bufferOutput)
                    assert(result == kCVReturnSuccess)
                    assert(bufferOutput != nil)
                    let buffer = bufferOutput!
                    assert(CVPixelBufferGetWidth(buffer) == filmWidth)
                    assert(CVPixelBufferGetHeight(buffer) == filmHeight)
                    assert(CVPixelBufferGetIOSurface(buffer) != nil)
                    return buffer
                }
                super.init(frame: .zero)
            }
            required init?(coder: NSCoder) {
                fatalError("Unsupported.")
            }
            override func makeBackingLayer() -> CALayer {
                let film = CALayer()
                let surface = CVPixelBufferGetIOSurface(buffers.0)!.takeRetainedValue()
                film.allowsEdgeAntialiasing = false
                film.allowsGroupOpacity = false
                film.minificationFilter = .nearest
                film.magnificationFilter = .nearest
                film.contents = surface
                assert(film.contents != nil)
                return film
            }
            
            func updatePixels(_ mutate: (UnsafeMutableBufferPointer<Pixel>) -> Void) {
                assert(MemoryLayout<Pixel>.size == 4)
                let buffer = buffers.0
                CVPixelBufferLockBaseAddress(buffer, [])
                let uptr = CVPixelBufferGetBaseAddress(buffer)!
                uptr.withMemoryRebound(to: Pixel.self, capacity: filmWidth * filmHeight, { ptr in
                    mutate(UnsafeMutableBufferPointer(start: ptr, count: filmWidth * filmHeight))
                })
                CVPixelBufferUnlockBaseAddress(buffer, [])
//                buffers = (buffers.1, buffers.0)
//                let surface = CVPixelBufferGetIOSurface(buffers.0)!.takeRetainedValue()
//                layer?.contents = surface
            }
            
            var scene: Scene?
            func makeInitialScene() -> Scene {
                Scene(
                    randomMachine: PCG.PRNG(),
                    viewport: Scene.Viewport(
                        width: filmWidth,
                        height: filmHeight),
                    quality: Scene.Quality(
                        sampleCount: 4,
                        reflectionLimit: 4),
                    space: Space(
                        spheres: [
                            Sphere(center: Vector3(0, 0, 0), radius: 0.3, material: .mirror),
                            Sphere(center: Vector3(-0.3, -0.1, 0), radius: 0.1, material: .diffuse),
                            Sphere(center: Vector3(0, +5.65, -2), radius: 5.75, material: .diffuse),
                        ]))
            }
            
            func updateScene(timestamp: Date) {
                if scene == nil {
                    scene = makeInitialScene()
                }
                _ = scene?.randomMachine.random()
                let seconds = timestamp.timeIntervalSince1970
                scene?.space.spheres[0].center.x = Float32(cos(seconds * 5)) * 0.5
            }
            
            func drawScene() {
                guard let scene = scene else { return }
                updatePixels { ptr in
                    let start = Date.now
                    compute(scene: scene, into: ptr.baseAddress!)
                    let end = Date.now
                    print(end.timeIntervalSince(start))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
