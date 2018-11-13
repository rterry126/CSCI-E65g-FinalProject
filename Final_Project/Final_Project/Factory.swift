//
//  Factory.swift
//  
//
//  Created by Robert Terry on 11/12/18.
//
// Source - https://medium.com/swiftworld/swift-world-design-patterns-singleton-b1dc663f4fdd

import Foundation

// Currently just used for Singletons, will rename if used for other factories...
class SingletonFactory {
    
   
    static let sharedInstance: GameLogicModelProtocol = {
        let instance = GameLogicModel()
        return instance
    }()
    
    
//    private static let _model = GameLogicModel()
//    
//    
//    // This is a “lock for honest people"
////    public var readOnlyModel: ReadOnlyModelProtocol {
////        get {
////            return _model
////        }
////    }
//    
//    public  var instance: GameLogicModel {
//        get {
//            return SingletonFactory._model
//        }
//    }
}
