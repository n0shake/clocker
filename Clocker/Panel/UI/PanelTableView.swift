// Copyright © 2015 Abhishek Banthia

import Cocoa

protocol PanelTableViewDelegate: NSTableViewDelegate {
    func tableView(_ table: NSTableView, didHoverOver row: NSInteger)
}

class PanelTableView: NSTableView {
    weak var panelDelegate: PanelTableViewDelegate?
    private var enableHover: Bool = false
    private var trackingArea: NSTrackingArea?
    private(set) var hoverRow: Int = -1

    override func awakeFromNib() {
        super.awakeFromNib()
        enableHover = true
    }

    override func updateTrackingAreas() {
        if let tracker = trackingArea {
            removeTrackingArea(tracker)
        }

        createTrackingArea()

        super.updateTrackingAreas()
    }

    private func createTrackingArea() {
        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .mouseEnteredAndExited,
            .activeAlways
        ]
        let clipRect = enclosingScrollView?.contentView.bounds ?? .zero

        trackingArea = NSTrackingArea(rect: clipRect,
                                      options: options,
                                      owner: self,
                                      userInfo: nil)

        if let tracker = trackingArea {
            addTrackingArea(tracker)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        let mousePointInWindow = event.locationInWindow
        let mousePoint = convert(mousePointInWindow, from: nil)
        var currentHoverRow = row(at: mousePoint)

        if currentHoverRow != hoverRow {
            // We've scrolled off the end of the table

            if currentHoverRow < 0 || currentHoverRow >= numberOfRows {
                currentHoverRow = -1
            }

            setHoverRow(currentHoverRow)
        }
    }

    private func setHoverRow(_ row: Int) {
        if row != hoverRow {
            hoverRow = row
            panelDelegate?.tableView(self, didHoverOver: hoverRow)
            setNeedsDisplay()
        }
    }

    override func reloadData() {
        super.reloadData()
        setHoverRow(-1)
        evaluateForHighlight()
    }

    private func evaluateForHighlight() {
        if enableHover == false {
            return
        }

        guard let mousePointInWindow = window?.mouseLocationOutsideOfEventStream else {
            return
        }

        let mousePoint = convert(mousePointInWindow, from: nil)
        evaluateForHighlight(at: mousePoint)
    }

    private func evaluateForHighlight(at point: NSPoint) {
        if enableHover == false {
            print("Unable to show hover button because window is occluded!")
            return
        }

        var hover = row(at: point)

        if hover != hoverRow {
            if hover < 0 || hover >= numberOfRows {
                hover = -1
            }
        }

        setHoverRow(hover)
    }

    override func mouseMoved(with event: NSEvent) {
        let mousePointInWindow = event.locationInWindow
        let mousePoint = convert(mousePointInWindow, from: nil)
        evaluateForHighlight(at: mousePoint)
    }

    private func setEnableHover(_ enable: Bool) {
        if enable != enableHover {
            if enableHover == false {
                setHoverRow(-1)
            }

            enableHover = enable
            evaluateForHighlight()
        }
    }
}
