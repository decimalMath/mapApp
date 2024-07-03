import UIKit

class ImageCache {
    static let shared = ImageCache()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    func saveImage(_ image: UIImage, withID id: String) -> Bool {
        guard let data = image.pngData() else { return false }
        let fileURL = cacheDirectory.appendingPathComponent("\(id).png")

        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }

    func getCachedImage(withID id: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).png")

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return UIImage(data: data)
    }

    func clearCache() {
        let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [])
        contents?.forEach { file in
            try? fileManager.removeItem(at: file)
        }
    }
}
