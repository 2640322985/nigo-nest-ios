import AppKit
import Foundation

// Reject launch-screen captures. Ignore the system status bar and outer edges.
guard CommandLine.arguments.count == 2,
      let data = try? Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])),
      let pixels = NSBitmapImageRep(data: data) else {
    fputs("Cannot read screenshot\n", stderr)
    exit(1)
}
var low = 1.0
var high = 0.0
for y in stride(from: pixels.pixelsHigh / 5, to: pixels.pixelsHigh * 4 / 5, by: 13) {
    for x in stride(from: pixels.pixelsWide / 10, to: pixels.pixelsWide * 9 / 10, by: 13) {
        guard let color = pixels.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
        let light = (color.redComponent + color.greenComponent + color.blueComponent) / 3
        low = min(low, light)
        high = max(high, light)
    }
}
guard high - low > 0.4 else {
    fputs("Blank launch screen detected; retry capture\n", stderr)
    exit(1)
}
print("Screenshot contains rendered content: \(CommandLine.arguments[1])")
