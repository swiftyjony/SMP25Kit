//
//  AsyncImageVM.swift
//  EmpleadosAPI
//
//  Created by Jon Gonzalez on 10/4/25.
//

import SwiftUI

@Observable @MainActor
public final class AsyncImageVM {
    let imageDownloader = ImageDownloader.shared

    public var image: UIImage?

    public func getImage(url: URL?) {
        guard let url, let urlDoc = imageDownloader.urlDoc(url: url) else { return }
        if FileManager.default.fileExists(atPath: urlDoc.path()) {
            if let data = try? Data(contentsOf: urlDoc) {
                image = UIImage(data: data)
            }
        } else {
            Task {
                await getImageAsync(url: url)
            }
        }
    }

    func getImageAsync(url: URL) async {
        do {
            let image = try await imageDownloader.image(for: url)
            self.image = image
        } catch {
            print("Error retrieving image: \(error.localizedDescription)")
        }
    }
}
