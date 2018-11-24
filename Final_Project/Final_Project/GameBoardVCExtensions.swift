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
        
        //TODO: - currently just using instance (static) variable of 'state' vice a singleton implementation
        // VC has loaded so we change state to 2 - initializing
        StateMachine.state = .initializing
        Util.log("View Controller initializing. State changed to  -> 2")
        
        // This doesn't really do anything???
        //        fireStoreDB = FirebaseProxy.db // Get handle to our database
        FirebaseProxy.instance.requestInitialize() {
            Util.log("Initialization Completion handler called. ")
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
