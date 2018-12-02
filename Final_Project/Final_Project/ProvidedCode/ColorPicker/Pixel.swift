//  Pixel.swift
//  Final_Project
//
//  Created by Daniel Bromberg on 10/19/18.
//  Copyright © 2018 CSCI E65g 2018. All rights reserved.

import Foundation
import UIKit.UIColor


// http://mhorga.org/2015/10/05/image-processing-in-ios.html
struct RGB32Pixel: CustomStringConvertible {
    enum component: UInt8 {
        case blue = 0
        case green = 8
        case red = 16
        case alpha = 24
        
        var mask: UInt32 {
            return UInt32(UInt8.max) << rawValue
        }
        
        func of(_ pixelVal: UInt32) -> UInt8 {
            return UInt8((pixelVal & mask) >> rawValue)
        }
        
        func replace(in pixelVal: UInt32, with component: UInt8) -> UInt32 {
            return (pixelVal & ~mask) | UInt32(component) << rawValue
        }
    }
    
    static let White = RGB32Pixel(r: 255, g: 255, b: 255, a: 255)
    private var value: UInt32
    
    var blue: UInt8 {
        get { return component.blue.of(value) }
        set { value = component.blue.replace(in: value, with: newValue) }
    }
    
    var green: UInt8 {
        get { return component.green.of(value) }
        set { value = component.green.replace(in: value, with: newValue) }
    }
    
    var red: UInt8 {
        get { return component.red.of(value) }
        set { value = component.red.replace(in: value, with: newValue) }
    }
    
    var alpha: UInt8 {
        get { return component.alpha.of(value) }
        set { value = component.alpha.replace(in: value, with: newValue) }
    }
    
    var isTransparent: Bool {
        return alpha == 0
    }
    
    var description: String {
        get {
            return "r: \(red) g: \(green) b: \(blue) alpha: \(alpha)"
        }
    }
    
    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        value = 0
        red = r
        green = g
        blue = b
        alpha = a
    }
    
    var asColor: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
