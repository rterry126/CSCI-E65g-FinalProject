//
//  Factory.swift
//  
//
//  Created by Robert Terry on 11/12/18.
//

import UIKit        // Alert creaton function


// Not sure if these are really 'Factories', however anytime I was creating more than 1 of an object I just put the code here to simplify
class Factory {
    
   
    
    
    // Pass an array of observers to set
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
    
    // During the end of game state, functioning observers were causing issues. So stateEndOfGame just kills them all.
    static func killObserver(observer: Any, listeners: observerArray)  {
    
        // If array is 'empty' it isn't nil (I tested this) so let's log that an empty array was passed.
        if listeners.count > 0 {
            for listener in listeners {
                NotificationCenter.default.removeObserver(observer, name: listener.name, object: nil)
            }
        }
        else {
            print(String(describing: observer))
            print("Listener not removed.")
        }
        
    }
    
    /********* Timer factory *********/
    
    // Superceded by code simplificaiton
    
    /************** Alert Factory *********************/
    
   
    // With overloads and default values, I essentially have 4 functions here
    // Alerts that have more extensive action (handler isn't nil) don't use these (PreferencesVC)
    
    // Used to pass error messages
    static func displayAlert(target: AnyObject, error: Error, title: String = "Firestore Error") {
        
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        target.present(alert, animated: true, completion: nil)
    }
    
    
    // Used to pass strings
    static func displayAlert(target: AnyObject, message: String, title: String = "Game Error") {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        target.present(alert, animated: true, completion: nil)
    }
    
}
