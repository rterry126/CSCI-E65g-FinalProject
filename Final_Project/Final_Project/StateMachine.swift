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
        
        // Get the notification name when the case is valid and then post at the bottom of didSet block
        // This just keeps from having to post in each case statement...
    
            let notificationName: NSNotification.Name
            
            switch state {
                
            case .uninitialized: // Added so switch would be exhaustive, no listener needed on startup
                return
                
            case .electPlayerOne: // Added before the game is initialized. Whoever is player one will upload saved game, if it exists.
                notificationName = Notification.Name.electPlayerOne
                Util.log("state changed to .electPlayerOne")

            case .initializing:
                notificationName = Notification.Name.initializing
                Util.log("state changed to .initializing")
                
            case .waitingForPlayer2: // ONLY Player 1 should reach this state
                notificationName = Notification.Name.waitingForPlayer2
                Util.log("state changed to .waitingForPlayer2")
                
            case .waitingForGameStart: // ONLY Player 2. Basically same as ready for game but no button
                notificationName = Notification.Name.waitingForGameStart
                Util.log("state changed to .waitingForGameStart")

            case .readyForGame:
                notificationName = Notification.Name.readyForGame
                Util.log("state changed to .readyForGame")

            case .waitingForUserMove:
                notificationName = Notification.Name.waitingForUserMove
                Util.log("state changed to .waitingForUserMove")

            case .waitingForMoveConfirmation:
//                notificatonName = Notification.Name.waitingForMoveConfirmation
                //This listener is embeded in the model logic function executeMove, as it needs the move coordinates, etc to pass to selector function
                return
                
            case .initialSnapshotOfGameBoard:
                notificationName = Notification.Name.initialSnapshotOfGameBoard
                Util.log("state changed to .initial snapshot of board")


            case .waitingForOpponentMove:
                Util.log("state changed to .waitingForOpponentMove")

//                notificatonName = Notification.Name.waitingForOpponentMove
                return

            case .gameOver:
                notificationName = Notification.Name.gameOver
                
            }
            NotificationCenter.default.post(name: notificationName, object: self) // Used to drive the game state
            NotificationCenter.default.post(name: .stateChanged , object: self) // Just used to update state label on game screen
            
        }
    }
    
    enum State: String {
        
        case uninitialized = "Welcome"
        case electPlayerOne = "Determining Player One"
        case initializing = "Initializing"
        case waitingForPlayer2 = "Waiting for player to join"
        case waitingForGameStart = "Waiting for Player 1 to start game"
        case readyForGame = "Ready for game"
        case waitingForUserMove = "Ready for Your Move"
        case waitingForMoveConfirmation = "Waiting for confirmation of Your move"
        // So when we first set a listener on Firestore waiting for opponent's move it returns current game board. We need to discard this
        // and wait for the NEXT listener update, which is the opponent move. Could just use BOOL logic in the callback but this
        // might be a little cleaner...
        case initialSnapshotOfGameBoard = "Waiting for opponent's move "
        case waitingForOpponentMove = "Waiting for opponent's move"
        case gameOver = "Game Over"
        
    }
}
