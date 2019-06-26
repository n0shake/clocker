// Copyright © 2015 Abhishek Banthia

import Cocoa
import ServiceManagement

struct StartupManager {
    
    func toggleLogin(_ sender: NSButton) {
        if !SMLoginItemSetEnabled("com.abhishek.ClockerHelper" as CFString, sender.state == .on) {
            Logger.log(object: ["Successful": "NO"], for: "Start Clocker Login")
            addClockerToLoginItemsManually()
        } else {
            Logger.log(object: ["Successful": "YES"], for: "Start Clocker Login")
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
