//
//  AppDelegate.swift
//  Assignment7-rterry126
//
//  Created by Robert Terry on 10/11/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Source - sharing state (i.e. models) between VC - https://code.tutsplus.com/tutorials/the-right-way-to-share-state-between-swift-view-controllers--cms-28474

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Because we are using a Navigation controller we need to specify children[0]
        // to return GameBoardVC. By trial/error, if we move the entry point to this view controller
        // it's not needed. Not sure if there is a better way....
//        if let gameBoardVC =  window?.rootViewController?.children[0] as? GameBoardVC {
//            gameBoardVC.modelGamePrefs = GamePrefModel()
//        }
//        else {
//            fatalError("Could not initialize GamePrefModel")
//        }
        FirebaseApp.configure()
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        
        // Setup test data
        let playerOneName = "John"
        let playerTwoName = "Susan"
        let playerOneScore = 5
        let playerTwoScore = 2
        
        let gameBoard = [["Player One","Empty","Empty","Player One","Empty"],
                         ["Empty","Player Two","Player One","Empty","Empty"],
                         ["Player One","Empty","Player Two","Empty","Empty"],
                         ["Empty","Empty","Player Two","Player One","Empty"],
                         ["Empty","Empty","Empty","Player Two","Empty"]]
        
        // Add a new document with a generated ID
        var ref: DocumentReference? = nil
        
        ref = db.collection("history_test").addDocument(data: [
            "playerOneName": playerOneName,
            "playerTwoName": playerTwoName,
            "playerOneScore": playerOneScore,
            "playerTwoScore": playerTwoScore,
            "gameBoard": [
                "0": gameBoard[0],
                "1": gameBoard[1],
                "2": gameBoard[2],
                "3": gameBoard[3],
                "4": gameBoard[4]
            ],
            "created_at": NSDate()
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
        
//        // Add a second document with a generated ID.
//        ref = db.collection("history_test").addDocument(data: [
//            "playerOneName": "Timothy",
//            "playerTwoName": "Jean",
//            "playerOneScore": 6,
//            "playerTwoScore": 0,
//            "created_at": NSDate()
//        ]) { err in
//            if let err = err {
//                print("Error adding document: \(err)")
//            } else {
//                print("Document added with ID: \(ref!.documentID)")
//            }
//        }
        
        db.collection("history_test").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
//                    let timestamp: Timestamp = document.get("created_at") as! Timestamp
//                    let date: Date = timestamp.dateValue()
//                    print("\(date)")
                    
                }
            }
        }
        
        return true
    }

   

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

