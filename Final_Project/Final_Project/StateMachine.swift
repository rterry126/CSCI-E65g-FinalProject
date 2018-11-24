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
            
            NotificationCenter.default.post(name: .stateChanged, object: self) //, userInfo: ["state": StateMachine.State.RawValue()])
            
        }
    }
    
    enum State: String {
        
        case uninitialized = "Welcome"
        case initializing = "Initializing"
        case readyForGame = "Ready for game"
        case waitingForUserMMove = "Ready for Your Move"
        case waitingForMoveConfirmation = "Waiting for confirmation of Your move"
        case waitingForOpponentMove = "Waiting for opponent's move"
        case gameOver = "Game Over"
        
        
    }
}
