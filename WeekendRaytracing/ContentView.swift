import SwiftUI
import MetalKit

struct ContentView: View {
    @State private var isPaused = false
    @State private var quality = Scene.Quality(
        sampleCount: 3,
        reflectionLimit: 3,
        motionBlurTime: 0.0125)
    @State private var frameTime = TimeInterval(0)
    @State private var sampleCountText = "1"

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: isPaused)) { context in
            Rep(quality: quality, timestamp: context.date, frameTime: $frameTime)
                .aspectRatio(contentMode: .fit)
        }
        .overlay(alignment: .bottomTrailing) {
            GroupBox {
                VStack {
                    Button("Pause/Resume", action: togglePaused)
                    TextField("", text: $sampleCountText)
                        .onSubmit {
                            quality.sampleCount = Int(sampleCountText) ?? 1
                            sampleCountText = quality.sampleCount.description
                        }
                    Slider(value: $quality.motionBlurTime, in: 0.0125...1) {
                        Text("Motion Blur")
                    } minimumValueLabel: {
                        Text("0.0125")
                    } maximumValueLabel: {
                        Text("1.0")
                    }
                }
            }
            .frame(width: 300)
            .groupBoxStyle(.automatic)
        }
    }
    func togglePaused() {
        isPaused.toggle()
    }
}

private extension ContentView {
    @MainActor
    struct Rep: NSViewRepresentable {
        var quality: Scene.Quality
        var timestamp: Date
        @Binding var frameTime: TimeInterval
        
        @MainActor
        func makeNSView(context: Context) -> Impl {
            Impl()
        }
        @MainActor
        func updateNSView(_ impl: Impl, context: Context) {
            impl.updateScene(quality: quality, timestamp: timestamp)
            frameTime = impl.drawScene()
        }
        
        /// https://metalbyexample.com/up-and-running-1/
        /// https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/PersistentObjects.html
        @MainActor
        final class Impl: NSView {
            private let filmWidth = 256
            private let filmHeight = 256
            private let commandQueue: MTLCommandQueue
            private let imageContext: CIContext
            
            init() {
                let metalLayer = CAMetalLayer()
                metalLayer.device = metalLayer.preferredDevice!
                /// Default pixel format is `bgra8Unorm`.
                metalLayer.pixelFormat = .rgba8Unorm
                /// Default is set to writable framebuffer texture.
                metalLayer.framebufferOnly = false
                /// Force certain size as we can cover only certain pixel size.
                metalLayer.drawableSize = CGSize(width: filmWidth, height: filmHeight)
                /// V-synced by default.
                metalLayer.allowsEdgeAntialiasing = false
                metalLayer.allowsGroupOpacity = false
                metalLayer.minificationFilter = .nearest
                metalLayer.magnificationFilter = .nearest
                commandQueue = metalLayer.device!.makeCommandQueue()!
                imageContext = CIContext(mtlDevice: metalLayer.device!)
                super.init(frame: .zero)
                wantsLayer = true
                layer = metalLayer
            }
            required init?(coder: NSCoder) {
                fatalError("Unsupported.")
            }
            var metalLayer: CAMetalLayer {
                layer! as! CAMetalLayer
            }
            
            var scene: Scene?
            func makeInitialScene(quality: Scene.Quality) -> Scene {
                Scene(
                    randomMachine: PCG.PRNG(),
                    viewport: Scene.Viewport(
                        width: filmWidth,
                        height: filmHeight),
                    quality: quality,
                    space: Space(
                        spheres: [
//                            Sphere(center: Vector3(0, 0, 0), radius: 0.3, material: .normal),
                            Sphere(motion: .vibrateOnXYAxis(center: .zero, width: 1, height: 0.1, speed: 1), radius: 0.3, material: .mirror),
                            Sphere(motion: .stopped(Vector3(-0.3, -0.1, 0)), radius: 0.1, material: .diffuse),
                            Sphere(motion: .stopped(Vector3(0, +5.65, -2)), radius: 5.75, material: .diffuse),
                        ]),
                    time: Time(
                        point: .zero))
            }
            
            private var firstTime: Date?
            func updateScene(quality: Scene.Quality, timestamp: Date) {
                if scene == nil {
                    scene = makeInitialScene(quality: quality)
                }
                if firstTime == nil {
                    firstTime = timestamp
                }
                _ = scene!.randomMachine.random()
                scene!.quality = quality
                let secs = timestamp.timeIntervalSince(firstTime!)
                scene!.time.point = Scalar(secs)
            }
            
            func drawScene() -> TimeInterval {
                autoreleasepool {
                    guard let scene = scene else { return 0 }
                    let commands = commandQueue.makeCommandBuffer()!
                    let drawable = metalLayer.nextDrawable()!

                    let pass = MTLRenderPassDescriptor()
                    pass.colorAttachments[0].texture = drawable.texture
                    pass.colorAttachments[0].loadAction = .clear
                    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
                    let render = commands.makeRenderCommandEncoder(descriptor: pass)!
                    render.endEncoding()
                    
                    let colorSpace = CGColorSpaceCreateDeviceRGB()
                    var bitmapPixels = ContiguousArray<Pixel>(repeating: Pixel(), count: filmWidth * filmHeight)
                    let start = Date.now
                    compute1A(scene: scene, into: &bitmapPixels)
                    let end = Date.now
                    bitmapPixels.withUnsafeBufferPointer { bptr in
                        let bitmap = Data(buffer: bptr)
                        let image = CIImage(
                            bitmapData: bitmap,
                            bytesPerRow: 4 * filmWidth,
                            size: CGSize(width: filmWidth, height: filmHeight),
                            format: .RGBA8,
                            colorSpace: colorSpace)
                        imageContext.render(
                            image,
                            to: drawable.texture,
                            commandBuffer: commands,
                            bounds: metalLayer.bounds,
                            colorSpace: colorSpace)
                    }
                    
                    commands.present(drawable)
                    commands.commit()
                    
                    return end.timeIntervalSince(start)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
