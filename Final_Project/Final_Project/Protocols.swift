////
////  ModelProtocol.swift
////  Final_Project-rterry126
////
////  Created by Robert Terry on 10/11/18.
////  Copyright © 2018 Robert Terry. All rights reserved.
////
//
import Foundation
import Firebase

//Used for delegate for view
import UIKit

protocol StateMachineProtocol: class {
    
    static var state: StateMachine.State { get set }
    //var instance: StateMachineProtocol { get }
    
    
    
}


protocol GameLogicModelObserver: class {
    func successfulBoardMove() // grid has changed

    func stateEndOfGame()

    func updatePlayer()
}

protocol GamePrefModelObserver: class {
    func namesChanged()

    func colorsChanged()
}

protocol GameStateMachine: class {
    
//    func getDatabaseHandle(notification : NSNotification) -> Firestore
    
    func stateInitializing()
    func stateReadyForGame()
    func stateWaitingForUserMove()
    func stateElectPlayerOne()
    func stateWaitingForMoveConfirmation(_ notification :Notification)
    func stateWaitingForOpponent()

}




protocol GameLogicModelProtocol: class, Codable {
        
    var bounds: GridCoord { get }
    
    var whoseTurn: GridState { get }
    
    func incrementMoveCount()
    
    func gridState(at location: GridCoord) -> GridState
    
    func executeMove(playerID ID: GridState, moveCoordinates coordinates: GridCoord) throws
    
    func setTurn()
    
//    var gameState: GameState { get }
    
    func resetModel()
    
    var moveCount: Int { get }
    var gameBoard: [[GridState]] { get set }
    
    var amIPlayerOne: Bool { get set }
    
    var maxTurns: Int { get set } // Need to make this public. Player 1 sets this randomly, need to now set it in player 2 via Firestore
    
    
}


protocol GamePrefModelProtocol: class {
    
    var myNameIs:String { get set }
    
    var playerOneName:String { get set }
    var playerTwoName:String { get set }
    
    var playerOneColor: HSBColor { get set }
    var playerTwoColor: HSBColor { get set }
    
    var gameName: String { get set }
    var numRows: Int { get set }
    var numColumns: Int { get set }
    
    func deletePreferences()
    
}

// Making the custom view Protocol based as I might use it again for the detail page of my game history
protocol GameGridViewProtocol: class {
    
    //Create our grid array
    var gridArray: [[(square: CGRect, state: GridState)]] { get set }
    var shortSide: CGFloat { get set }
    var rows: Int { get }
    var columns: Int { get }
    
//    func reloadOneSquare(_ rect: CGRect)
//
//    func reloadAllSquares()
}


// TODO: - https://blog.bobthedeveloper.io/protocol-oriented-programming-view-in-swift-3-8bcb3305c427
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


// Source - Protocols were copied from pickerView and modified accordingly
// NSObjectProtocol - from what I read, it's not necessary but there is no downside to having it conform
protocol GameGridViewDataSource : NSObjectProtocol {
    
    // returns the # of rows in each component..
    @available(iOS 2.0, *)
    func numberOfRows(in gameGridView: GameBoardView) -> Int
    
    // returns the number of 'columns' to display.
    @available(iOS 2.0, *)
    func numberOfColumns(in gameGridView: GameBoardView) -> Int
    
    // Returns the state of a 'square', one of 3 possible states
    @available(iOS 2.0, *)
    func gameGridView(in gameGridView: GameBoardView, at location: GridCoord) -> GridState
    
}



protocol GameGridViewDelegate : NSObjectProtocol {
    
    // Returns the color of a 'square', given one of 3 possible states
    @available(iOS 2.0, *)
    func gameGridView(in gameGridView: GameBoardView, gridState state: GridState) -> UIColor
    
    func gameGridView(in gameGridView: GameBoardView, at location: GridCoord)
    
}

// I want the 'Save Game State' button in preferences, ostensible for space issues but
// don't want to expose the logic model to that view controller
protocol PreferencesVCDelegate : NSObjectProtocol {
    
// Removed 12.11.18 - See other comments on this date in PreferencesVC
    //    @available(iOS 2.0, *)
//
//    func preferencesVC(in preferencesVC: PreferencesVC) -> Bool
}


