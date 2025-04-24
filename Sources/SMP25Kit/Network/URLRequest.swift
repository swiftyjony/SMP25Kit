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
}

extension URLRequest {
    public static func get(url: URL, method: HTTPMethod = .get) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 5
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        return request
    }
    public static func post<T: Encodable>(url: URL, body: T, method: HTTPMethod = .post) -> URLRequest {
        var request = URLRequest.get(url: url, method: method)
        request.httpBody = try? JSONEncoder().encode(body)
        return request
    }
}
