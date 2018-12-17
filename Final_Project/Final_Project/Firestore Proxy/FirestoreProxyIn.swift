//
//  FirestoreProxyInbound.swift
//  Final_Project
//
//  Created by Robert Terry on 12/16/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

//import Foundation
import Firebase

extension FirebaseProxy {
    
    /************** Inbound (mostly) Firestore Functions  ****************/
    
    func opponentMoveFirestore(completion: @escaping ([String: Any], ListenerRegistration) -> Void ) {
        print("opponent move Firestore function")
        
        // Just care about latest move
        moveQuery = Firestore.firestore().collection("activeGame").order(by: "moveTime", descending: true ).limit(to: 1)
        
        listener =  moveQuery?.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(String(describing: error))")
                return
            }
            
            // First snapshot is before move, we use 2nd snapshot (2nd time listener fires) in state func
            snapshot.documentChanges.forEach { diff in
                var temp: [String: Any]
                
                if (diff.type == .added) {
                    print("New move: \(diff.document.data())")
                    temp = diff.document.data()
                    print("temp is \(temp)")
                    completion(temp, self.listener)
                    
                }
            }
        }
    }
    
    
    // This lets each player know 1) 2nd Player has joined 2) When Player 1 has initiated start of game
    func listenPlayersJoin(completion: @escaping ([String: Any], Error?, ListenerRegistration) -> Void) {
        
        let joinQuery = Firestore.firestore().collection("elect_leader").limit(to: 1)
        
        listenerJoin =  joinQuery.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching document: \(String(describing: error))")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                
                var temp: [String: Any]
                if (diff.type == .modified) {
                    temp = diff.document.data()
                    completion(temp, nil, self.listenerJoin)
                }
            }
        }
    }
    
    
    func downloadHistory( completion: @escaping ([Game], Error?) -> Void) {
        
        print("Function downloadHistory called")
        
        var resultsArray = [Game]()
        // Create query.
        historyQuery = Firestore.firestore().collection("history").order(by: "gameDate", descending: true ).limit(to: 10)
        
        listenerHistory =  historyQuery?.addSnapshotListener { ( documents, error) in
            
            guard let snapshot = documents else {
                if let error = error {
                    print(error)
                    // Return error to async calling closure in HistoryMasterVC
                    completion(resultsArray, error)
                }
                return
            }
            // Basically go through the sequence and pull out the data...
            resultsArray = snapshot.documents.map { (document) -> Game in
                if let game = Game(dictionary: document.data(), id: document.documentID) {
                    return game
                }
                else {
                    fatalError("Unable to initialize type \(Game.self) with dictionary \(document.data())")
                }
            }
            // Return results to async calling closure in HistoryMasterVC
            print("results array size is \(resultsArray.count)")
            completion(resultsArray, nil)
        }
    }
    
}
