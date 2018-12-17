//
//  Delegates.swift
//  Final_Project_rterry126
//
//  Created by Robert Terry on 11/1/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import UIKit // Needed for UIColor and Data types

//MARK: - GameGridView Data Source extension
extension GameBoardVC: GameGridViewDataSource {
    
    func numberOfRows(in gameGridView: GameBoardView) -> Int {
        return modelGameLogic.bounds.row
    }
    
    func numberOfColumns(in gameGridView: GameBoardView) -> Int {
        return modelGameLogic.bounds.column
    }
    
    // Remember GridCoord are row/column
    func gameGridView(in gameGridView: GameBoardView, at location: GridCoord) -> GridState {
        return modelGameLogic.gridState(at: location)
        
    }
}

//MARK: - GameGridView Delegate extension
extension GameBoardVC: GameGridViewDelegate {
    
    
    // Given a grid state, what color should the view fill it with????
    func gameGridView(in gameGridView: GameBoardView, gridState state: GridState) -> UIColor {
        
        switch state {
            
            // So return either the value we have obstensibly had 'set'/input for each case; if nil then
            // the view will use its default colors.
        case .playerOne:
            return hsbToUIColor(color: modelGamePrefs.playerOneColor)
            
        case .playerTwo:
            return hsbToUIColor(color: modelGamePrefs.playerTwoColor)
            
        // Power squares are same color, just drop the opacity
            
        case .playerOnePower:
            return hsbToUIColor(color: modelGamePrefs.playerOneColor, alpha: 0.6)
            
        case .playerTwoPower:
            return hsbToUIColor(color: modelGamePrefs.playerTwoColor, alpha: 0.6)
            
            
        case .empty:
            return colorEmpty
            
        }
    }
    
    // Called by the tap handler in the view. GridCoord are logical coordinates...
    func gameGridView(in gameGridView: GameBoardView, at location: GridCoord) {
        
        // So .executeMove throws several errors (out of turn, square occupied, etc)
        do {
            // observer implanted in .executeMove
            try modelGameLogic.executeMove(playerID: modelGameLogic.whoseTurn, moveCoordinates: (location.row, location.column))
            
            // So now the board AND model are updated via the listener .moveStoredFirestore
//            gameView?.changeGridState(x: location.column, y: location.row)
            
        }
            
        catch let e {
            if let gameLogicError = e as? GameLogicError {
                
                Factory.displayAlert(target: self, message: gameLogicError.rawValue)
            }
        }
    }
}




// Source cited but was having issues passing model to encode function. This is hacky but got it
// to work.
extension Encodable {
    func toJSONData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}


