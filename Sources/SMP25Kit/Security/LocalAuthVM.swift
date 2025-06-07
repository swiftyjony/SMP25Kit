//
//  File.swift
//  SMP25Kit
//
//  Created by Jon Gonzalez on 7/6/25.
//

import SwiftUI
import LocalAuthentication

enum Biometry {
    case faceid
    case touchid
    case opticid
    case none
}

extension LAContext: @retroactive @unchecked Sendable {}

@Observable
final class LocalAuthVM {
    let context = LAContext()

    var biometry: Biometry = .none
    var accessGranted = false

    init() {
        initBiometry()
    }

    func initBiometry() {
        var authError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            if context.biometryType == .faceID {
                biometry = .faceid
            } else if context.biometryType == .touchID {
                biometry = .touchid
            } else if context.biometryType == .opticID {
                biometry = .opticid
            }
        }
    }

    @MainActor
    func checkBiometry() async throws {
        guard biometry != .none else { return }
        if try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                            localizedReason: "Se verificará el acceso al contenido privado de la app") {
            accessGranted = true
        }
    }
}
