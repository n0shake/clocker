// Copyright © 2015 Abhishek Banthia

import Foundation
import AppKit

extension CGRect {
    static func center(of layer: CALayer) -> CGPoint {
        let parentSize = layer.frame.size
        return CGPoint(x: parentSize.width / 2, y: parentSize.height / 2)
    }
    static func center(of parent: NSView) -> CGPoint {
        let parentSize = parent.frame.size
        return CGPoint(x: parentSize.width / 2, y: parentSize.height / 6)
    }
}

extension String {
    func size(with fontSize: CGFloat) -> CGSize {
        let attr: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: fontSize)]
        let size = NSString(string: self).size(withAttributes: attr)
        return size
    }
}

fileprivate class HideAnimationDelegate: NSObject, CAAnimationDelegate {
    private weak var view: NSView?
    fileprivate init(view: NSView) {
        self.view = view
    }
    fileprivate static func delegate(forView NSView: NSView) -> CAAnimationDelegate {
        return HideAnimationDelegate(view: NSView)
    }
    fileprivate func animationDidStart(_ anim: CAAnimation) {
        view?.layer?.opacity = 0.0
    }
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        view?.removeFromSuperview()
        view = nil
    }
}

func hideAnimation(view: NSView, style: Style) {
    let anim = CABasicAnimation(keyPath: "opacity")
    let timing = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
    anim.timingFunction = timing
    let currentLayerTime = view.layer?.convertTime(CACurrentMediaTime(), from: nil)
    anim.beginTime = currentLayerTime! + CFTimeInterval(style.fadeInOutDelay)
    anim.duration = CFTimeInterval(style.fadeInOutDuration)
    anim.fromValue = 1.0
    anim.toValue = 0.0
    anim.isRemovedOnCompletion = false
    anim.delegate = HideAnimationDelegate.delegate(forView: view)

    view.layer?.add(anim, forKey: "hide animation")
}

public protocol Style {
    var fontSize: CGFloat {get}
    var horizontalMargin: CGFloat {get}
    var verticalMargin: CGFloat {get}
    var cornerRadius: CGFloat {get}
    var font: NSFont {get}
    var backgroundColor: NSColor {get}
    var foregroundColor: NSColor {get}
    var fadeInOutDuration: CGFloat {get}
    var fadeInOutDelay: CGFloat {get}
    var labelOriginWithMargin: CGPoint {get}
    var activitySize: CGSize {get}
}

extension Style {
    public var labelOriginWithMargin: CGPoint {
        return CGPoint(x: horizontalMargin, y: verticalMargin)
    }
    public var fontSize: CGFloat {return 12}
    public var font: NSFont {
        if let avenirFont = NSFont(name: "Avenir-Light", size: fontSize) {
            return avenirFont
        }
        return NSFont.systemFont(ofSize: fontSize)
    }
    public var horizontalMargin: CGFloat {return 10}
    public var verticalMargin: CGFloat {return 5}
    public var cornerRadius: CGFloat {return 8}
    public var backgroundColor: NSColor {return .black}
    public var foregroundColor: NSColor {return .white}
    public var activitySize: CGSize {return CGSize(width: 100, height: 100)}
    public var fadeInOutDuration: CGFloat {return 1.0}
    public var fadeInOutDelay: CGFloat {return 1.0}
}

public struct DefaultStyle: Style {
    public static let shared = DefaultStyle()
}

private struct ToastKeys {
    static var ActiveToast  = "TSToastActiveToastKey"
}

class ToastView: NSView {
    private let message: String
    private let labelSize: CGSize
    private let style: Style
    init(message: String) {
        self.message = message
        self.style = DefaultStyle()
        self.labelSize = message.size(with: style.fontSize)
        let size = CGSize(
            width: labelSize.width + style.horizontalMargin*2,
            height: labelSize.height + style.verticalMargin*2
        )
        let rect = CGRect(origin: .zero, size: size)
        super.init(frame: rect)
        wantsLayer = true
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview != nil {
            configure()
        }
    }
    
    private func configure() {
        frame = superview?.bounds ?? NSRect.zero
        let rect = CGRect(origin: style.labelOriginWithMargin, size: labelSize)
        let sizeWithMargin = CGSize(
            width: rect.width + style.horizontalMargin*2,
            height: rect.height + style.verticalMargin*2
        )
        let rectWithMargin = CGRect(
            origin: .zero, // position is manipulated later anyways
            size: sizeWithMargin
        )
        // outside Container
        let container = CALayer()
        container.frame = rectWithMargin
        container.position = CGRect.center(of: superview!)
        container.backgroundColor = style.backgroundColor.cgColor
        container.cornerRadius = style.cornerRadius
        layer?.addSublayer(container)
        // inside TextLayer
        let text = CATextLayer()
        text.frame = rect
        text.position = CGRect.center(of: container)
        text.string = message
        text.font = NSFont.systemFont(ofSize: style.fontSize)
        text.fontSize = style.fontSize
        text.alignmentMode = .center
        text.foregroundColor = style.foregroundColor.cgColor
        text.backgroundColor = style.backgroundColor.cgColor
        text.contentsScale = layer?.contentsScale ?? 0 // For Retina Display
        container.addSublayer(text)
    }
}

extension NSView {
    public func makeToast(_ message: String) {
        let toast = ToastView(message: message)
        self.addSubview(toast)
        hideAnimation(view: toast, style: DefaultStyle.shared)
    }
}
