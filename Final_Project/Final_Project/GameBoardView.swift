//
//  GameGridView.swift
//  Assignment7-rterry126
//
//  Created by Robert Terry on 10/11/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

// Sources - implementing delegate and datasource - https://useyourloaf.com/blob/quick-guide-to-swift-delegates/
// Sources - bezier paths in custom views - https://www.appcoda.com/bezier-paths-introduction/
// Sources - array idea for multiple paths - https://stackoverflow.com/questions/42091599/how-to-create-a-multiple-path-from-several-bezierpath

// Sources - initialize 2D array- http://swiftnotions.com/2017/05/24/2d-arrays-in-swift/

// Sources - custom view - https://www.raywenderlich.com/411-core-graphics-tutorial-part-1-getting-started

// Sources - gesture recognizers - https://guides.codepath.com/ios/Using-Gesture-Recognizers

//Sources - get image from UIView - https://stackoverflow.com/questions/30696307/how-to-convert-a-uiview-to-an-image

import UIKit

@IBDesignable
class GameBoardView: UIView, GameGridViewProtocol {
    
    
    
    
    // Robert - taken directly from pickerView definition.
    weak open var dataSource: GameGridViewDataSource? // default is nil. weak reference
    weak open var delegate: GameGridViewDelegate? // default is nil. weak reference
    
    
    let colorStroke = UIColor.black
    // View's default colors IF delegate isn't set to retrieve colors.
    let colorPlayerOneDefault = UIColor.darkGray
    let colorPlayerTwoDefault = UIColor.lightGray
    // Very light gray background for empty
    let colorEmptyDefault = UIColor.init(red: 0.902, green: 0.902, blue: 0.902, alpha: 1.0)
    
    //Create our grid array
    var gridArray = [[(square: CGRect, state: GridState)]]()
    
    let screenWidth = UIScreen.main.bounds.width
    
    // This will be the length of our square. It's calculated in createGrid() but also used for the tap recognizer. It needs to be
    // initialized so this is a hack so that we can use it in both functions.
    var shortSide: CGFloat = 0.0
    
    
    
    // Robert - optional with default values set if unable to determine
    var rows:Int {
        get {
            // If we cannot determine number of rows then delibertly set size to 2 x 2 per specs
            let testRows = dataSource?.numberOfRows(in: self) ?? 2
            if testRows < 2 || testRows > 20 {
                fatalError("Grid rows are out of size specs")
            }
            return testRows
        }
    }
    // Same as 'rows' logic
    var columns:Int {
        get {
            let testColumns = dataSource?.numberOfColumns(in: self) ?? 2
            if testColumns < 2 || testColumns > 20 {
                fatalError("Grid columns are out of size specs")
            }
            return testColumns
        }
    }
    
