//
//  HistoryDetailVC.swift
//  Final_Project
//
//  Created by Robert Terry on 11/14/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import Foundation
import UIKit


//class HistoryDetailVC: UIViewController {
//    
//    // Source previously cited
//    let screenWidth = UIScreen.main.bounds.width
//    let screenHeight = UIScreen.main.bounds.height
//    
//    // Size of game board. Set values in initializer below. Need to do this to pass the values to
//    // the constructor of the custom view when that object is instantiated
//    var numOfGridRows: Int
//    var numOfGridColumns: Int
//    
////    @IBOutlet weak var testLabel: UILabel!
////
////    var username:String = ""
////    // Stub/placeholer to build view
////    let gameBoard = [["Player One","Empty","Empty","Player One","Empty"],
////                     ["Empty","Player Two","Player One","Empty","Empty"],
////                     ["Player One","Empty","Player Two","Empty","Empty"],
////                     ["Empty","Empty","Player Two","Player One","Empty"],
////                     ["Empty","Empty","Empty","Player Two","Empty"]]
//    
//    
//        
//        
//    override func viewDidLoad() {
//            super.viewDidLoad()
////            print("Detail --> \(username)")
////            print("\(gameBoard)")
////
////            testLabel.text = username
//        
//        let gameHistoryView = GameGridViewProtocol()
//        
//        gameHistoryView.frame = CGRect(x: 0, y: 94, width: screenWidth, height: screenHeight * 0.75 )
//        
//        view.addSubview(gameHistoryView) // View hierarchy
//        Util.log("Added custom view - gameHistoryView")
//        
//        self.gameHistoryView = gameHistoryView
//        
//        gameHistoryView.dataSource = self
//        gameHistoryView.delegate = self
//        
//        // Initialize grid in view
//        gameHistoryView.createGrid()
//        
//    
//    }
//}
