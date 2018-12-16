//
//  FirestoreProxyOut.swift
//  Final_Project
//
//  Created by Robert Terry on 12/16/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import Foundation
import Firebase

extension FirebaseProxy {

    
    // Called app startup...
    // 1) Determines P1 & P2 2) Sets maxNum of turns 3) Uploads each player's name 4) Sets P1's name
    // when for P2 when it calls.
    func electPlayerOne(completion: @escaping ( Bool, String, Int ) -> Void ) {
        
        let reference = FirebaseProxy.db.collection("elect_leader").document("123456")
        let maxTurns = self.modelGameLogic.maxTurns
        var playerOneName = self.modelGamePrefs.myNameIs
        let playerTwoName = self.modelGamePrefs.myNameIs
        
        FirebaseProxy.db.runTransaction({ (transaction, errorPointer) -> (Bool?, String?, Int?) in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(reference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                Factory.displayAlert(target: GameBoardVC.self, error: fetchError)

                return (nil,nil, nil)
            }
            guard let leaderBit = document.data()?["leader_bit"] as? Bool else {
                
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve leader_bit from snapshot \(document)"
                    ]
                )
                errorPointer?.pointee = error
                Factory.displayAlert(target: GameBoardVC.self, error: error)
                return (nil,nil, nil)
            }
            print("leader Bit from Firestore \(leaderBit)")
            // leaderBit is current false, i.e. no player one. Go ahead and set
            if !leaderBit {
                Util.log("\nUpdated leader bit\n")
                
                let dataToUpdate = ["leader_bit": true,"gameStarted": false, "maxTurns": maxTurns, "playerOneName": playerOneName] as [String : Any]
                transaction.updateData(dataToUpdate, forDocument: reference)
                
            }
                // Else... this is Player 2 logic
            else {
                
                Util.log("\nUpdated leader reset for next game\n")
                // Download number of turns
                guard let maxTurns = document.data()?["maxTurns"] as? Int else {
                    fatalError("Could not set maximum number of turns")
                }
//                //TODO:  This sets maxTurns for Player 2. Not sure how to get it out of here...
//                self.modelGameLogic.maxTurns = maxTurns
                
                playerOneName = document.data()?["playerOneName"] as? String ?? "Player 1"
                
                // Reset leader bit so that election starts all over if we quit
                let dataToUpdate = ["leader_bit": false, "playerTwoName": playerTwoName] as [String : Any]
                
                transaction.updateData(dataToUpdate, forDocument: reference)
                return (!leaderBit, playerOneName, maxTurns)
            }
            return (!leaderBit, playerOneName, maxTurns) // Ideally this should return True and in completion block below we set in model
        })
        {(object, error) in
            guard let object = object as? (leaderBit: Bool, playerOneName: String, maxTurns: Int) else {
                Util.log("Unable to set leader bit")
                return
            }
            if let error = error {
                Util.log("Transaction failed: \(error)")
            } else {
                Util.log("Transaction successfully committed!")
                completion(object.leaderBit, object.playerOneName, object.maxTurns)
                
            }
        }
    }


}
