//
//  NetworkInteractor.swift
//  EmpleadosAPI
//
//  Created by Jon Gonzalez on 9/4/25.
//

import Foundation

public protocol NetworkInteractor {
    var session: URLSession { get }
}

extension NetworkInteractor {
    public func getJSON<JSON>(_ request: URLRequest,
                       type: JSON.Type,
                       status: Int = 200) async throws(NetworkError) -> JSON where JSON: Codable {
        let (data, response) = try await session.getData(for: request)
        if response.statusCode == status {
            do {
                return try JSONDecoder().decode(JSON.self, from: data)
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
