//
//  FirestoreProxyOut.swift
//  Final_Project
//
//  Created by Robert Terry on 12/16/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - func downloadHistory - mapping -  https://code.tutsplus.com/tutorials/getting-started-with-cloud-firestore-for-ios--cms-30910

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
    
    // Resume a game; only Player 1 can upload a game
    func uploadGame(_ gameModel: GameLogicModelProtocol, completion: @escaping () -> Void) {
        
        
        var fakeMoveNumber = 1
        // Get new write batch
        let batch = Firestore.firestore().batch()
        
        // Create 'header' document
        let headerToStore: [String : Any] = ["playerOneName": modelGamePrefs.playerOneName, "playerTwoName": modelGamePrefs.playerTwoName, "moveTime": FieldValue.serverTimestamp(), "moveCount": gameModel.moveCount ]
        
        // Setup our header document
        let header = Firestore.firestore().collection("activeGame").document("\(0)")
        batch.setData(headerToStore, forDocument: header)
        
        for row in 0..<gameModel.gameBoard.count {
            for column in 0..<gameModel.gameBoard[0].count {
                
                let grid = gameModel.gameBoard[row][column]
                if grid != .empty {
                    
                    
                    // Write the moves as a batch. We won't have the actual move time as it wasn't persisted, however I'm going to
                    // add a moveTime field to keep the data consistent. Move numbers won't correspond to the actual move numbers
                    // but this doesn't matter, we're just resetting the board state.
                    
                    
                    // Create moves to upload
                    let dataToStore:[String : Any] = ["moveTime": FieldValue.serverTimestamp(),"column": column, "row": row, "player": gameModel.gameBoard[row][column].rawValue ]
                    
                    
                    // Setup our moves document
                    let gameMoves = Firestore.firestore().collection("activeGame").document("\(fakeMoveNumber)")
                    batch.setData(dataToStore, forDocument: gameMoves)
                    
                    fakeMoveNumber += 1
                }
            }
        }
        
        // Commit the batch
        batch.commit() { err in
            if let err = err {
                print("Error writing batch \(err)")
            } else {
                print("Batch write succeeded.")
                completion()
            }
        }
    }
    
    func restorePlayerTwo(completion: @escaping () -> Void) {
        
        
        FirebaseProxy.db.collection("activeGame").getDocuments() { (querySnapshot, err) in
            
            
            if let err = err {
                print("Error getting documents: \(err)")
            }
            else {
                
                for document in querySnapshot!.documents {
                    if document.documentID != "\(0)" {
                        
                        let move = document.data()
                        
                        guard let gridState = move["player"] as? String else {
                            print("Error retrieving move player ID")
                            return
                        }
                        let player = GridState(rawValue: gridState) ?? .empty
                        guard let row = move["row"] as? Int else {
                            print("Error retrieving move row")
                            return
                        }
                        guard let column = move["column"] as? Int  else {
                            print("Error retrieving move column")
                            return
                        }
                        
                        self.modelGameLogic.gameBoard[row][column] = player
                        // Hack as I can't sync the maxTurns on restart...
                        self.modelGameLogic.maxTurns = self.modelGameLogic.moveCount + 10
                    }
                    
                }
            }
        }
        completion()
        
    }
    
    
    // Used to let Player 2 know game has started
    func startGame(completion: @escaping () -> Void) {
        
        Util.log("startGame function")
        FirebaseProxy.db.collection("elect_leader").document("123456").setData(["gameStarted": true], merge: true) { error in
            if let error = error {
                Factory.displayAlert(target: GameBoardVC.self, error: error)
                //                completion()
            }
            Util.log("Game is on!")
            completion()
        }
    }
    
    
    func storeMoveFirestore(row: Int?, column: Int?, playerID: String, moveNumber: Int, completion: @escaping (Error?) -> Void) {
        
        var docData: [String: Any] = ["moveTime": FieldValue.serverTimestamp(), "player": playerID]
        // Coordinates are optionals, in case of forfeited move. Only store the fields IF they have values. Will make checking
        // much easier for the other player...
        if let rowExists = row, let columnExists = column {
            docData["row"] = rowExists
            docData["column"] = columnExists
            
        }
        
        // Update one field, creating the document if it does not exist.
        // setData runs asynchronously. completion() is the 'callback' function to let us know that it was or not successful.
        // If successful then we will update our board logical state and view state and change our state Machine
        
        Firestore.firestore().collection("activeGame").document("\(moveNumber + 1)").setData(docData, merge: false) { err in
            if let err = err {
                print("Error writing document: \(err)")
                completion(err)
            }
            else {
                Util.log("Document successfully written!")
                completion(nil)
            }
        }
    }
    
    
    
    // Have to brute force delete the game move (document) by move. Cannot just delete the collection
    func deleteCompletedGame(completion: @escaping () -> Void) {
        
        let oldGame = Firestore.firestore().collection("activeGame")
        oldGame.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            }
            else {
                
                if let snapshot = querySnapshot {
                    for document in snapshot.documents {
                        document.reference.delete()
                    }
                }
            }
            completion()
        }
    }
    
    
    
    // Called at end of game
    func resetElection()  {
        
        let reference = FirebaseProxy.db.collection("elect_leader").document("123456")
        reference.updateData(["leader_bit": false])
        reference.updateData(["gameStarted": false])
    }
    
    
    //MARK: - History Functions
    
    // Stores game results in Firestore;
    // moves were  stored in a separate collection with a reference to them; however that is inactive for now
    // Might use the moves later for a detail history view..
    func storeGameResults(_ image: UIImage?, completion: @escaping (Error?) -> Void) {
        
        // Create unique name to reference this collection. Current time will always be unique.
        // Fetch as Epoch time so it's simply a number, convert to string
        
        // Not currently used; kept for future implementation
        //        let gameMoves = "\(Date().timeIntervalSince1970)"
        //        copyGameMoves(referenceName: gameMoves )
        
        var imageData: Data? = nil
        // This should be passed in Via listener or something but use here for temporary
        let scores = CalculateScore.gameTotalBruteForce(passedInArray: modelGameLogic.gameBoard)
        
        // Get thumbnail image of gameboard
        if let image = image {
            
            imageData = resizeImage(image: image, newWidth: 80.0)?.pngData()
        }
        
        FirebaseProxy.db.collection("history").addDocument(data: [
            "playerOneName": modelGamePrefs.playerOneName,
            "playerTwoName": modelGamePrefs.playerTwoName,
            "playerOneScore": scores.playerOne,
            "playerTwoScore": scores.playerTwo,
            "gameDate": NSDate(),
            "gameBoardView": imageData as Any
            //"gameMoves": gameMoves // Simply a reference to the collection where the moves are stored.
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                completion(err)
            } else {
                print("New History Document added ")
                completion(nil)
            }
        }
    }
    
    
    
    // Make copy of finished game in Firestore so we can play it back later... Currently not used.
    // Source cited
    func copyGameMoves (referenceName: String) {
        
        let oldGame = Firestore.firestore().collection("activeGame")
        oldGame.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            }
            else {
                if let snapshot = querySnapshot {
                    for document in snapshot.documents {
                        let data = document.data()
                        let batch = Firestore.firestore().batch()
                        let docset = querySnapshot
                        
                        let historicalGame = Firestore.firestore().collection(referenceName).document()
                        
                        docset?.documents.forEach {_ in batch.setData(data, forDocument: historicalGame)}
                        
                        batch.commit(completion: { (error) in
                            if let error = error {
                                print("\(error)")
                            }
                            else {
                                print("success")
                                
                            }
                        })
                    }
                }
            }
        }
    }
    
}
