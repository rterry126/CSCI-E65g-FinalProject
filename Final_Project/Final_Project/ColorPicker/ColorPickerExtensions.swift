//  UIViewExtensions.swift
//  Assignment7
//
//  Created by BaseZen on 10/23/18.
//  Copyright © 2018 CSCI E65g 2018. All rights reserved.

import UIKit

extension CGSize {
    var asGridCoord: GridCoord {
        return (row: Int(height), column: Int(width))
    }
}


extension CGRect {
    // Views have centers, so why not any rect
    var center: CGPoint {
        return CGPoint(x: width / 2, y: height / 2)
    }
    
    init(center: CGPoint, radius: CGFloat) {
        self.init(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}


// Not necessarily needed, but good to show how to manipulate colors in various color spaces
extension UIColor {
    convenience init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha) / 255)
    }

    var hsva: (CGFloat, CGFloat, CGFloat, CGFloat) {
        var (h, s, v, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        getHue(&h, saturation: &s, brightness: &v, alpha: &a)
        return (h, s, v, a)
    }
    
    func withHSVATweak(brightness: CGFloat) -> UIColor {
        let curVals = hsva
        return UIColor(hue: curVals.0, saturation: curVals.1, brightness: brightness, alpha: curVals.3)
    }    
}


// Some layout conveniences when doing layout in code
extension UIView {
    public func layoutSquareCenteredFullWidth(in superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        superView.addSubview(self)
        NSLayoutConstraint.activate(constraintsCenteredFullWidth(in: superView))
    }

    
    // For elements with intrinsic size
    public func layoutCenteredBelow(sibling: UIView, in superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        superView.addSubview(self)
        NSLayoutConstraint.activate(constraintsCenteredBelow(sibling: sibling))
    }

    
    public func layoutBelowEqualWidthTo(sibling: UIView, in superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        superView.addSubview(self)
        NSLayoutConstraint.activate(constraintsEqualWidthBelow(sibling: sibling))
    }

    
    public func layoutAboveEqualWidthTo(sibling: UIView, in superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        superView.addSubview(self)
        NSLayoutConstraint.activate(constraintsEqualWidthAbove(sibling: sibling))
    }


    private func constraintsCenteredBelow(sibling: UIView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal,
                               toItem: sibling, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal,
                               toItem: sibling, attribute: .bottom, multiplier: 1.0, constant: 8)
        ]
    }


    private func constraintsEqualWidthAbove(sibling: UIView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal,
                               toItem: sibling, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal,
                               toItem: sibling, attribute: .top, multiplier: 1.0, constant: -8),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal,
                               toItem: sibling, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal,
                               toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50),
        ]
    }

    
    private func constraintsEqualWidthBelow(sibling: UIView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal,
                               toItem: sibling, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal,
                               toItem: sibling, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal,
                               toItem: sibling, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal,
                               toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50),
        ]
    }
    

    private func constraintsCenteredFullWidth(in superView: UIView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal,
                               toItem: superView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal,
                               toItem: superView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal,
                               toItem: superView, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal,
                               toItem: superView, attribute: .width, multiplier: 1, constant: 0),
        ]
    }
}

