//  ColorPickerProtocols.swift
//  Final_Project
//
//  Created by BaseZen on 10/23/18.
//  Copyright © 2018 CSCI E65g 2018. All rights reserved.

import UIKit.UIColor

protocol ColorPickerGestureListener: class {
    func colorAdjusted()
}


protocol ColorPickerGestureDelegate: class {
    var currentColor: UIColor { get }
}

protocol ColorPickerChoiceListener: class {
    func userDidPick(color: UIColor)
}


