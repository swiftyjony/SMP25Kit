//
//  File.swift
//  MyLibraryTDD
//
//  Created by Jon Gonzalez on 23/4/25.
//

import Foundation

public protocol JSONLoader {}

extension JSONLoader {
    public func load<T>(url: URL, type: T.Type) throws -> T where T: Codable {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    public func save<T>(url: URL, data: T) throws where T: Codable {
        let jsonData = try JSONEncoder().encode(data)
        try jsonData.write(to: url, options: [.atomic, .completeFileProtection])
    }
}
