//
//  HistoryDetailView.swift
//  Final_Project
//
//  Created by Robert Terry on 12/8/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import UIKit

//class HistoryDetailView: GameGridViewProtocol {
//    
//    
//    
//    
//    // Robert - taken directly from pickerView definition.
//    weak open var dataSource: GameGridViewDataSource? // default is nil. weak reference
//    weak open var delegate: GameGridViewDelegate? // default is nil. weak reference
//    
//    
//    let colorStroke = UIColor.black
//    // View's default colors IF delegate isn't set to retrieve colors.
//    let colorPlayerOneDefault = UIColor.darkGray
//    let colorPlayerTwoDefault = UIColor.lightGray
//    // Very light gray background for empty
//    let colorEmptyDefault = UIColor.init(red: 0.902, green: 0.902, blue: 0.902, alpha: 1.0)
//    
//    //Create our grid array
//    var gridArray = [[(square: CGRect, state: GridState)]]()
//    
//    let screenWidth = UIScreen.main.bounds.width
//    
//    // This will be the length of our square. It's calculated in createGrid() but also used for the tap recognizer. It needs to be
//    // initialized so this is a hack so that we can use it in both functions.
//    var shortSide: CGFloat = 0.0
//    
//    
//    
//    // Robert - optional with default values set if unable to determine
//    var rows:Int {
//        get {
//            // If we cannot determine number of rows then delibertly set size to 2 x 2 per specs
//            let testRows = dataSource?.numberOfRows(in: self) ?? 2
//            if testRows < 2 || testRows > 20 {
//                fatalError("Grid rows are out of size specs")
//            }
//            return testRows
//        }
//    }
//    // Same as 'rows' logic
//    var columns:Int {
//        get {
//            let testColumns = dataSource?.numberOfColumns(in: self) ?? 2
//            if testColumns < 2 || testColumns > 20 {
//                fatalError("Grid columns are out of size specs")
//            }
//            return testColumns
//        }
//    }
//    
//    private func commonInit() {
//        
//        // Make view clear, in case that the grid doesn't take up whole view.
//        backgroundColor = UIColor.clear
//        
//        //Default start state of game view should be non-interactive
//        self.isUserInteractionEnabled = false
//        
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        // Can do custom set up here, like setting up the border and drop shadow and clipping behavior
//        // maybe retrieve the data model from somewhere
//        commonInit()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        commonInit()
//        // This is the one Xcode calls, so all init stuff has to be here too
//    }
//    
//    @objc func handleTap(sender: UITapGestureRecognizer) {
//        
//        print("Got a tap, Location in sample view: \(sender.location(in: self)), setting color")
//        let logicalRow = (Int(sender.location(in: self).y / shortSide))
//        let logicalColumn = (Int(sender.location(in: self).x / shortSide))
//        
//        delegate?.gameGridView(in: self, at: (row: logicalRow, column: logicalColumn))
//        
//    }
//    
//    
//    // Source cited
//    // NOTE: Coordinates are COLUMN/ROW not row/column
//    // Need to update state (color) of a logical location
//    func changeGridState(x: Int, y: Int) {
//        
//        // VIew to Controller: What color should new grid square be?
//        
//        // So if the dataSource isn't set, we'll just set as an empty grid
//        // changed to y,x as we are fetching GridCoord are row/column and x,y is column/row
//        //
//        // I'm not sure how we're supposed to determine the grid state if the data source isn't working...
//        
//        let gridState = dataSource?.gameGridView(in: self, at: (y,x)) ?? GridState.empty
//        
//        
//        // Change the state of the logical location
//        gridArray[y][x].state = gridState
//        
//        // 'Schedule' redraw of just one square
//        // Conveniently the location to redraw is built into the object, as it's a CGRect
//        
//        reloadOneSquare(gridArray[y][x].square)
//    }
//    
//
//    
//}



