////
////  ModelProtocol.swift
////  Final_Project-rterry126
////
////  Created by Robert Terry on 10/11/18.
////  Copyright © 2018 Robert Terry. All rights reserved.
////

import Firebase

//Used for delegate for view
import UIKit

protocol StateMachineProtocol: class {
    
    static var state: StateMachine.State { get set }
    
}


protocol GameLogicModelObserver: class {
    
    func successfulBoardMove() // grid has changed
    func updatePlayer()
}


protocol GamePrefModelObserver: class {
    
    func namesChanged()
    func colorsChanged()
}

protocol GameStateMachine: class {
    
    func updateGameStateLabel()
    func stateElectPlayerOne()
    func stateInitializing()
    func stateWaitingToStartGame()
    func stateReadyForGame()
    func stateWaitingForUserMove()
    func stateWaitingForMoveConfirmation(_ notification :Notification)
    func stateWaitingForOpponent()
    func stateEndOfGame()
    
}




protocol GameLogicModelProtocol: class, Codable {
    
    var bounds: GridCoord { get }
    
    var whoseTurn: GridState { get }
    
    func incrementMoveCount()
    
    func gridState(at location: GridCoord) -> GridState
    
    func executeMove(playerID ID: GridState, moveCoordinates coordinates: GridCoord) throws
    
    func setTurn()
    
    func resetModel()
    
    var moveCount: Int { get }
    var gameBoard: [[GridState]] { get set }
    
    var amIPlayerOne: Bool { get set }
    
    var maxTurns: Int { get set }
    
    
}


protocol GamePrefModelProtocol: class {
    
    var localHistory: Bool { get set }
    
    var moveTime: Int { get set }
    
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

