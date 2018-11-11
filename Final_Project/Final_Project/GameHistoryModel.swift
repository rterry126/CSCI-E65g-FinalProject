//
//  GameHistoryModel.swift
//  Final_Project
//
//  Created by Robert Terry on 11/10/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import Foundation

class GameHistoryModel  {
    
/*
     Class Requirements:
     
     1) When game is over, it should store the player names, scores, date, and game state to the cloud.
     Need an observer to trigger this?
     
     2) Provide methods to retrieve the necessary history items for the historyTableView from the cloud OR
     simply download the entire history in it's model and the table can access this directly??
 
*/

    
    struct Game {
        
        var playerOneName: String
        var _layerTwoName: String

        var playerOneScore: Int
        var playerTwoScore: Int

        var gameDate: Date
    }
    
    var history: [Game] = []
    
    var db = MinimalFirebaseProxy.db
    
    func retrieveHistory() {
    
        db.collection("history_test").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            }
            else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
        //                    let timestamp: Timestamp = document.get("created_at") as! Timestamp
        //                    let date: Date = timestamp.dateValue()
        //                    print("\(date)")
                    
                   
        
                }
            }
        }
    }



}
