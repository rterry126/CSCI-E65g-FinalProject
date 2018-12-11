//
//  Delegates.swift
//  Final_Project_rterry126
//
//  Created by Robert Terry on 11/1/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import UIKit

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
            return hsbToUIColor(color: modelGamePrefs.playerOneColor, alpha: 0.5)
            
        case .playerTwoPower:
            return hsbToUIColor(color: modelGamePrefs.playerTwoColor, alpha: 0.5)
            
            
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
            
            // 11/24 the function below should only run and update the board color after confirmation
            //from the cloud...
            
            // Update the board state. Ideally I'd like to do this in updateUI, however not sure how to
            // pass the coordinates to updateUI....
            
            //
//            gameView?.changeGridState(x: location.column, y: location.row)
        }
            
        catch let e {
            if let gameLogicError = e as? GameLogicError {
                
                Factory.displayAlert(target: self, message: gameLogicError.rawValue)
            }
        }
    }
}


//MARK: - PreferencesVC Delegate extension

// Because I don't want to expose the model to PreferencesVC I use a delegate.
// It returns a Bool which we can use on the other end (I use it to inform the user of success if the save
// was the same.

extension GameBoardVC: PreferencesVCDelegate {
    
    // Commented out 12.11.18 - Cleaning up Preferences and don't need a specific save button
    // since game saves on each move
//    func preferencesVC(in preferencesVC: PreferencesVC) -> Bool {
//        var success: Bool
//
//        // First time run: nothing was saved from before
//        print("First run. Creating and saving \(modelGameLogic)")
//
//        // Data is optional
//        if let data = modelGameLogic.toJSONData() {
//            do {
//                try Persistence.save(data)
//                success = true
//            }
//            catch let e {
//                print("Sving failed: \(e)")
//                success = false
//            }
//
//        }
//        else {
//            print("Unable to unwrap model prior to saving")
//            return false
//        }
//        return success
//    }
    
}

// Source cited but was having issues passing model to encode function. This is hacky but got it
// to work.
extension Encodable {
    func toJSONData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}


