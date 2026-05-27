// Copyright © 2026 Adrak Studio LLC

import Cocoa

class Panelr: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)

        // Escape key is pressed
        if event.keyCode == 53 {
            close()
        }
    }
}
