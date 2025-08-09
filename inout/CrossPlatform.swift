import SwiftUI

#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
extension PlatformImage {
    static func fromData(_ data: Data) -> PlatformImage? { UIImage(data: data) }
    func toJPEGData() -> Data? { self.jpegData(compressionQuality: 1.0) }
}
extension Image {
    init(platformImage: PlatformImage) { self = Image(uiImage: platformImage) }
}
#else
import AppKit
public typealias PlatformImage = NSImage
extension PlatformImage {
    static func fromData(_ data: Data) -> PlatformImage? { NSImage(data: data) }
    func toJPEGData() -> Data? {
        guard let tiff = self.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [:])
    }
}
extension Image {
    init(platformImage: PlatformImage) { self = Image(nsImage: platformImage) }
}
#endif
