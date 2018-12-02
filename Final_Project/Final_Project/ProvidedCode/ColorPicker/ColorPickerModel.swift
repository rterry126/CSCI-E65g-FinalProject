//  ColorPickerModel.swift
//  Final_Project
//
//  Created by BaseZen on 10/23/18.
//  Copyright © 2018 CSCI E65g 2018. All rights reserved.


// Nice and pure, no dependencies
class ColorPickerModel {
    weak var dataListener: ColorPickerGestureListener?
        
    var hue = 0.0 {
        didSet {
            dataListener?.colorAdjusted()
        }
    }
    
    var saturation = 1.0 {
        didSet {
            dataListener?.colorAdjusted()
        }
    }
    
    var brightness = 1.0 {
        didSet {
            dataListener?.colorAdjusted()
        }
    }
    
    var alpha = 1.0 {
        didSet {
            dataListener?.colorAdjusted()
        }
    }
}
