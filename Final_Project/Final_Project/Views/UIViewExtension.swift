//
//  UIViewExtension.swift
//  Final_Project
//
//  Created by Robert Terry on 12/17/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import UIKit

// Added to create image from game board state
extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
