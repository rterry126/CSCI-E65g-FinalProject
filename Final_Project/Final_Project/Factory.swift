//
//  Factory.swift
//  
//
//  Created by Robert Terry on 11/12/18.
//
// Source - https://medium.com/swiftworld/swift-world-design-patterns-singleton-b1dc663f4fdd

import Foundation
import AVFoundation // Used to notify when timer/turn is about to expire via audio.


// Initially just created for Singleton generation, however was creating observers and
// timers using convenience code so move that here as well.
class Factory {
    
   // Singleton Creation
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
    
    /********* Observer factory *********/
    
    static func createObserver(observer: Any, listeners: observerArray)  {
        
        // Loop through and subscribe to each listener. 'Observer' (normally 'self') is the same for each item in the array passed in.
        // However this can be used for different VC's, models, etc...
        
        // If array is 'empty' it isn't nil (I tested this) so let's log that an empty array was passed.
        if listeners.count > 0 {
            for listener in listeners {
                NotificationCenter.default.addObserver(observer, selector: listener.selector, name: listener.name, object: nil)
            }
        }
        else {
            print(String(describing: observer))
            print("Listener array not set.")
        }
        
        
    }
    
    /********* Timer factory *********/

    
    // A move timer and a 2 second (untile move expires) timer are created and returned via tuple.
    // Purpose of timerWarning is to play audio alert so it's action is 'hardcoded' in the closure.
    static func createTimers(timeToMakeMove timeInterval: TimeInterval, target: Any, functionToRun selector: Selector ) -> (Timer,Timer) {
        
        let timerMove = Timer.scheduledTimer(timeInterval: timeInterval, target: target, selector: selector, userInfo: nil, repeats: false)
        
        let timerWarning = Timer.scheduledTimer(withTimeInterval: timeInterval - 2.0, repeats: false) { timer2 in
            AudioServicesPlayAlertSound(SystemSoundID(1103))
        }
        
        // Supposedly if timing isn't critical this is energy efficient.
        timerMove.tolerance = 0.4
        timerWarning.tolerance = 0.2
        
        return (timerMove, timerWarning)
    }
    

    
    
}
