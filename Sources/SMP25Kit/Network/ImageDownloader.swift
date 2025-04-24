//
//  ImageDownloader.swift
//  EmpleadosAPI
//
//  Created by Jon Gonzalez on 10/4/25.
//

import SwiftUI

actor ImageDownloader {
    static let shared = ImageDownloader()

    private enum ImageStatus {
        case downloading(task: Task<UIImage, Error>)
        case downloaded(image: UIImage)
    }

    private var cache: [URL: ImageStatus] = [:]
    var maxWidth: CGFloat = 512

    private func getImage(url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let image = UIImage(data: data) {
            return image
        } else {
            throw URLError(.badServerResponse)
        }
    }

    func image(for url: URL) async throws -> UIImage {
        if let imageStatus = cache[url] {
            switch imageStatus {
            case .downloading(let task):
                return try await task.value
            case .downloaded(let image):
                return image
            }
        }

        let task = Task {
            try await getImage(url: url)
        }

        cache[url] = .downloading(task: task)

        do {
            let image = try await task.value
            cache[url] = .downloaded(image: image)
            return try await saveImage(url: url)
//            return image
        } catch {
            cache.removeValue(forKey: url)
            throw error
        }
    }

    func saveImage(url: URL) async throws -> UIImage {
        guard let imageCached = cache[url],
              let urlDoc = urlDoc(url: url) else { throw URLError(.cannotDecodeContentData) }
        if case .downloaded(let image) = imageCached,
           let resized = await resizeImage(image),
           let data = resized.heicData() {
            try data.write(to: urlDoc, options: .atomic)
            cache.removeValue(forKey: url)
            return resized
        } else {
            throw URLError(.cannotDecodeContentData)
        }
    }

    func resizeImage(_ image: UIImage) async -> UIImage? {
        let scale = image.size.width / maxWidth
        let height = image.size.height / scale
        return await image.byPreparingThumbnail(ofSize: CGSize(width: maxWidth, height: height))
    }

//    func saveImage(url: URL) async throws {
//        guard let imageCached = cache[url],
//              let urlDoc = urlDoc(url: url) else { return }
//        if case .downloaded(let image) = imageCached,
//           let data = image.heicData() {
//            try data.write(to: urlDoc, options: .atomic)
//            cache.removeValue(forKey: url)
//        }
//    }

    // Como no hacemos uso de ninguna variable del actor, puede ser nonisolated
    nonisolated func urlDoc(url: URL) -> URL? {
        URL.cachesDirectory
            .appending(path: url.deletingPathExtension().lastPathComponent)
            .appendingPathExtension("heic")
    }
}
