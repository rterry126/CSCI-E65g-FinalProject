//
//  Notifications.swift
//  Final_Project
//
//  Created by Robert Terry on 11/9/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - https://stackoverflow.com/questions/38889125/swift-3-how-to-use-enum-raw-value-as-nsnotification-name


import Foundation

extension Notification.Name {
    
    static let turnCountIncreased = NSNotification.Name("turnCountIncreased")
    
    static let gameState = NSNotification.Name("gameState")
    static let moveExecuted = NSNotification.Name("moveExecuted")
    static let namesChanged = NSNotification.Name("namesChanged")
    static let colorsChanged = NSNotification.Name("colorsChanged")
    static let stateChanged = NSNotification.Name("stateChanged")
    
    static let readyForGame = NSNotification.Name("readyForGame")
    static let waitingForUserMove = NSNotification.Name("waitingForUserMove")

    
    




    
    
}
