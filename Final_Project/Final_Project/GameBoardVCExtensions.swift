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
