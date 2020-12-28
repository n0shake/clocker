// Copyright © 2015 Abhishek Banthia
import Cocoa
import ServiceManagement

public struct StartupManager {
    public init() {}
    public func toggleLogin(_ shouldStartAtLogin: Bool) {
        if !SMLoginItemSetEnabled("com.abhishek.ClockerHelper" as CFString, shouldStartAtLogin) {
            addClockerToLoginItemsManually()
        }
    }

    private func addClockerToLoginItemsManually() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Clocker is unable to set to start at login. 😅"
        alert.informativeText = "You can manually set it to start at startup by adding Clocker to your login items."
        alert.addButton(withTitle: "Add Manually")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response.rawValue == 1000 {
            OperationQueue.main.addOperation {
                let prefPane = "/System/Library/PreferencePanes/Accounts.prefPane"
                NSWorkspace.shared.openFile(prefPane)
            }
        }
    }
}
