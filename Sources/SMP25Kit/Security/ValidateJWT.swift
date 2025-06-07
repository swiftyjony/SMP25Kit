//
//  File.swift
//  SMP25Kit
//
//  Created by Jon Gonzalez on 7/6/25.
//

import Foundation
import CryptoKit

struct JWTBody: Codable {
    let exp: Double
    let iss: String
    let sub: String
    let aud: String
}

struct JWTHeader: Codable {
    let alg: String
    let typ: String
}

public final class ValidateJWT: Sendable {
    public init() {}

    func base64Padding(jwt: String) -> String {
        var encoded = jwt
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let count = encoded.count % 4
        for _ in 0 ..< count {
            encoded += "="
        }
        return encoded
    }

    func isTokenExpired(exp: Double) -> Bool {
        let expirationTime = TimeInterval(exp)
        let expirationDate = Date(timeIntervalSince1970: expirationTime)
        return Date.now >= expirationDate
    }

    public func JWTValidation(jwt: String, issuer: String, key: Data) throws(NetworkError) -> Bool {
        let simmetricKey = SymmetricKey(data: key)

        let jwtParts = jwt.components(separatedBy: ".")
        guard let headerData = Data(base64Encoded: jwtParts[0]),
              let bodyData = Data(base64Encoded: jwtParts[1]),
              let signatureData = Data(base64Encoded: base64Padding(jwt: jwtParts[2])) else {
            return false
        }

        do {
            let header = try JSONDecoder().decode(JWTHeader.self, from: headerData)
            let body = try JSONDecoder().decode(JWTBody.self, from: bodyData)

            guard header.alg == "HS256", header.typ == "JWT" else {
                throw NetworkError.security("Cabecera no válida en el JWT.")
            }

            if body.iss != issuer || isTokenExpired(exp: body.exp) {
                throw NetworkError.security("Issuer o fecha de expiración inválida.")
            }

            let verify = jwtParts[0] + "." + jwtParts[1]
            let verifyData = Data(verify.utf8)

            return HMAC<SHA256>.isValidAuthenticationCode(signatureData,
                                                   authenticating: verifyData,
                                                   using: simmetricKey)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.security("Fallo genérico en la validación del token JWT")
        }
    }
}
