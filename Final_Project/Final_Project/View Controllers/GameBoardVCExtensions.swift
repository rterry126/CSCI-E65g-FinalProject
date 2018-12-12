//
//  GameBoardVCExtensions.swift
//  Final_Project
//
//  Created by Robert Terry on 11/24/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//


import UIKit
import Firebase
import AVFoundation

// The various states drive these functions. Ostensibly they are view controller related; putting them
// in an extension seems to organize it better logically and physically code wise...

// For the most part the functions are triggered by the listeners by the same name.


//MARK: - GameStateMachine extension
extension GameBoardVC: GameStateMachine {
    
    
    
    // As game state changes through initialization AND play, listener will modify the text field
    @objc func updateGameStateLabel() {
        
        // Update game state text field.
        textGameStatus.text = StateMachine.state.rawValue
        
    }
    
    @objc func stateElectPlayerOne() {
        
        
        Util.log("Player election function called in proxy")
        FirebaseProxy.instance.electPlayerOne() { success in
            
            if success {
                self.modelGameLogic.amIPlayerOne = true
            }
            
            // Both players need to initialize
            // Now advance to state .initializing
            StateMachine.state = .initializing
            
            let player =  success ? "Player One" : "Player Two"
            Factory.displayAlert(target: self, message: "You are \(player).", title: "Election Complete")

        } // End of callback closure
    }
    
    
   // Initializing the game state (moves) in Firestore. We already have handle as we've elected P1
    @objc func stateInitializing() {
        
        Util.log("View Controller initializing. State changed to  -> \(StateMachine.state)")
        
        
        readyPlayerOne.isHidden = true
        readyPlayerTwo.isHidden = true
        
        activityIndicator.startAnimating() // Show activity while we initialize the game state
        

        // Next state is called asynchronously from within initialization code
        FirebaseProxy.instance.requestInitialize()
    }
    
    // Called by listeners for both players for 2 states: waitingForPlayer2 & waitingForGameStart
    @objc func stateWaitingToStartGame() {
        
//        var docData: [String: Any] = [:]
        self.activityIndicator.stopAnimating()
        FirebaseProxy.instance.listenPlayersJoin() {data, error, listener in
            
            // Different logic depending on whether waiting on player OR are Joinee
            
            // When Player 2 joines, leader_bit is reset to false. So
            // 1) IF Player 1, 2) try to get the leader_bit 3) IF it's false, then P2 has joined
            // Stop listening and advance state. .readyForGame gives us button to start game.
            if self.modelGameLogic.amIPlayerOne {
            
                if let joined = (data["leader_bit"]) as? Bool {
                    if !joined {
                        listener.remove()
                        StateMachine.state = .readyForGame
                    }
                }
                
                // else... something has gone wrong with leader_bit, but let's try to start the game
                // anyway instead of fatal error. Worse case is that no one will respond on other end.
                else {
                    listener.remove()
                    StateMachine.state = .readyForGame
                }
        }
                
            // Player2's listener triggered
            else {
                
                // 1) IF Player 2, 2) try to get the gameStarted bit 3) IF true then advance to waiting for
                // the other player's move (via the .initialSnapshot... state)
                if let gameStarted = (data["gameStarted"]) as? Bool {
                    if gameStarted {
                        listener.remove()
                        StateMachine.state = .initialSnapshotOfGameBoard
                    }
                }
                // else... something has gone wrong with gameState bit, but let's try to start the game
                // anyway instead of fatal error. Worse case is that move never comes...
                else {
                    listener.remove()
                    StateMachine.state = .initialSnapshotOfGameBoard
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
    
    
    // TODO:- Also much Firestore cleanup and resetting needs to be here...
    @objc func stateEndOfGame() {
        // Called when num of turns in model is increased to max turns.
        
        let scores = CalculateScore.gameTotalBruteForce(passedInArray: modelGameLogic.gameBoard)
        //        Factory.displayAlert(target: self, message: "Player 1 score is \(scores.playerOne)\n Player 2 score is \(scores.playerTwo)", title: "End of Game")
        //        // Disable inputs
        gameView?.isUserInteractionEnabled = false
        
        
        
        // Kill/delete the move timer/ no longer needed
        timerCountDown.invalidate()
        
        updateUI()
        
        // Going to save a Thumbnail for the history
        let gameImage = gameView?.asImage()
        
        
        // So we don't have double history entries
        if modelGameLogic.amIPlayerOne {
            FirebaseProxy.instance.storeGameResults(gameImage) { err in
                
                if let error = err {
                    // Runs asychronously after move is written to Firestore and coonfirmation is received. This is the completion handler
                    
                    self.present(Factory.displayAlert(error), animated: true, completion: nil)
                    
                }
                    // 4) Successful write to Firestore so continue with deleting old game
                else {
                    
                    FirebaseProxy.instance.deleteGameMoves()
                    
                }
                
            }
        }
        
        FirebaseProxy.instance.resetPlayerOne()
        
        // Commented out on 12.1.18 - Somehow end of game is letting play continue although
        //inputs are invalidated above
        
        //        // Delete saved game, otherwise we are in a loop that just fetches saved game
        //        do {
        //            Util.log("End of game. Deleting saved game state \(modelGameLogic)")
        //
        //            try Persistence.deleteSavedGame()
        //
        //            // Get image of gameboard
        //            //TODO: Force unwrapping now just to test
        //            let image = gameView!.asImage()
        //            sharedFirebaseProxy.storeGameBoardImage(image: image)
        //
        //
        //        }
        //        catch let e {
        //            Util.log("Deleting previous game failed: \(e)")
        //        }
        //
        
        
        // Play again?
        // So as I understand the code that is the action, we are resetting the view controller,
        // which causes it to reload. This is what I want, as viewDidLoad will run again and
        // the default initialization will be run.
        
        // commented out on 11/10. Initializing new game code has been modifed due to singleton/Firebase
        
        let alert = UIAlertController(title: "End of Game", message: "Player 1 score is \(scores.playerOne)\n Player 2 score is \(scores.playerTwo)\nPlay Again?", preferredStyle: .alert)
        
        //        if let gameBoardVC = window?.rootViewController?.children[0] as? GameBoardVC {
        //            gameBoardVC.modelGamePrefs = GamePrefModel()
        //        }
        // .destructive to color 'Yes' in red...
        alert.addAction(UIAlertAction(title: "Yes", style: .default , handler: {
            action in
            
            self.modelGameLogic.resetModel()
            //            modelGamePrefs = nil
            //            sharedFirebaseProxy = nil
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "GameBoardVC") as! GameBoardVC
            let navigationController = UINavigationController(rootViewController: nextViewController)
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.window!.rootViewController = navigationController
            
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
        
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
