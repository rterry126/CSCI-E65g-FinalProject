//
//  GameBoardViewExtension.swift
//  Final_Project
//
//  Created by Robert Terry on 12/17/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import UIKit

// So I was going to have the detail page of the history play back the game. For this I needed parts of the custom view. I pulled out
// what I though I might need and put in a protocol extension so I wouldn't have to duplicate code.
// That project never came to fruition, however I decided to keep this 'common' code in the extension.

// Source - https://blog.bobthedeveloper.io/protocol-oriented-programming-view-in-swift-3-8bcb3305c427
extension GameGridViewProtocol where Self: UIView {
    
    
    func reloadOneSquare(_ rect: CGRect) {
        setNeedsDisplay(rect)
    }
    
    func reloadAllSquares() {
        setNeedsDisplay()
    }
    
    // This will be the length of our square. It's calculated in createGrid() but also used for the tap recognizer. It needs to be
    // initialized so this is a hack so that we can use it in both functions.
    
    
    
    func createGrid() {
        
        print(" calculated size \(self.frame.size.width)   \(self.frame.size.height)")
        // First determine the largest square we can draw. For example if the layout is 20x3 we have more vertical space than if 3x20.
        // We want to maximize our square size for the screen real estate given.
        
        let widthCalculation = self.frame.size.width / CGFloat(columns)
        let heightCalculation = self.frame.size.height / CGFloat(rows)
        
        
        shortSide = (widthCalculation < heightCalculation) ? widthCalculation : heightCalculation
        // Initialize our empty grid array
        
        // Determine square size, then location of each square. We're making an array of physical (points)
        // location, square size, and state. Location/square size are stored as CGRect. Array is tuples
        // of CGRect and gridState
        // We'll use this array to initialize grid and then modify as
        // game progresses
        let _squareSize = CGSize.init(width: shortSide, height: shortSide)
        //        let _squareSize = CGSize.init(width: screenWidth / CGFloat(columns), height: screenWidth / CGFloat(columns))
        
        
        //Need to enumerate through empty array and store state, CGRect, which contains position.
        //Array subscripts are our logical coordinates, so we need them to calculate the physical location.
        // Since each element is different we can't use our array initializer.
        // Source cited for initializing array of arrays.
        for row in 0..<rows {
            var rowToAppend = [(square: CGRect, state: GridState)]()
            
            for column in 0..<columns {
                
                let xLocation = _squareSize.width * CGFloat(column)
                let yLocation = _squareSize.height * CGFloat(row)
                
                // We need a CGRect, which is a size and location. Location is a CGPoint
                // calculated below. This is physical (points, not logical) location
                let locationToDraw = CGPoint.init(x: xLocation, y: yLocation)
                
                // square is CGRect and is both size AND location. Size won't vary but location will
                // Square size previously calculated
                let square = CGRect(origin: locationToDraw, size: _squareSize)
                
                
                // So now we have the square. 2nd item to store is the state, which is .empty
                
                // this builds 1-D array, which is appended to the 2-D array as a row.
                rowToAppend.append((square, .empty))
            }
            // Build the 2-D array from 1-D array above
            gridArray.append(rowToAppend)
        }
        // Set flag to render our grid. Must reload all squares, i.e. schedule a setNeedsDisplay()
        reloadAllSquares()
    }
}

