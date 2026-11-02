// Renders the app icons from IconArtwork into the asset catalog.
// Usage: tools/render-icons.sh  (compiles this with the shared artwork sources)
import AppKit
import SwiftUI

@MainActor
func render() throws {
    let catalog = URL(filePath: CommandLine.arguments[1])
    for style in AppIconStyle.allCases {
        let renderer = ImageRenderer(content: IconArtwork(style: style))
        renderer.scale = 1
        guard let cgImage = renderer.cgImage else { fatalError("render failed for \(style)") }

        // App Store icons must be opaque: redraw without alpha.
        let width = cgImage.width, height = cgImage.height
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let opaque = context.makeImage()!
        let data = NSBitmapImageRep(cgImage: opaque).representation(using: .png, properties: [:])!

        let folder = catalog.appending(path: "\(style.assetName).appiconset")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try data.write(to: folder.appending(path: "icon.png"))
        let contents = """
        {
          "images" : [
            { "filename" : "icon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
          ],
          "info" : { "author" : "xcode", "version" : 1 }
        }

        """
        try Data(contents.utf8).write(to: folder.appending(path: "Contents.json"))
        print("\(style.assetName): \(data.count) bytes")
    }
}

try MainActor.assumeIsolated { try render() }
