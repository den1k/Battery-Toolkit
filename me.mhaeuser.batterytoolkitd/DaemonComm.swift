/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import ServiceManagement

internal final class BTDaemonComm: NSObject, BTDaemonCommProtocol {
    @MainActor func getUniqueId(reply: @Sendable @escaping (NSData?) -> Void) -> Void {
        reply(BTIdentification.getUniqueId())
    }

    @MainActor internal func execute(authData: NSData?, command: UInt8, reply: @Sendable @escaping (BTError.RawValue) -> Void) -> Void {
        let authRef = BTAuthorization.fromData(authData: authData)
        guard let authRef = authRef else {
            reply(BTError.notAuthorized.rawValue)
            return
        }

        guard command != BTDaemonCommProtocolCommands.removeLegacyHelperFiles.rawValue else {
            let authorized = BTAuthorization.checkRight(
                authRef: authRef,
                rightName: kSMRightModifySystemDaemons
                )
            guard authorized else {
                reply(BTError.notAuthorized.rawValue)
                return
            }

            let success = BTDaemonManagement.removeLegacyHelperFiles()
            reply(BTError(fromBool: success).rawValue)
            return
        }

        let authorized = BTAuthorization.checkRight(
            authRef: authRef,
            rightName: BTAuthorizationRights.manage
            )
        guard authorized else {
            reply(BTError.notAuthorized.rawValue)
            return
        }

        var success = false
        switch command {
            case BTDaemonCommProtocolCommands.disablePowerAdapter.rawValue:
                success = BTPowerState.disablePowerAdapter()

            case BTDaemonCommProtocolCommands.enablePowerAdapter.rawValue:
                success = BTPowerState.enablePowerAdapter()

            case BTDaemonCommProtocolCommands.chargeToFull.rawValue:
                success = BTPowerEvents.chargeToFull()

            case BTDaemonCommProtocolCommands.chargeToMaximum.rawValue:
                success = BTPowerEvents.chargeToMaximum()

            case BTDaemonCommProtocolCommands.disableCharging.rawValue:
                success = BTPowerEvents.disableCharging()

            default:
                os_log("Unknown command: \(command)")
        }

        reply(BTError(fromBool: success).rawValue)
    }

    @MainActor internal func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void {
        BTDaemonManagement.getState(reply: reply)
    }

    @MainActor internal func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        reply(BTSettings.getSettings())
    }

    @MainActor internal func setSettings(authData: NSData?, settings: [String: AnyObject], reply: @Sendable @escaping (BTError.RawValue) -> Void) -> Void {
        let authRef = BTAuthorization.fromData(authData: authData)
        guard let authRef = authRef else {
            reply(BTError.notAuthorized.rawValue)
            return
        }

        let authorized = BTAuthorization.checkRight(
            authRef: authRef,
            rightName: BTAuthorizationRights.manage
            )
        guard authorized else {
            reply(BTError.notAuthorized.rawValue)
            return
        }

        BTSettings.setSettings(settings: settings, reply: reply)
    }
}
