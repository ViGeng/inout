
import Foundation
import CoreData
import UIKit

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

    func savePhoto(image: UIImage, for item: Item, context: NSManagedObjectContext) -> Photo? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
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

    func getPhoto(for photo: Photo) -> UIImage? {
        guard let filename = photo.filename else { return nil }
        let fileURL = photosDirectory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }

    func deletePhoto(photo: Photo, context: NSManagedObjectContext) {
        if let filename = photo.filename {
            let fileURL = photosDirectory.appendingPathComponent(filename)
            try? fileManager.removeItem(at: fileURL)
        }
        context.delete(photo)
    }
}