    private func commonInit() {
        
        // Make view clear, in case that the grid doesn't take up whole view.
        backgroundColor = UIColor.clear
        
        //Default start state of game view should be non-interactive
        self.isUserInteractionEnabled = false
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Can do custom set up here, like setting up the border and drop shadow and clipping behavior
        // maybe retrieve the data model from somewhere
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
        // This is the one Xcode calls, so all init stuff has to be here too
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        
        print("Got a tap, Location in sample view: \(sender.location(in: self)), setting color")
        let logicalRow = (Int(sender.location(in: self).y / shortSide))
        let logicalColumn = (Int(sender.location(in: self).x / shortSide))
        
        delegate?.gameGridView(in: self, at: (row: logicalRow, column: logicalColumn))
        
    }
    
//    func createGrid() {
//
//        print(" calculated size \(self.frame.size.width)   \(self.frame.size.height)")
//        // First determine the largest square we can draw. For example if the layout is 20x3 we have more vertical space than if 3x20.
//        // We want to maximize our square size for the screen real estate given.
//
//        let widthCalculation = self.frame.size.width / CGFloat(columns)
//        let heightCalculation = self.frame.size.height / CGFloat(rows)
//
//
//        shortSide = (widthCalculation < heightCalculation) ? widthCalculation : heightCalculation
//        // Initialize our empty grid array
//
//        // Determine square size, then location of each square. We're making an array of physical (points)
//        // location, square size, and state. Location/square size are stored as CGRect. Array is tuples
//        // of CGRect and gridState
//        // We'll use this array to initialize grid and then modify as
//        // game progresses
//        let _squareSize = CGSize.init(width: shortSide, height: shortSide)
//        //        let _squareSize = CGSize.init(width: screenWidth / CGFloat(columns), height: screenWidth / CGFloat(columns))
//
//
//        //Need to enumerate through empty array and store state, CGRect, which contains position.
//        //Array subscripts are our logical coordinates, so we need them to calculate the physical location.
//        // Since each element is different we can't use our array initializer.
//        // Source cited for initializing array of arrays.
//        for row in 0..<rows {
//            var rowToAppend = [(square: CGRect, state: GridState)]()
//
//            for column in 0..<columns {
//
//                let xLocation = _squareSize.width * CGFloat(column)
//                let yLocation = _squareSize.height * CGFloat(row)
//
//                // We need a CGRect, which is a size and location. Location is a CGPoint
//                // calculated below. This is physical (points, not logical) location
//                let locationToDraw = CGPoint.init(x: xLocation, y: yLocation)
//
//                // square is CGRect and is both size AND location. Size won't vary but location will
//                // Square size previously calculated
//                let square = CGRect(origin: locationToDraw, size: _squareSize)
//
//
//                // So now we have the square. 2nd item to store is the state, which is .empty
//
//                // this builds 1-D array, which is appended to the 2-D array as a row.
//                rowToAppend.append((square, .empty))
//            }
//            // Build the 2-D array from 1-D array above
//            gridArray.append(rowToAppend)
//        }
//        // Set flag to render our grid. Must reload all squares, i.e. schedule a setNeedsDisplay()
//        reloadAllSquares()
//    }
//
    // Source cited
    // NOTE: Coordinates are COLUMN/ROW not row/column
    // Need to update state (color) of a logical location
    func changeGridState(x: Int, y: Int) {
        
        // VIew to Controller: What color should new grid square be?
        
        // So if the dataSource isn't set, we'll just set as an empty grid
        // changed to y,x as we are fetching GridCoord are row/column and x,y is column/row
        //
        // I'm not sure how we're supposed to determine the grid state if the data source isn't working...
        
        let gridState = dataSource?.gameGridView(in: self, at: (y,x)) ?? GridState.empty
        
        
        // Change the state of the logical location
        gridArray[y][x].state = gridState
        
        // 'Schedule' redraw of just one square
        // Conveniently the location to redraw is built into the object, as it's a CGRect
        
       reloadOneSquare(gridArray[y][x].square)
    }
    
    
    
    override func draw(_ rect: CGRect) {
//        print("Draw was called! My frame is \(self.frame) relative to my parent: \(String(describing: self.superview))")
        
        
        // Draw each of our grid squares, array of CGRect (which incorporates location
        // and size) and status (player1/2, empty)
        for row in gridArray{
            for path in row {
                
                var fillColor: UIColor
                // Set the fill color before drawing based upon square state.
                // Must unwrap and use muted view default colors if nil.
                switch path.state {
                    
                case .playerOne:
                    fillColor = delegate?.gameGridView(in: self, gridState: path.state) ?? colorPlayerOneDefault
                    
                case .playerTwo:
                    fillColor = delegate?.gameGridView(in: self, gridState: path.state) ?? colorPlayerTwoDefault
                    
                case .empty:
                    fillColor = delegate?.gameGridView(in: self, gridState: path.state) ?? colorEmptyDefault
                }
                
                fillColor.setFill()
                UIBezierPath.init(rect: path.square).fill() // This is the Bezier path we are filling
                
                // Specify a border (stroke) color. Color is set with class properties.
                colorStroke.setStroke()
                UIBezierPath.init(rect: path.square).stroke()
            }
        }
    }
    
    
//    func reloadOneSquare(_ rect: CGRect) {
//        setNeedsDisplay(rect)
//    }
//
//    func reloadAllSquares() {
//        setNeedsDisplay()
//    }
    
    override func didMoveToSuperview() {
        // "Lazy" initialization
        // set up your gesture recognizer here!
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(sender:)))
        // tapRecognizer used to be attached to superview!
        // Robert - so this just gives us locations relative to the custom view
        self.addGestureRecognizer(tapRecognizer)
        
    }
}

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
