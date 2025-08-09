
import Foundation
import CoreData

class PhotoManager {
    static let shared = PhotoManager()
    private let fileManager = FileManager.default
    private lazy var photosDirectory: URL = {
        let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Photos")
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }()

    private init() {}

    func savePhoto(image: PlatformImage, for item: Item, context: NSManagedObjectContext) -> Photo? {
        guard let data = image.toJPEGData() else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            let photo = Photo(context: context)
            photo.filename = filename
            photo.creationDate = Date()
            item.addToPhotos(photo)
            return photo
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }

    func getPhoto(for photo: Photo) -> PlatformImage? {
        guard let filename = photo.filename else { return nil }
        let fileURL = photosDirectory.appendingPathComponent(filename)
        #if os(iOS)
        return PlatformImage(contentsOfFile: fileURL.path)
        #else
        return PlatformImage(contentsOfFile: fileURL.path)
        #endif
    }

    func deletePhoto(photo: Photo, context: NSManagedObjectContext) {
        if let filename = photo.filename {
            let fileURL = photosDirectory.appendingPathComponent(filename)
            try? fileManager.removeItem(at: fileURL)
        }
        context.delete(photo)
    }
}
