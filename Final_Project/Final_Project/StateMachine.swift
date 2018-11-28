//
//  StateMachine.swift
//  
//
//  Created by Robert Terry on 11/17/18.
//

import Foundation

class StateMachine: StateMachineProtocol {
    
    // Create Singleton instance
//    static let instance: StateMachineProtocol = StateMachine()
    
    private static let _instance: StateMachineProtocol = StateMachine()
    private init() {}
    
    static var instance: StateMachineProtocol {
        return _instance
    }
    
    static var state: State = .uninitialized {
        didSet {
            
            Util.log("state variable didSet to  --> \(self.state)")
            
            
            let notificatonName: NSNotification.Name
            
            switch state {
                
            case .uninitialized: // Added so switch would be exhaustive, no listener needed on startup
                return

            case .initializing:
                notificatonName = Notification.Name.initializing
                Util.log("state changed to .initializing")

            case .readyForGame:
                notificatonName = Notification.Name.readyForGame
                Util.log("state changed to .readyForGame")

            case .waitingForUserMMove:
                notificatonName = Notification.Name.waitingForUserMove
                Util.log("state changed to .waitingForUserMove")

            case .waitingForMoveConfirmation:
//                notificatonName = Notification.Name.waitingForMoveConfirmation
                //This listener is embeded in the model logic function executeMove, as it needs the move coordinates, etc to pass to selector function
                return
                
            case .initialSnapshotOfGameBoard:
                notificatonName = Notification.Name.initialSnapshotOfGameBoard
                Util.log("state changed to .waitingForUserMove")


            case .waitingForOpponentMove:
                notificatonName = Notification.Name.waitingForOpponentMove

            case .gameOver:
                notificatonName = Notification.Name.gameOver
                
            }
            NotificationCenter.default.post(name: notificatonName, object: self) // Used to drive the game state
            NotificationCenter.default.post(name: .stateChanged , object: self) // Just used to update state label on game screen
            

//                NotificationCenter.default.post(name: .waitingForOpponentMove, object: self) //, userInfo: ["state": StateMachine.State.RawValue()])
//            }
            
        }
    }
    
    enum State: String {
        
        case uninitialized = "Welcome"
        case initializing = "Initializing"
        case readyForGame = "Ready for game"
        case waitingForUserMMove = "Ready for Your Move"
        case waitingForMoveConfirmation = "Waiting for confirmation of Your move"
        // So when we first set a listener on Firestore waiting for opponent's move it returns current game board. We need to discard this
        // and wait for the NEXT listener update, which is the opponent move. Could just use BOOL logic in the callback but this
        // might be a little cleaner...
        case initialSnapshotOfGameBoard = "Waiting for opponent's move "
        case waitingForOpponentMove = "Waiting for opponent's move"
        case gameOver = "Game Over"
        
    }
}
