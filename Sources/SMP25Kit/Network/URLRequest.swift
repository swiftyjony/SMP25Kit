//
//  URLRequest.swift
//  EmpleadosAPI
//
//  Created by Jon Gonzalez on 9/4/25.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

extension URLRequest {
    public static func get(url: URL, method: HTTPMethod = .get, tokenType: GlobalIDs = .tokenID) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        if let token = SecKeyStore.shared.readValueString(label: tokenType.rawValue) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    public static func post<T: Encodable>(url: URL, body: T, method: HTTPMethod = .post, tokenType: GlobalIDs = .tokenID, encoder: JSONEncoder = JSONEncoder()) -> URLRequest {
        var request = URLRequest.get(url: url, method: method, tokenType: tokenType)
        request.httpBody = try? encoder.encode(body)
        print(String(data: request.httpBody!, encoding: .utf8)!)
        return request
    }
}
