//
//  GameBoardVCExtensions.swift
//  Final_Project
//
//  Created by Robert Terry on 11/24/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - reset tab controller - https://stackoverflow.com/questions/45303292/how-to-reset-root-view-controller

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
        sharedFirebaseProxy.electPlayerOne() { [unowned self] /*avoid strong reference to self in closure*/ success, name, maxTurns in
            
            if success {
                self.modelGameLogic.amIPlayerOne = true
                // If I'm player 1 then name is my name
                // Pure hack to get padding onto name so it displays better
                self.modelGamePrefs.playerOneName = " \(self.modelGamePrefs.myNameIs) "
                // Set this to empty for now, otherwise previous Player 2's name is displayed
                self.modelGamePrefs.playerTwoName = ""
            }
            // Player 2 logic
            else {
                self.modelGamePrefs.playerOneName = " \(name) "
                self.modelGameLogic.maxTurns = maxTurns
                // Set own name
                self.modelGamePrefs.playerTwoName = " \(self.modelGamePrefs.myNameIs) "
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
        sharedFirebaseProxy.requestInitialize()
    }
    
    
    
    // Called by listeners for both players for 2 states: waitingForPlayer2 & waitingForGameStart
    // Let's players know game is ready to start AND updates Player 2's name in Player 1 device
    
    // Admittedly the code in this function is a mess; added onto at the end to make resuming game work.
    @objc func stateWaitingToStartGame() {
        
        
        
        Util.log("View Controller initializing. State changed to  -> \(StateMachine.state)")
        self.activityIndicator.stopAnimating()
        
        // This lets each player know 1) 2nd Player has joined 2) When Player 1 has initiated start of game
        sharedFirebaseProxy.listenPlayersJoin() { [unowned self] /*avoid strong reference to self in closure*/ data, error, listener in
            
            // Different logic depending on whether waiting on player OR are Joinee
            
            // When Player 2 joines, leader_bit is reset to false. So
            // 1) IF Player 1, 2) try to get the leader_bit 3) IF it's false, then P2 has joined
            // Stop listening and advance state. .readyForGame gives us button to start game.
            if self.modelGameLogic.amIPlayerOne {
                
                /*** Start game resume code */
                // Not successful with restoring previous game in proxy (model not visible here), suspect scope issues. Hack to make it work
                if restoreModel(&self.modelGameLogic) { 
                    self.newGameButtonOutlet.setTitle("Resume Game", for: .normal)
                    self.modelGameLogic.maxTurns = self.modelGameLogic.moveCount + 10
                    self.redrawView()
                }
                
                
                //Cleanup items from restore
                self.modelGameLogic.amIPlayerOne = true // this is overwritten by the restore
                // For state model simplicity, I'm just assigning turn to player 1
                if self.modelGameLogic.whoseTurn == GridState.playerTwo {
                    self.modelGameLogic.setTurn()
                }
                // End of game resume code. Now resume normal operations
                
                
                // Waiting on 2nd player to join
                if let joined = (data["leader_bit"]) as? Bool {
                    if !joined {
                        listener.remove()
                        let name = data["playerTwoName"] as? String ?? "Player Two"
                        // Again, hack to get padding for better display
                        self.modelGamePrefs.playerTwoName = " \(name) "
                        StateMachine.state = .readyForGame
                    }
                }
                    
                    // else... something has gone wrong with leader_bit, but let's try to start the game
                    // anyway instead of fatal error. Worse case is that no one will respond on other end.
                else {
                    listener.remove()
                    let name = data["playerTwoName"] as? String ?? "Player Two"
                    // Again, hack to get padding for better display
                    self.modelGamePrefs.playerTwoName = " \(name) "
                    StateMachine.state = .readyForGame
                }
            }
                
                // Player 2's listener triggered
            else {
                
                
                // A) Either Player 2 has loaded a stored game or not. Redrawing won't affect view
                // either way.
                self.redrawView()
                
                // B) Cleanup items from restore, if it happened. Since what I'm setting is the
                // same if it's a brand new game, only has effect if game is resumed.
                
                self.modelGameLogic.amIPlayerOne = false // this is overwritten by the restore
                // For state model simplicity, I'm just assigning turn to player 1
                if self.modelGameLogic.whoseTurn == GridState.playerTwo {
                    self.modelGameLogic.setTurn()
                }

                
                
                // Resume normal flow
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
    
    
    // Only applicable to Player 1
    @objc func stateReadyForGame() {
        
        newGameButtonOutlet.isEnabled = true
        newGameButtonOutlet.isHidden = false
        
        
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
        Util.log("Machine state is \(StateMachine.state.rawValue)")
        
        timerCountDown.invalidate()
        
        // the GameLogicModel (executeMove) has determined that the move is valid (grid not occupied, in bounds,...)
        // Since logic model has determined it's a valid move, try to store in Firestore,
        activityIndicator.startAnimating()
        
        gameView?.isUserInteractionEnabled = false
        
        // 0) Coordinates could be optional if move was forfeited. Chain it and let the proxy deal with it
        let coordinates = notification.userInfo?["coordinates"] as? (row:Int, column:Int)
        
        // 1) Unwrap info that was passed in notification
        
        guard let playerID = notification.userInfo?["playerID"] as? GridState else {
            Factory.displayAlert(target: self, message: "Error retrieving or unwrapping playerID", title: "Move Confirmation")
            fatalError("Cannot retrieve playerID")
        }
        
        guard let moveNumber = notification.userInfo?["moveCount"] as? Int else {
            Factory.displayAlert(target: self, message: "Error retrieving or unwrapping moveCount", title: "Move Confirmation")
            fatalError("Cannot retrieve turn number")
        }
        
        Util.log("move number storing in Firestore is \(moveNumber)")
        
        // 2) Attempt to store in Firestore
        // 3) Closure is called from completion() in the async
        sharedFirebaseProxy.storeMoveFirestore(row: coordinates?.row, column: coordinates?.column,
                    playerID: playerID.rawValue, moveNumber: moveNumber ) {  [unowned self] err in
                                                    
            // Runs asychronously after move is written to Firestore and coonfirmation is received. This is the completion handler
            if let error = err {
                Factory.displayAlert(target: self, error: error)
            }
                // 4) Have successful write to Firestore so continue with game
            else {
                
                // A) Update game state model and the view
                // B) Change state machine to .initialSnapshotOfGameBoard
                // State change moved to increment turn logic for sequencing issues
                
                NotificationCenter.default.post(name: .moveStoredFirestore, object: self, userInfo:notification.userInfo)
                
                self.activityIndicator.stopAnimating()
            }
        } // End of completion handler
    }
    
    
    // Triggered by listener when state changes to .waitingForOpponentMove
    @objc func stateWaitingForOpponent() {
        
        
        Util.log("Listener activitated for opponent move")
        // 1) opponentMoveFirestore sets a Firestore listener. 2) Must discard initial snapshot
        // 3) and wait for actual move data 4) Finally kill the listener until we're waiting on
        // opponent move again.
        
        // Closure is completion handler. Is triggered by A) Initial snapshot and B) Actual move
        // Ideally should be called twice; ignore data in first call...
        sharedFirebaseProxy.opponentMoveFirestore() { move, listener in
            
            var userInfo: [String: Any] = [:]
            
            // first snapshot, doesn't contain new move
            if StateMachine.state == .initialSnapshotOfGameBoard {
                
                // Advance the state. Now we'll use the listener information
                StateMachine.state = .waitingForOpponentMove
            }
                
                // else we have an actual move
            else {
                
                if let gridState = move["player"] as? String {
                    userInfo["playerID"] = GridState(rawValue: gridState)
                }
                
                if let coordinates = (row: move["row"], column: move["column"]) as? GridCoord {
                    userInfo["coordinates"] = coordinates
                }
                
                listener.remove() // don't want or need notifications while it's our move
                
                // Set listener to update the game state model and the view
                NotificationCenter.default.post(name: .moveStoredFirestore, object: self, userInfo: userInfo)
                
            }
        }
    }
    
    
    @objc func stateEndOfGame() {
        // Called when num of turns in model is increased to max turns.
        // Should be called by both devices simultaneously
        
        let scores = CalculateScore.gameTotalBruteForce(passedInArray: modelGameLogic.gameBoard)
        
        // Disable inputs
        gameView?.isUserInteractionEnabled = false
        
        
        // Kill/delete the move timer/ no longer needed
        timerCountDown.invalidate()
        
        //Kill any remaining listeners
        sharedFirebaseProxy.listener.remove()
        
        
        //Kill the observers. If we play again and they aren't killed, sequencing is affected.
        
        Factory.killObserver(observer: self, listeners: observerStateMachine)
        Factory.killObserver(observer: self, listeners: observerLogicModel)
        Factory.killObserver(observer: self, listeners: observerPreferencesModel)
        
        updateGameStateLabel() // Listener isn't activating this at game end. Force update for now.
        
        // Save a Thumbnail for the history
        // method is extension of the custom view. Source cited in GameBoardView
        let gameImage = gameView?.asImage()
        
        
        // So we don't have double history entries
        if modelGameLogic.amIPlayerOne {
            sharedFirebaseProxy.storeGameResults(gameImage) { [unowned self] err in
                
                if let error = err {
                    // Runs asychronously after move is written to Firestore and coonfirmation is received. This is the completion handler
                    
                    Factory.displayAlert(target: self, error: error)
                    
                }
                    // 4) Successful write to Firestore so continue with deleting old game
                else {
                    
                    self.sharedFirebaseProxy.deleteCompletedGame() {}
                }
            }
        }
        
        sharedFirebaseProxy.resetElection()
        
        
            // Delete saved game, otherwise we are in a loop that just fetches saved game
            do {
                Util.log("End of game. Deleting saved game state \(modelGameLogic)")
                try Persistence.deleteSavedGame()
            }
            catch let e {
                Util.log("Deleting previous game failed: \(e)")
            }
        
        
        
        // Play again?
        // So as I understand the code that is the action, we are resetting the view controller,
        // which causes it to reload. This is what I want, as viewDidLoad will run again and
        // the default initialization will be run.
        
        
        let alert = UIAlertController(title: "End of Game", message: "Player 1 score is \(scores.playerOne)\n Player 2 score is \(scores.playerTwo)\nPlay Again?", preferredStyle: .alert)
        
        
        // .destructive to color 'Yes' in red...
        alert.addAction(UIAlertAction(title: "Yes", style: .default , handler: {
            action in
            
            self.modelGameLogic.resetModel()
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            
            guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "GameBoardVC") as? GameBoardVC else {
                print("Cannot start new game")
                fatalError("Cannot Start new game")
            }
            
            guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("Cannot start new game")
                fatalError("Cannot Start new game")
            }
            
            let navigationController = UINavigationController(rootViewController: nextViewController)
            
            appdelegate.window?.rootViewController = navigationController
            
            let tabBarController = storyBoard.instantiateViewController(withIdentifier: "myTabBarController") as! UITabBarController
            UIApplication.shared.keyWindow?.rootViewController = tabBarController
            UIApplication.shared.keyWindow?.makeKeyAndVisible()

            
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
        // Ideally reloading the VC should carry the rest of the reset
        
    }
    
}
