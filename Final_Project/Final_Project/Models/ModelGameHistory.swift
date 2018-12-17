//
//  ModelGameHistory.swift
//  Final_Project
//
//  Created by Robert Terry on 11/10/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Source of using struct cited in HistoryMasterVC

import Foundation



/*
     Class Requirements:
     
     1) When game is over, it should store the player names, scores, date, and game state to the cloud.
     Need an observer to trigger this?
     
     2) Provide methods to retrieve the necessary history items for the historyTableView from the cloud OR
     simply download the entire history in it's model and the table can access this directly??
 
*/

// Used to format game history retrieved. Structures it so that it can be easier displayed in the tableView for history
struct Game {
    
    var playerOneName: String
    var playerTwoName: String
    var playerOneScore: Int
    var playerTwoScore: Int
    
    var gameBoardView: Data
    
    var gameDate: Any // Native type is Firestore Timestamp, which isn't available here unless import Firestore
    
    var id: String
    
    var dictionary: [String: Any] {
        return [
            "playerOneName": playerOneName,
            "playerTwoName": playerTwoName,
            "playerOneScore": playerOneScore,
            "playerTwoScore": playerTwoScore,
            "gameBoardView": gameBoardView,
            "gameDate": gameDate
        ]
    }
}


extension Game {
    init?(dictionary: [String : Any], id: String) {
        
        guard   let playerOneName = dictionary["playerOneName"] as? String,
            let playerOneScore = dictionary["playerOneScore"] as? Int,
            let playerTwoName = dictionary["playerTwoName"] as? String,
            let playerTwoScore = dictionary["playerTwoScore"] as? Int,
            let gameBoardView = dictionary["gameBoardView"] as? Data,
            let gameDate = dictionary["gameDate"]
            else { return nil }
        
        self.init(playerOneName: playerOneName, playerTwoName: playerTwoName, playerOneScore: playerOneScore, playerTwoScore: playerTwoScore, gameBoardView: gameBoardView, gameDate: gameDate, id: id)
    }
}
    
