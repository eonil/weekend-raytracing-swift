struct Sample {
    /// Offset of destination pixel in X/Y axis on film.
    var pixel: (x: Int, y: Int)
    var ray: Ray
    var time: Time
    var intensity: Scalar
}
