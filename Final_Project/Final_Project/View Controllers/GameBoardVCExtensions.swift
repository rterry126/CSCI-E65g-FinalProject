//
//  GameBoardVCExtensions.swift
//  Final_Project
//
//  Created by Robert Terry on 11/24/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import UIKit
import Firebase


//MARK: - GameStateMachine extension
extension GameBoardVC: GameStateMachine {
    
    func stateInitializing() {
        
        // Initialize the game state label
        textGameStatus.text = StateMachine.state.rawValue
        
        activityIndicator.startAnimating()
        
        //TODO: - currently just using instance (static) variable of 'state' vice a singleton implementation
        // VC has loaded so we change state to 2 - initializing
        StateMachine.state = .initializing
        Util.log("View Controller initializing. State changed to  -> 2")
        
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
        Util.log("Ready for Game") // Eventually change the label I haven't created to show this...
        
        self.activityIndicator.stopAnimating()
        // Button is deactivated and hidden via the storyboard setup.
        newGameButtonOutlet.isEnabled = true
        newGameButtonOutlet.isHidden = false
        
        //Clear in memory cache
        // Doubt this is needed for initial first time run, as model is initialed from scratch, but
        // keep for now.
//        modelGameLogic.resetModel()
        
        Util.log("Waiting for New Game button press")
        Util.log("Machine state is \(StateMachine.state.rawValue)")

    }
    
    // As game state changes through initialization AND play, listener will modify the text field
    @objc func updateGameStateLabel() {
        
        // Update game state text field.
        textGameStatus.text = StateMachine.state.rawValue
        
    }
    
    @objc func stateWaitingForUserMove() {
        
        StateMachine.state = .waitingForUserMMove
        Util.log("Entered func stateWaitingForUseMove")
        Util.log("Machine state is \(StateMachine.state.rawValue)")
        
        // Probably don't need to disable AND hide...
        newGameButtonOutlet.isEnabled = false
        newGameButtonOutlet.isHidden = true
        
        // Allow inputs
        gameView?.isUserInteractionEnabled = true
        
        //Start move timers
        //(timerMove, timerWarning) = Factory.createTimers(timeToMakeMove: timeToMakeMove, target: self, functionToRun: #selector(timerFired))

        
    }
    
    // Triggered by listener in .executeMove in GameLogicModel
    @objc func tempMOveFunction(_ notification :Notification) {
        
        // the GameLogicModel (executeMove) has determined that the move is valid. Therefore lock the grid from user input
        //while we attempt to store the move to Firestore
        gameView?.isUserInteractionEnabled = false
        
     
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
        FirebaseProxy.instance.storeMove(row: coordinates.row, column: coordinates.column, playerID: playerID.rawValue, moveNumber: moveNumber ) { err in
        
            if let error = err {
                // Runs asychronously after move is written to Firestore and coonfirmation is received. This is the completion handler
                let alert = UIAlertController(title: "Firebase Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            
            //Successful write to Firestore so continue with game
            }  else
            {
             // Set listener to update the game state model and the view
                NotificationCenter.default.post(name: .moveStoredFirestore, object: self, userInfo: ["playerID": playerID, "coordinates": coordinates, "moveNumber": moveNumber ])
                
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
