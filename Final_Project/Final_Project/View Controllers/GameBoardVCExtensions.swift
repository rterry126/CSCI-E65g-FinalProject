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
            Factory.displayAlert(target: self, message: "You are \(player)", title: "Election Complete")

        } // End of callback closure
    
        
    }
    
    @objc func stateInitializing() {
        
        Util.log("View Controller initializing. State changed to  -> 2")
        
        
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
    
    @objc func stateReadyForGame() {

        Util.log("function stateReadyForGame triggered via listener")
        
        self.activityIndicator.stopAnimating()
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
        
        //TODO: - Change sound
        // Audio to let user know it's their turn
        AudioServicesPlayAlertSound(SystemSoundID(1103))
        
        // Probably don't need to disable AND hide...
        newGameButtonOutlet.isEnabled = false
        newGameButtonOutlet.isHidden = true
        
        
        // Allow inputs
        gameView?.isUserInteractionEnabled = true
        
        //Start move timers
        //(timerMove, timerWarning) = Factory.createTimers(timeToMakeMove: timeToMakeMove, target: self, functionToRun: #selector(timerFired))

        
    }
    
    // Triggered by listener in .executeMove in GameLogicModel. 'notification' passes us the move coordinates
    @objc func stateWaitingForMoveConfirmation(_ notification :Notification) {
        
        // the GameLogicModel (executeMove) first determines that the move is valid (grid not occupied, game not over, in bounds,...)
        // IF valid, only then do we attempt to store the move to the cloud..
        activityIndicator.startAnimating()
        
//        StateMachine.state = .waitingForMoveConfirmation
//        gameView?.isUserInteractionEnabled = false
        
     
        // notification has a dict 'userInfo' that we've used to pass moves, etc. Dict is optional and must be unwrapped
        guard let coordinates = notification.userInfo!["coordinates"] as? (row:Int, column:Int) else {
            fatalError("Cannot retrieve coordinates of move")
        }
        
        //TODO: - Will eventually remove this as it won't be necessary. Player ID is set per device
        guard let playerID = notification.userInfo!["playerID"] as? GridState else {
            fatalError("Cannot retrieve playerID")
        }
        
        guard let moveNumber = notification.userInfo!["totalTurns"] as? Int else {
            fatalError("Cannot retrieve turn number")
        }
        
        //Attempt to store in Firestore
        //Closure is called from completion() in the async
        FirebaseProxy.instance.storeMoveFirestore(row: coordinates.row, column: coordinates.column,
                                         playerID: playerID.rawValue, moveNumber: moveNumber ) { err in
                if let error = err {
                    // Runs asychronously after move is written to Firestore and coonfirmation is received. This is the completion handler
                   
                    self.present(Factory.createAlert(error), animated: true, completion: nil)
                
                }
                //Successful write to Firestore so continue with game
                else {
                   
                    // Set listener to update the game state model and the view
                    NotificationCenter.default.post(name: .moveStoredFirestore, object: self, userInfo:notification.userInfo)
                    
                    self.activityIndicator.stopAnimating()
                    StateMachine.state = .initialSnapshotOfGameBoard
                    
                    
                }
        }
        
    }
    
    // Triggered by listener when state changes to .waitingForOpponentMove
    @objc func stateWaitingForOpponent() {
        
//        blurView(view: gameView)
        
//        var stateFirstCallback: Bool = true
        
        Util.log("Listener activitated for opponent move")
        FirebaseProxy.instance.opponentMoveFirestore() { move, listener in
            
            
            if StateMachine.state == .initialSnapshotOfGameBoard { // first snapshot, doesn't contain new move
               StateMachine.state = .waitingForOpponentMove // Now we can get the actual move
            }
            else {
                
                print("\(move)")
                
                //TODO: - parrse to ensure data is correct and move is correct//?
//                print("row \(move["row"])")
//                print("col \(move["column"])")

                let ID = self.modelGameLogic.whoseTurn
                let coordinates = (row: move["row"], column: move["column"]) as! GridCoord
                print(coordinates)
//                let userInfo = ["playerID": ID, "coordinates": coordinates ]
                listener.remove() // don't want or need notifications while it's our move
                
                // Set listener to update the game state model and the view
                NotificationCenter.default.post(name: .moveStoredFirestore, object: self, userInfo: ["playerID": ID, "coordinates": coordinates])
                
                StateMachine.state = .waitingForUserMove
            }
            
        }
        
        
        
    }
    
//    func blurView(view: UIView?) {
//        if let view = view {
//            if !UIAccessibility.isReduceTransparencyEnabled {
//                view.backgroundColor = .clear
//
//                let blurEffect = UIBlurEffect(style: .regular)
//                let blurEffectView = UIVisualEffectView(effect: blurEffect)
//                //always fill the view
//                blurEffectView.frame = view.frame.offsetBy(dx: 0.0, dy: -94.0) // Only blur the board
////                blurEffectView.frame = self.view.bounds
//                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//                view.addSubview(blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
//            } else {
//                view.backgroundColor = .black
//            }
//        }
//    }
    
    
    
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
