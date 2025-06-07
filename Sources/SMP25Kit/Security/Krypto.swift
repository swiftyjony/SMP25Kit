//
//  File.swift
//  SMP25Kit
//
//  Created by Jon Gonzalez on 7/6/25.
//

import Foundation
import CryptoKit

public final class Krypto: Sendable {
    static let shared = Krypto()
    static private let keyName = "KryptoKey"
    static private let certificateName = "KryptoCertificate"

    private let key: SymmetricKey
    private let randomSecure: Data
    private let privateKey: SecureEnclave.P256.Signing.PrivateKey

    static private func randomSecureNumber(bits: Int) -> Data? {
        var randomNumber = [UInt8](repeating: 0, count: bits / 8)
        let success = SecRandomCopyBytes(kSecRandomDefault, randomNumber.count, &randomNumber)
        if success == errSecSuccess {
            return Data(randomNumber)
        } else {
            return nil
        }
    }

    private init() {
        if let key = SecKeyStore.shared.readValue(label: Krypto.keyName) {
            self.key = SymmetricKey(data: key)
        } else {
            self.key = SymmetricKey(size: .bits256)
            let keyData = self.key.withUnsafeBytes { Data($0) }
            SecKeyStore.shared.storeValue(keyData, label: Krypto.keyName)
        }
        if let random = SecKeyStore.shared.readValue(label: "randomKey") {
            self.randomSecure = random
        } else {
            if let random = Krypto.randomSecureNumber(bits: 256) {
                self.randomSecure = random
                SecKeyStore.shared.storeValue(random, label: "randomKey")
            } else {
                self.randomSecure = Data()
            }
        }
        do {
            if let privateKey = SecKeyStore.shared.readPrivateKey(tag: Krypto.certificateName) {
                self.privateKey = try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: privateKey)
            } else {
                privateKey = try SecureEnclave.P256.Signing.PrivateKey()
                SecKeyStore.shared.storePrivateKey(privateKey.dataRepresentation, tag: Krypto.certificateName)
            }
        } catch {
            fatalError("Error en el acceso al Secure Enclave. No se pudo iniciar la app.")
        }
    }

    public func hashHMAC(data: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
    }

    public func hashHMAC(data: String) -> Data {
        let data = Data(data.utf8)
        return Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
    }

    public func validateHMAC(data: Data, hash: Data) -> Bool {
        HMAC<SHA256>.isValidAuthenticationCode(hash, authenticating: data, using: key)
    }

    public func validateHMAC(data: String, hash: Data) -> Bool {
        let data = Data(data.utf8)
        return HMAC<SHA256>.isValidAuthenticationCode(hash, authenticating: data, using: key)
    }

    public func GCMEncrypt(data: Data) throws -> Data? {
        let box = try AES.GCM.seal(data, using: key)
        return box.combined
    }

    public func GCMEncrypt(data: String) throws -> Data? {
        let data = Data(data.utf8)
        let box = try AES.GCM.seal(data, using: key)
        return box.combined
    }

    public func GCMDecrypt(data: Data) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        let open = try AES.GCM.open(box, using: key)
        return open
    }

    public func GCMDecryptString(data: Data) throws -> String? {
        let box = try AES.GCM.SealedBox(combined: data)
        let open = try AES.GCM.open(box, using: key)
        return String(data: open, encoding: .utf8)
    }

    public func ChaChaEncryptB64(data: Data) throws -> String {
        let box = try ChaChaPoly.seal(data, using: key)
        return box.combined.base64EncodedString()
    }

    public func ChaChaEncrypt(data: Data) throws -> Data {
        let box = try ChaChaPoly.seal(data, using: key)
        return box.combined
    }

    public func ChaChaEncrypt(data: String) throws -> Data {
        let data = Data(data.utf8)
        let box = try ChaChaPoly.seal(data, using: key)
        return box.combined
    }

    public func ChaChaDecrypt(data: Data) throws -> Data {
        let box = try ChaChaPoly.SealedBox(combined: data)
        let open = try ChaChaPoly.open(box, using: key)
        return open
    }

    public func ChaChaDecryptString(data: Data) throws -> String? {
        let box = try ChaChaPoly.SealedBox(combined: data)
        let open = try ChaChaPoly.open(box, using: key)
        return String(data: open, encoding: .utf8)
    }

    public func ChaChaDecryptB64(data: String) throws -> String? {
        guard let data = Data(base64Encoded: data) else { return nil }
        let box = try ChaChaPoly.SealedBox(combined: data)
        let open = try ChaChaPoly.open(box, using: key)
        return String(data: open, encoding: .utf8)
    }

    public func sign(data: Data) throws -> Data {
        let signature = try privateKey.signature(for: data)
        return signature.rawRepresentation
    }

    public func sign(data: String) throws -> Data {
        let data = Data(data.utf8)
        return try sign(data: data)
    }

    public func validateSignature(data: Data, signature: Data) throws -> Bool {
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
        return privateKey.publicKey.isValidSignature(signature, for: data)
    }

    public func validateSignature(data: String, signature: Data) throws -> Bool {
        let data = Data(data.utf8)
        return try validateSignature(data: data, signature: signature)
    }
}
