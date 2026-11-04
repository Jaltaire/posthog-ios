#if os(iOS)
    import Foundation
    @testable import PostHog
    import Testing
    import UIKit

    @Suite("Screenshot colour spaces")
    struct PostHogScreenshotColorSpaceTests {
        let displayP3 = CGColorSpace(name: CGColorSpace.displayP3)!
        let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

        @Test("renders a wide-gamut screen in Display P3")
        func wideGamutScreen() {
            #expect(PostHogGraphicsImageRenderer.colorSpace(for: .P3).name == CGColorSpace.displayP3)
        }

        @Test("renders an sRGB screen in the device colour space")
        func sRGBScreen() {
            #expect(PostHogGraphicsImageRenderer.colorSpace(for: .SRGB).name == CGColorSpaceCreateDeviceRGB().name)
        }

        @Test("renders a screen of unknown gamut in the device colour space")
        func unspecifiedScreen() {
            #expect(PostHogGraphicsImageRenderer.colorSpace(for: .unspecified).name == CGColorSpaceCreateDeviceRGB().name)
        }

        @Test("draws into the colour space it is given")
        func rendererColorSpace() {
            let renderer = PostHogGraphicsImageRenderer(size: CGSize(width: 2, height: 2), scale: 1, colorSpace: displayP3)
            let image = renderer.image { context in
                context.setFillColor(UIColor.red.cgColor)
                context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
            }
            #expect(image?.cgImage?.colorSpace?.name == CGColorSpace.displayP3)
        }

        @Test("draws in the device colour space by default")
        func rendererDefaultColorSpace() {
            let renderer = PostHogGraphicsImageRenderer(size: CGSize(width: 2, height: 2), scale: 1)
            let image = renderer.image { _ in }
            #expect(image?.cgImage?.colorSpace?.name == CGColorSpaceCreateDeviceRGB().name)
        }

        @Test("encodes a wide-gamut image in sRGB")
        func webPColorSpaceForWideGamut() {
            #expect(UIImage.webPColorSpace(for: displayP3).name == CGColorSpace.sRGB)
        }

        @Test("encodes an sRGB image in its own colour space")
        func webPColorSpaceForSRGB() {
            #expect(UIImage.webPColorSpace(for: sRGB) === sRGB)
        }

        @Test("encodes a device RGB image in its own colour space")
        func webPColorSpaceForDeviceRGB() {
            let device = CGColorSpaceCreateDeviceRGB()
            #expect(UIImage.webPColorSpace(for: device) === device)
        }

        @Test("encodes an image without an RGB colour space in linear sRGB")
        func webPColorSpaceForOtherModels() {
            #expect(UIImage.webPColorSpace(for: CGColorSpaceCreateDeviceGray()).name == CGColorSpace.linearSRGB)
            #expect(UIImage.webPColorSpace(for: nil).name == CGColorSpace.linearSRGB)
        }

        @Test("keeps a Display P3 screenshot's colours when it is encoded")
        func displayP3ScreenshotColours() throws {
            let expected = CGColor(colorSpace: sRGB, components: [0.8, 0.2, 0.2, 1])!
            let fill = try #require(expected.converted(to: displayP3, intent: .defaultIntent, options: nil))
            let renderer = PostHogGraphicsImageRenderer(size: CGSize(width: 32, height: 32), scale: 1, colorSpace: displayP3)
            let image = try #require(renderer.image { context in
                context.setFillColor(fill)
                context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
            })
            let data = try #require(image.webpData(compressionQuality: 1))
            let decoded = try #require(UIImage(data: data)?.cgImage)
            let pixel = try #require(sRGBPixel(decoded, x: 16, y: 16))
            #expect(abs(Int(pixel.0) - 204) <= 6)
            #expect(abs(Int(pixel.1) - 51) <= 6)
            #expect(abs(Int(pixel.2) - 51) <= 6)
        }

        private func sRGBPixel(_ image: CGImage, x: Int, y: Int) -> (UInt8, UInt8, UInt8)? {
            var bytes = [UInt8](repeating: 0, count: 4)
            let drawn: Bool = bytes.withUnsafeMutableBytes { buffer in
                guard let context = CGContext(
                    data: buffer.baseAddress,
                    width: 1,
                    height: 1,
                    bitsPerComponent: 8,
                    bytesPerRow: 4,
                    space: sRGB,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ) else {
                    return false
                }
                context.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
                return true
            }
            return drawn ? (bytes[0], bytes[1], bytes[2]) : nil
        }
    }
#endif
