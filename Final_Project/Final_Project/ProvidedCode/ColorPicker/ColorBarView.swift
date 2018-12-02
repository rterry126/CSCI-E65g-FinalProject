//  ColorBarView.swift
//  Final_Project
//
//  Created by BaseZen on 10/23/18.
//  Copyright © 2018 CSCI E65g 2018. All rights reserved.

import UIKit

class ColorBarView: UIView {
    enum DisplayMode {
        case brightness
        case hsb
    }
    
    // This model is so simple it is already encapsulated by CGPoint
    private(set) var mode: DisplayMode
    
    var lastCheckedLocation: CGPoint?
    weak var delegate: ColorPickerGestureDelegate?
    

    init(mode: DisplayMode) {
        self.mode = mode
        super.init(frame: CGRect())
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        backgroundColor = .clear
    }
    
    
    override func draw(_ rect: CGRect) {
        guard let d = delegate else {
            return
        }
        { (mode: DisplayMode) -> UIColor in
            switch mode {
            case .brightness: return UIColor.black.withAlphaComponent(1 - d.currentColor.hsva.2)
            case .hsb: return d.currentColor
            }
        }(mode).setFill()
        UIBezierPath(rect: bounds).fill()
        if let selectedPoint = lastCheckedLocation {
            let marker = UIBezierPath(ovalIn: CGRect(center: selectedPoint, radius: 7))
            marker.lineWidth = 4
            UIColor.white.setStroke()
            marker.stroke()
        }
    }
}
