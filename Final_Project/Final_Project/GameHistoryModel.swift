//
//  GameHistoryModel.swift
//  Final_Project
//
//  Created by Robert Terry on 11/10/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import Foundation


    


//
//extension Task{
//    init?(dictionary: [String : Any], id: String) {
//        guard   let name = dictionary["name"] as? String,
//            let done = dictionary["done"] as? Bool
//            else { return nil }
//
//        self.init(name: name, done: done, id: id)
//    }
//}

//TODO: - Eventually make this a class
//class GameHistoryModel  {

/*
     Class Requirements:
     
     1) When game is over, it should store the player names, scores, date, and game state to the cloud.
     Need an observer to trigger this?
     
     2) Provide methods to retrieve the necessary history items for the historyTableView from the cloud OR
     simply download the entire history in it's model and the table can access this directly??
 
*/

struct Game {
    
    var playerOneName: String
    var playerTwoName: String
    var playerOneScore: Int
    var playerTwoScore: Int
    
//    var gameBoard: [Any] //[[GridState]]
    var gameBoardView: Data
    
    var gameDate: Any // Native type is Firestore Timestamp, which isn't available here unless import Firestore
    
    
    var id: String
    
    var dictionary: [String: Any] {
        return [
            "playerOneName": playerOneName,
            "playerTwoName": playerTwoName,
            "playerOneScore": playerOneScore,
            "playerTwoScore": playerTwoScore,
//            "gameBoard": gameBoard, // [
//                "0": gameBoard[0],
//                "1": gameBoard[1],
//                "2": gameBoard[2],
//                "3": gameBoard[3],
//                "4": gameBoard[4]
//            ],
            
            "gameBoardView": gameBoardView,
            "created_at": gameDate
        ]
    }
}


extension Game {
    init?(dictionary: [String : Any], id: String) {
        
        guard   let playerOneName = dictionary["playerOneName"] as? String,
            let playerOneScore = dictionary["playerOneScore"] as? Int,
            let playerTwoName = dictionary["playerTwoName"] as? String,
            let playerTwoScore = dictionary["playerTwoScore"] as? Int,
//            let gameBoard = dictionary["gameBoard"] as? Any,
            let gameBoardView = dictionary["gameBoardView"] as? Data,
            let gameDate = dictionary["created_at"]
            else { return nil }
        
        self.init(playerOneName: playerOneName, playerTwoName: playerTwoName, playerOneScore: playerOneScore, playerTwoScore: playerTwoScore, gameBoardView: gameBoardView, gameDate: gameDate, id: id)
    }
}
    
struct Restaurant {
    
    var playerOneName: String
    var playerTwoName: String
    var playerOneScore: Int
    var playerTwoScore: Int
    var gameDate: Any // Native type is Firestore Timestamp, which isn't available here unless import Firestore
    
    
    var dictionary: [String: Any] {
        return [
            "playerOneName": playerOneName,
            "playerTwoName": playerTwoName,
            "playerOneScore": playerOneScore,
            "playerTwoScore": playerTwoScore,
            "created_at": gameDate
//            "avgRating": averageRating,
            
        ]
    }
    
}

extension Restaurant {
    
 
    
    init?(dictionary: [String : Any]) {
        guard let playerOneName = dictionary["playerOneName"] as? String,
            let playerTwoName = dictionary["playerTwoName"] as? String,
            let playerOneScore = dictionary["playerOneScore"] as? Int,
            let playerTwoScore = dictionary["playerTwoScore"] as? Int,
            let gameDate = dictionary["created_at"] as? Any
//            let averageRating = dictionary["avgRating"] as? Float,
//            let photo = (dictionary["photo"] as? String).flatMap(URL.init(string:))
            else { return nil }
        
        self.init(playerOneName: playerOneName,
                  playerTwoName: playerTwoName,
                  playerOneScore: playerOneScore,
                  playerTwoScore: playerTwoScore,
                  gameDate: gameDate)
//                  averageRating: averageRating,
//                  photo: photo)
    }
    
}

struct Review {
    
    var rating: Int // Can also be enum
    var userID: String
    var username: String
    var text: String
    var date: Date
    
    var dictionary: [String: Any] {
        return [
            "rating": rating,
            "userId": userID,
            "userName": username,
            "text": text,
            "date": date
        ]
    }
    
}


