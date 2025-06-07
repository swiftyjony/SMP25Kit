//
//  File.swift
//  SMP25Kit
//
//  Created by Jon Gonzalez on 7/6/25.
//

import Foundation
import os.log
@preconcurrency import Security

//extension SecAccessControl: @retroactive @unchecked Sendable {}

public struct SecKeyStore: Sendable {
    private static let access: SecAccessControl = {
        guard let ac = SecAccessControlCreateWithFlags(nil,
                                                       kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                       [.privateKeyUsage, .userPresence],
                                                       nil) else {
            fatalError("Error al crear el control de acceso")
        }
        return ac
    }()

    private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "", category: "SecKeyStore")

    public static let shared = SecKeyStore()

    public func storeValue(_ value: Data, label: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: label,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "",
            kSecUseDataProtectionKeychain: true,
            kSecValueData: value
        ] as [String: Any]

        if readValue(label: label) == nil {
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Error grabando la clave \(label) \(status)")
            }
        } else {
            let attributes = [
                kSecValueData: value
            ] as [String: Any]

            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status != errSecSuccess {
                print("Error actualizando la clave \(label) \(status)")
            }
        }
    }

    public func readValueString(label: String) -> String? {
        guard let item = readValue(label: label),
              let itemString = String(data: item, encoding: .utf8) else {
            return nil
        }
        return itemString
    }

    public func readValue(label: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: label,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "",
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [String: Any]

        var item: CFTypeRef?

        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status != errSecSuccess {
            print("Error leyendo la clave \(label) \(status)")
            return nil
        }
        return item as? Data
    }

    public func deleteValue(label: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: label
        ] as [String: Any]

        let result = SecItemDelete(query as CFDictionary)
        if result == noErr {
            print("Item \(label) se ha borrado.")
        }
    }

    public func storePrivateKey(_ certificate: Data, tag: String) {
        let tagData = Data(tag.utf8)
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag: tagData,
            kSecAttrAccessControl: Self.access,
            kSecAttrIsPermanent: true,
            kSecValueData: certificate
        ] as [String: Any]

        let status = SecItemAdd(query as CFDictionary, nil)
        switch status {
        case errSecSuccess: break
        case errSecDuplicateItem:
            os_log("La clave del certificado está duplicada para el tag", log: Self.log, type: .error, tag, status)
        default:
            os_log("Error grabando el certificado", log: Self.log, type: .error, tag, status)
        }
    }

    public func readPrivateKey(tag: String) -> Data? {
        let tagData = Data(tag.utf8)
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag: tagData,
            kSecAttrAccessControl: Self.access,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [String: Any]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            os_log("Error leyendo el certificado", log: Self.log, type: .error, tag, status)
            return nil
        }
        return item as? Data
    }

    func deletePrivateKey(tag: String) {
        let tagData = Data(tag.utf8)
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag: tagData
        ] as [String: Any]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            os_log("Error al borrar la clave", log: Self.log, type: .error, tag, status)
            return
        }
    }
}
