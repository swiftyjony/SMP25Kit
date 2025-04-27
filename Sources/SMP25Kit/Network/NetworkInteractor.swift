//
//  NetworkInteractor.swift
//  EmpleadosAPI
//
//  Created by Jon Gonzalez on 9/4/25.
//

import Foundation

public protocol NetworkInteractor {
    var session: URLSession { get }
    var decoder: JSONDecoder { get }
}

extension NetworkInteractor {
    public var session: URLSession { .shared }
    public var decoder: JSONDecoder { JSONDecoder() }

    public func getJSON<JSON>(_ request: URLRequest,
                       type: JSON.Type,
                       status: Int = 200) async throws(NetworkError) -> JSON where JSON: Codable {
        let (data, response) = try await session.getData(for: request)
        if response.statusCode == status {
            do {
                return try decoder.decode(JSON.self, from: data)
            } catch {
                throw .json(error)
            }
        } else {
            throw .status(response.statusCode)
        }
    }

    public func getStatus(request: URLRequest, status: Int = 200) async throws(NetworkError) {
        let (_, response) = try await session.getData(for: request)
        if response.statusCode != status {
            throw .status(response.statusCode)
        }
    }
}
