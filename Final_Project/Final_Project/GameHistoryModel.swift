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
    var gameDate: Any // Native type is Firestore Timestamp, which isn't available here unless import Firestore
    
    var id: String
    
    var dictionary: [String: Any] {
        return [
            "playerOneName": playerOneName,
            "playerTwoName": playerTwoName,
            "playerOneScore": playerOneScore,
            "playerTwoScore": playerTwoScore,
            
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
            let gameDate = dictionary["created_at"]
            else { return nil }
        
        self.init(playerOneName: playerOneName, playerTwoName: playerTwoName, playerOneScore: playerOneScore, playerTwoScore: playerTwoScore, gameDate: gameDate, id: id)
    }
}
    
//    var history: [Game] = []
//
//    var db = MinimalFirebaseProxy.db
//
//    func retrieveHistory() {
//
//        db.collection("history_test").getDocuments() { (querySnapshot, err) in
//            if let err = err {
//                print("Error getting documents: \(err)")
//            }
//            else {
//                for document in querySnapshot!.documents {
//                    print("\(document.documentID) => \(document.data())")
//        //                    let timestamp: Timestamp = document.get("created_at") as! Timestamp
//        //                    let date: Date = timestamp.dateValue()
//        //                    print("\(date)")
//
//
//
//                }
//            }
//        }
//    }



//}
