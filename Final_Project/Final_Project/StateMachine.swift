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
            
            print("State changed --> \(self.state)")
            
            NotificationCenter.default.post(name: .stateChanged, object: self, userInfo: ["state": StateMachine.State.RawValue()])
            
        }
    }
    
    enum State: Int {
        
        case uninitialized = 1 // Set first state as '1' to match up with lecture docs
        case initializing
        case readyForGame
        case waitingForUserMMove
        case waitingForMoveConfirmation
        case waitingForOpponentMove
        case gameOver
        
        
    }
}
