//
//  HistoryDetailVC.swift
//  Final_Project
//
//  Created by Robert Terry on 11/14/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

import Foundation
import UIKit


class HistoryDetailVC: UIViewController {
    
    @IBOutlet weak var testLabel: UILabel!
    
        var username:String = ""
        
        
        override func viewDidLoad()
        {
            super.viewDidLoad()
            print("Detail --> \(username)")
            
            testLabel.text = username
        }
    
    
    
}
