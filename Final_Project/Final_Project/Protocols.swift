////
////  ModelProtocol.swift
////  Assignment7-rterry126
////
////  Created by Robert Terry on 10/11/18.
////  Copyright © 2018 Robert Terry. All rights reserved.
////
//
import Foundation

//Used for delegate for view
import UIKit

protocol GameLogicModelListener: class {
    func successfulBoardMove() // grid has changed
    
    func endOfGame()
    
    func updatePlayer()
}

protocol GamePrefModelListener: class {
    func namesChanged()
    
    func colorsChanged()
    
    
}




protocol GameLogicModelProtocol: class, Codable {
    
    var dataListener: GameLogicModelListener? { get set }
    
    var bounds: GridCoord { get }
    
    var whoseTurn: GridState { get }
    
    func incrementTotalTurns()
    
    func gridState(at location: GridCoord) -> GridState
    
    func executeMove(playerID ID: GridState, moveCoordinates coordinates: GridCoord) throws
    
    func setTurn()
    
    var gameState: GameState { get }
    
}


protocol GamePrefModelProtocol: class {
    
    var dataListener: GamePrefModelListener? { get set }
    
    var playerOneName:String { get set }
    var playerTwoName:String { get set }
    
    var playerOneColor: HSBColor { get set }
    var playerTwoColor: HSBColor { get set }
    
    var gameName: String { get set }
    var numRows: Int { get set }
    var numColumns: Int { get set }
    
    func deletePreferences()
    
}




// Source - Protocols were copied from pickerView and modified accordingly
// NSObjectProtocol - from what I read, it's not necessary but there is no downside to having it conform

// TODO:- add @objc and then refactor function arguments and returns so that they can be represented
// Obj-C. This will let us set the protocol methods to 'Optional'.

/*@objc*/ protocol GameGridViewDataSource : NSObjectProtocol {
    
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
    
    @available(iOS 2.0, *)
    
    func preferencesVC(in preferencesVC: PreferencesVC) -> Bool
}


