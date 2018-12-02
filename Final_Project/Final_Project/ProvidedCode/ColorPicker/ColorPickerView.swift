//  ColorPickerView.swift
//  Final_Project
//
//  Created by BaseZen on 10/17/18.
//  Copyright © 2018 CSCI E65g 2018. All rights reserved.


import UIKit


class ColorPickerView: UIImageView {
    private static let WheelSize = CGSize(width: 500, height: 500)
    
    private var imageData: Data?
    
    
    private func createColorWheel() -> UIImage? {
        UIGraphicsBeginImageContext(ColorPickerView.WheelSize) // Start a blank slate
        let wheelFrame = CGRect(origin: CGPoint(), size: ColorPickerView.WheelSize)
        let slices = 360
        let radii = 120
        
        let startRadius = CGFloat(0)
        let radiusIncrement = wheelFrame.height / (2 * CGFloat(radii))
        let brightnessIncrement = 1.0 / CGFloat(radii)
        let startRadian = -(CGFloat.pi / 2)
        let radianIncrement = 2 * .pi / CGFloat(slices)
        let colorIncrement = 1.0 / CGFloat(slices)
        (0..<radii).forEach { radiusN in
            (0..<slices).forEach { sliceN in
                UIColor(hue: colorIncrement * CGFloat(sliceN), saturation: brightnessIncrement * CGFloat(radiusN), brightness: 1.0, alpha: 1.0).set()
                let slice = UIBezierPath(arcCenter: wheelFrame.center,
                                         radius: startRadius + radiusIncrement * CGFloat(radiusN),
                                         startAngle: startRadian + radianIncrement * CGFloat(sliceN),
                                         endAngle: startRadian + radianIncrement * CGFloat(sliceN + 1) + 0.01, // slight overlap prevents empty pixels, creating gaps
                                         clockwise: true)
                slice.lineWidth = radiusIncrement
                slice.stroke()
            }
        }
        let wheelImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return wheelImage
    }
    
    
    private func getBitmapData(from image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else {
            NSLog("Missing color picker cgImage!")
            return nil
        }
        guard let colorSpace = cgImage.colorSpace else {
            NSLog("Color picker image missing color space!")
            return nil
        }

        var rawImageData = Data(repeating: 0, count: cgImage.width * cgImage.height * (cgImage.bitsPerPixel / 8))        
        rawImageData.withUnsafeMutableBytes {
            (imageDataPtr: UnsafeMutablePointer<UInt8>) in
            guard let context = CGContext(data: imageDataPtr,
                                          width: cgImage.width,
                                          height: cgImage.height,
                                          bitsPerComponent: cgImage.bitsPerComponent,
                                          bytesPerRow: cgImage.width * 4,
                                          space: colorSpace,
                                          bitmapInfo: cgImage.bitmapInfo.rawValue) else {
                NSLog("Cannot create cg context from color picker cgImage!")
                return
            }
            context.draw(cgImage, in: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: cgImage.width, height: cgImage.height)))
        }
        return rawImageData
    }
    

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let wheelImage = createColorWheel() {
            image = wheelImage
            imageData = getBitmapData(from: wheelImage)
        }
        else {
            NSLog("Warning: could not create color wheel image!")
        }
    }
    
    
    func gridCoord(of location: CGPoint) -> GridCoord? {
        let scale = ColorPickerView.WheelSize.width / bounds.width
        let scaledLocation = CGPoint(x: location.x * scale, y: location.y * scale)
        let radius = ColorPickerView.WheelSize.width / 2
        let dist = sqrt(pow(scaledLocation.x - radius, 2) + pow(scaledLocation.y - radius, 2))
        guard dist <= radius else { // Ignore the touch if outside the color wheel itself; simple Pythagorean test
            return nil
        }
        let coord: GridCoord = (row: Int(scaledLocation.y), column: Int(scaledLocation.x))
        return coord
    }
    
    
    func pixelValue(of location: CGPoint) -> RGB32Pixel? {
        guard let data = imageData, let coord = gridCoord(of: location) else {
            return nil
        }
        let offset = 4 * (coord.row * Int(ColorPickerView.WheelSize.width) + coord.column)
        return RGB32Pixel(r: data[offset + 2], g: data[offset + 1], b: data[offset], a: 255)
    }
}




