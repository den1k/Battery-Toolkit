/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa

@MainActor
internal struct BTAppPrompts {
    internal private(set) static var open: UInt8 = 0

    private static func unregisterDaemon() {
        BatteryToolkit.unregisterDaemon() { error in
            DispatchQueue.main.async {
                guard error == BTError.success.rawValue else {
                    promptUnregisterDaemonError()
                    return
                }

                NSApp.terminate(self)
            }
        }
    }

    private static func runPromptStandalone(alert: NSAlert) -> NSApplication.ModalResponse {
        open += 1
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        open -= 1

        return response
    }

    private static func runPrompt(alert: NSAlert, window: NSWindow? = nil, reply: @MainActor @escaping @Sendable (NSApplication.ModalResponse) -> Void) {
        guard let window = window else {
            let response = runPromptStandalone(alert: alert)
            reply(response)
            return
        }
        //
        // The warning about losing MainActor is misleading because
        // completionHandler is always executed on the main thread.
        //
        alert.beginSheetModal(for: window, completionHandler: reply)
    }

    private static func runPrompt(alert: NSAlert, window: NSWindow? = nil) {
        runPrompt(alert: alert, window: window) { _ in }
    }

    internal static func promptApproveDaemon(timeout: UInt8, reply: @escaping @Sendable (Bool) -> Void) {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.allowMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.allowInfo
        alert.alertStyle      = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.approve)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = runPromptStandalone(alert: alert)
        switch response {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                BatteryToolkit.approveDaemon(timeout: timeout, reply: reply)

            case NSApplication.ModalResponse.alertSecondButtonReturn:
                NSApp.terminate(self)

            default:
                assert(false)
        }
    }

    internal static func promptRegisterDaemonError() -> Bool {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.enableFailMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo
        alert.alertStyle      = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = runPromptStandalone(alert: alert)
        switch response {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                return true

            case NSApplication.ModalResponse.alertSecondButtonReturn:
                NSApp.terminate(self)

            default:
                assert(false)
        }

        return false
    }

    internal static func promptUnregisterDaemon() {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.disableMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
        "\n\n" + BTLocalization.Prompts.Daemon.disableInfo
        alert.alertStyle      = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            unregisterDaemon()
        }
    }

    internal static func promptUnregisterDaemonError() {
        let alert         = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle  = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            unregisterDaemon()
        }
    }

    internal static func promptUnexpectedError(window: NSWindow?) {
        let alert         = NSAlert()
        alert.messageText = BTLocalization.Prompts.unexpectedErrorMessage
        alert.alertStyle  = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.ok)
        runPrompt(alert: alert, window: window)
    }

    internal static func promptNotAuthorized(window: NSWindow? = nil) {
        let alert         = NSAlert()
        alert.messageText = BTLocalization.Prompts.notAuthorizedMessage
        alert.alertStyle  = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.ok)
        runPrompt(alert: alert, window: window)
    }

    internal static func promptDaemonCommFailed(window: NSWindow? = nil) {
        let alert         = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.commFailMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.commFailInfo
        alert.alertStyle  = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        runPrompt(alert: alert, window: window) { _ in
            assert(Thread.isMainThread)
            NSApp.terminate(self)
        }
    }
}