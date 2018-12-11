//
//  GameBoardVCExtensions.swift
//  Final_Project
//
//  Created by Robert Terry on 11/24/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

// Sources - Blurring a view - https://stackoverflow.com/questions/17041669/creating-a-blurring-overlay-view

import UIKit
import Firebase
import AVFoundation


//MARK: - GameStateMachine extension
extension GameBoardVC: GameStateMachine {
    
    
    
    // As game state changes through initialization AND play, listener will modify the text field
    @objc func updateGameStateLabel() {
        
        // Update game state text field.
        textGameStatus.text = StateMachine.state.rawValue
        
    }
    
    @objc func stateElectPlayerOne() {
        
//        activityIndicator.startAnimating() // Transaction on Firstore, this could take a while
        
        Util.log("Player election function called in proxy")
        FirebaseProxy.instance.electPlayerOne() { success in
            
            if success {

                // For now write this directly to MOdel, however would like to eventually move to listener

                self.modelGameLogic.amIPlayerOne = true
                
            }
            // Both players need to initialize
            // Now advance to state .initializing
            StateMachine.state = .initializing
            
            let player =  success ? "Player One" : "Player Two"
            Factory.displayAlert(target: self, message: "You are \(player).", title: "Election Complete")

        } // End of callback closure
    
        
    }
    
    @objc func stateInitializing() {
        
        Util.log("View Controller initializing. State changed to  -> \(StateMachine.state)")
        
        
        readyPlayerOne.isHidden = true
        readyPlayerTwo.isHidden = true
        
        activityIndicator.startAnimating()
        
//        //TODO: - currently just using instance (static) variable of 'state' vice a singleton implementation
//        // VC has loaded so we change state to 2 - initializing
//        StateMachine.state = .initializing
        
        
        // This doesn't really do anything???
        //        fireStoreDB = FirebaseProxy.db // Get handle to our database
        
        // TODO: - I don't think this needs to be in a completion handler. The next state is called asynchronously and this doesn't do anything.
        FirebaseProxy.instance.requestInitialize() //{
//            Util.log("Initialization Completion handler called. ")
////            sleep(5)
////            self.activityIndicator.stopAnimating() // This is moved to state 3
//        }
        
        
    }
    
    // Called by listeners for both players for 2 states: waitingForPlayer2 & waitingForGameStart
    @objc func stateWaitingToStartGame() {
        
//        var docData: [String: Any] = [:]
        self.activityIndicator.stopAnimating()
        FirebaseProxy.instance.listenPlayersJoin() {data, error, listener in
            
            // Different logic depending on whether waiting on player OR are Joinee
            if self.modelGameLogic.amIPlayerOne {
            
                if let joined = (data["leader_bit"]) as? Bool {
                    if !joined {
                        listener.remove()
                        StateMachine.state = .readyForGame
                    }
                }
        }
            else { // Player2's listener triggered
                
                if let gameStarted = (data["gameStarted"]) as? Bool {
                    if gameStarted {
                        listener.remove()
                        StateMachine.state = .initialSnapshotOfGameBoard
                    }
                }
                
            }
        }
    }
    
    
    @objc func stateReadyForGame() {

        Util.log("function stateReadyForGame triggered via listener")
        
//        self.activityIndicator.stopAnimating()
        // Button is initially deactivated and hidden via the storyboard setup.
        newGameButtonOutlet.isEnabled = true
        newGameButtonOutlet.isHidden = false
        
        
        
        //Clear in memory cache
        // Doubt this is needed for initial first time run, as model is initialed from scratch, but
        // keep for now.
//        modelGameLogic.resetModel()
        
        Util.log("Waiting for New Game button press")
        Util.log("Machine state is \(StateMachine.state.rawValue)")

    }
    
    
    @objc func stateWaitingForUserMove() {
        
        Util.log("Machine state is \(StateMachine.state.rawValue)")
        
        // Probably don't need to disable AND hide...
        newGameButtonOutlet.isEnabled = false
        newGameButtonOutlet.isHidden = true
        
        // Allow inputs
        gameView?.isUserInteractionEnabled = true
        
        //Start move timers - now triggered via listener when changing to this state
        
        
    }
    
