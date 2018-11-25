//  ViewController.swift
//  Assignment7
//
//  Created by BaseZen on 10/17/18.
//  Copyright © 2018 CSCI E65g 2018. All rights reserved.

import UIKit

class ColorPickerViewController: UIViewController {
    private weak var pickerImageView: ColorPickerView?
    private weak var pickedColorBar: ColorBarView?
    private weak var brightnessOverlay: ColorBarView?
    private weak var brightnessSlider: UISlider?
    private let model = ColorPickerModel()
    
    weak var dataListener: ColorPickerChoiceListener?


    
    
    override func viewDidLoad() {
        model.dataListener = self
        
        let pickerImageView = ColorPickerView()
        let pickedColorBar = ColorBarView(mode: .hsb)
        let brightnessOverlay = ColorBarView(mode: .brightness)
        let brightnessSlider = UISlider()
        let doneButton = UIButton(type: .roundedRect)
        
        pickerImageView.layoutSquareCenteredFullWidth(in: view)
        brightnessOverlay.layoutSquareCenteredFullWidth(in: view)
 
        brightnessSlider.layoutAboveEqualWidthTo(sibling: brightnessOverlay, in: view)
        pickedColorBar.layoutBelowEqualWidthTo(sibling: brightnessOverlay, in: view)
        doneButton.layoutCenteredBelow(sibling: pickedColorBar, in: view)
        
        pickedColorBar.delegate = self
        brightnessOverlay.delegate = self
        doneButton.sizeToFit() // Take intrinsic size
        doneButton.setTitle("Done", for: .normal)
        
        self.pickerImageView = pickerImageView
        self.pickedColorBar = pickedColorBar
        self.brightnessOverlay = brightnessOverlay
        self.brightnessSlider = brightnessSlider
                
        brightnessSlider.addTarget(self, action: #selector(ColorPickerViewController.handleSlide(sender:)), for: .valueChanged)
        
        // Because the brightness overlay completely covers the color wheel, it needs to be the one to receive gestures
        brightnessOverlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ColorPickerViewController.handleGesture(recog:))))
        brightnessOverlay.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(ColorPickerViewController.handleGesture(recog:))))
        doneButton.addTarget(self, action: #selector(ColorPickerViewController.didTapDone(sender:)), for: .touchUpInside)
        updateUI()
    }
    
    
    @objc private func handleSlide(sender: UISlider) {
        guard let slider = brightnessSlider else {
            return
        }
        model.brightness = 1 - Double(slider.value)
    }
    
    
    @objc private func handleGesture(recog: UIGestureRecognizer) {
        guard let picker = pickerImageView,
            let hsvaTuplet = picker.pixelValue(of: recog.location(in: picker))?.asColor.hsva else {
            return
        }
        brightnessOverlay?.lastCheckedLocation = recog.location(in: brightnessOverlay) // slight MVC shortcut; recalculating this mathematically is possible but complicated
        (model.hue, model.saturation) = (Double(hsvaTuplet.0), Double(hsvaTuplet.1))
    }
    
    
    @objc private func didTapDone(sender: Any) {
        print("User tapped done, sending color: \(currentColor)")
        dataListener?.userDidPick(color: currentColor)
        dismiss(animated: true, completion: nil)
    }
    
    
    private func updateUI() {
        brightnessSlider?.value = Float(1 - model.brightness)
        pickedColorBar?.setNeedsDisplay()
        brightnessOverlay?.setNeedsDisplay()
    }
}


extension ColorPickerViewController: ColorPickerGestureListener {
    func colorAdjusted() {
        updateUI()
    }
}


extension ColorPickerViewController: ColorPickerGestureDelegate {
    var currentColor: UIColor {
        return UIColor(hue:        CGFloat(model.hue),
                       saturation: CGFloat(model.saturation),
                       brightness: CGFloat(model.brightness),
                       alpha:      CGFloat(model.alpha))
    }
}
