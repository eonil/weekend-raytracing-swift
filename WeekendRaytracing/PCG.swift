/// https://www.reedbeta.com/blog/hash-functions-for-gpu-rendering/
enum PCG {
    struct PRNG {
        private var seed = 0 as UInt32
        mutating func random() -> UInt32 {
            let state = seed
            let (a, _) = state.multipliedReportingOverflow(by: 747796405)
            let (b, _) = a.addingReportingOverflow(2891336453)
            seed = b
            let c = ((state >> ((state >> 28) + 4)) ^ state)
            let (d, _) = c.multipliedReportingOverflow(by: 277803737)
            let word = d
            return (word >> 22) ^ word
        }
//        mutating func randomFloat32() -> Float32 {
//            let bit32 = random() as UInt32
//            let b0 = bit32 & 0b1
//            let b8 = (bit32 >> 1) & 0b111111
//            let b23 = (bit32 >> 9) & 0b11111111111111111111111
//            return Float32(sign: b0 == 0 ? .minus : .plus, exponentBitPattern: UInt(b8), significandBitPattern: b23)
//        }
        
        /// Produces random `Scalar` in `0...1` range.
        mutating func randomScalar() -> Scalar {
            (Scalar(random()) / Self.uInt32MaxInScalar)
        }
        private static let uInt32MaxInScalar = Scalar(UInt32.max)
        
        /// Produces random `Vector3` with all components in `0...1` range.
        mutating func randomVector3() -> Vector3 {
            Vector3(
                randomScalar(),
                randomScalar(),
                randomScalar())
        }
    }
//    static func hash(_ value: UInt32) -> UInt32 {
//        let state = value * 747796405 + 2891336453
//        let word = ((state >> ((state >> 28) + 4)) ^ state) * 277803737
//        return (word >> 22) ^ word
//    }
}