    // Triggered by listener in .executeMove in GameLogicModel. 'notification' passes us the move coordinates
    @objc func stateWaitingForMoveConfirmation(_ notification :Notification) {
        
        StateMachine.state = .waitingForMoveConfirmation
        
        timerCountDown.invalidate()

        // the GameLogicModel (executeMove) has determined that the move is valid (grid not occupied, in bounds,...)
        // Since logic model has determined it's a valid move, try to store in Firestore,
        activityIndicator.startAnimating()
        
//        StateMachine.state = .waitingForMoveConfirmation
        gameView?.isUserInteractionEnabled = false
        
     
        // 0) Coordinates could be optional if move was forfeited. Chain it and let the proxy deal with it
        let coordinates = notification.userInfo?["coordinates"] as? (row:Int, column:Int)
        
        // 1) Unwrap info that was passed in notification
        
        //TODO: - Will eventually remove this as it won't be necessary. Player ID is set per device
        guard let playerID = notification.userInfo!["playerID"] as? GridState else {
            fatalError("Cannot retrieve playerID")
        }
        
        guard let moveNumber = notification.userInfo!["moveCount"] as? Int else {
            fatalError("Cannot retrieve turn number")
        }
        print("player ID from stateWaitingForMoveConfir \(playerID)")
        Util.log("move number storing in Firestore is \(moveNumber)")
        // 2) Attempt to store in Firestore
        // 3) Closure is called from completion() in the async
        FirebaseProxy.instance.storeMoveFirestore(row: coordinates?.row, column: coordinates?.column,
                                         playerID: playerID.rawValue, moveNumber: moveNumber ) { err in
                if let error = err {
                    // Runs asychronously after move is written to Firestore and coonfirmation is received. This is the completion handler
                   
                    self.present(Factory.displayAlert(error), animated: true, completion: nil)
                
                }
                // 4) Successful write to Firestore so continue with game
                else {
                   
                    // A) Update game state model and the view
                    NotificationCenter.default.post(name: .moveStoredFirestore, object: self, userInfo:notification.userInfo)
                    
                    self.activityIndicator.stopAnimating()
                    
                    // B) Change state machine
                    // Move this to the increment turn logic
//                    StateMachine.state = .initialSnapshotOfGameBoard
                    
                    
                }
        }
        
    }
    
    // Triggered by listener when state changes to .waitingForOpponentMove
    @objc func stateWaitingForOpponent() {
 
        
        Util.log("Listener activitated for opponent move")
        FirebaseProxy.instance.opponentMoveFirestore() { move, listener in
            
            var docData: [String: Any] = [:]
            if StateMachine.state == .initialSnapshotOfGameBoard { // first snapshot, doesn't contain new move
               StateMachine.state = .waitingForOpponentMove // Now we can get the actual move
            }
            else {
                
                print("\(move)")


//                let ID = self.modelGameLogic.whoseTurn
                
                let playerID = GridState(rawValue: move["player"] as! String)
                docData["playerID"] = playerID
                if let coordinates = (row: move["row"], column: move["column"]) as? GridCoord {
                    docData["coordinates"] = coordinates
                }

//                let userInfo = ["playerID": ID, "coordinates": coordinates ]
                listener.remove() // don't want or need notifications while it's our move
                
                // Set listener to update the game state model and the view
                NotificationCenter.default.post(name: .moveStoredFirestore, object: self, userInfo: docData)
                
            }
        }
    }
    
    
   
    

    
    
    //    @objc func getDatabaseHandle(notification : NSNotification) -> Firestore {
    //
    //        if let info = notification.userInfo as? Dictionary<String,Int> {
    //            // Check if value present before using it
    //            if let s = info["state"] {
    //                print(s)
    //                if s == 2 { // If we are in initializing state then get handle to Firestore
    //                    fireStoreDB = FirebaseProxy.db
    //                }
    //            }
    //        }
    //        else {
    //            print("no value for key\n")
    //        }
    //        return fireStoreDB
    //    }
}
