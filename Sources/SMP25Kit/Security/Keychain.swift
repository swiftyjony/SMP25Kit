//
//  File.swift
//  SMP25Kit
//
//  Created by Jon Gonzalez on 7/6/25.
//

import Foundation

@propertyWrapper
public struct Keychain {
    let key: String

    public init(key: String) {
        self.key = key
    }

    public var wrappedValue: Data? {
        get {
            SecKeyStore.shared.readValue(label: key)
        }
        set {
            if let value = newValue {
                SecKeyStore.shared.storeValue(value, label: key)
            } else {
                SecKeyStore.shared.deleteValue(label: key)
            }
        }
    }
}
