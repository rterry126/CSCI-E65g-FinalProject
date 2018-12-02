//
//  PreferencesVC.swift
//  Final_Project_rterry126
//
//  Created by Robert Terry on 10/20/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

// Sources - Return to main view using button. Dismiss doesn't work for nav controllers - https://stackoverflow.com/questions/47322379/swift-how-to-dismiss-all-of-view-controllers-to-go-back-to-root
// sources - Alert tutorial - https://learnappmaking.com/uialertcontroller-alerts-swift-how-to/

import UIKit

internal class PreferencesVC : UIViewController {
    
    private let colorPickerVC = ColorPickerViewController()
    
    // GameBoardVC in instantiating the modelGamePref and passing this VC a reference. This is optional
    // as it can't be guaranteed that object was created or passed.
    var modelGamePrefs: GamePrefModelProtocol?
    
    // Delegate to save the model state. This VC has no knowledge of the model
    weak open var delegate: PreferencesVCDelegate?// default is nil. weak reference
    
    // Used to determine which button was pressed for color picker
    var buttonTag: Int = 0 //  Set to 0 (Player 1 button) so we can declare it here. Otherwise it needs to go into init() or viewDidLoad
    
    
    @IBOutlet weak var playerOneNameText: UITextField!
    @IBOutlet weak var playerTwoNameText: UITextField!
    @IBOutlet weak var gameNameText: UITextField!
    
    @IBOutlet weak var playerOneColorBtn: UIButton!
    @IBOutlet weak var playerTwoColorBtn: UIButton!
    @IBOutlet weak var rowsSlider: UISlider!
    @IBOutlet weak var columnsSlider: UISlider!
    
    
    @IBOutlet weak var rowsText: UILabel!
    @IBOutlet weak var columnsText: UILabel!
    
    
    // Update the number of rows label when the slider is moved
    @IBAction func rowsSliderSet(_ sender: Any) {
        rowsText.text = Int(rowsSlider.value).description
    }
    @IBAction func columnsSliderSet(_ sender: Any) {
        columnsText.text = Int(columnsSlider.value).description
    }
    
    // Save the game state. I don't want to pass a reference to the game logic model here, plus
    // I don't think that this VC should have 'knowledge' of it. Therefore use delegates. Just copied
    // the way we did delegates for the GridView...
    @IBAction func saveGameBtn(_ sender: Any) {
        
        // Let user know that game was successfully saved or Not
        // Use the ternery operator so that we can use just one 'alert'
        if let success = delegate?.preferencesVC(in: self) {
//            if success {
            let alert = UIAlertController(title: success ? "Success!" : "Failure", message: success ? "Game state was successfully saved." : "Unable to save game state", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
//            }
        }
    }
    
    
    
    
    // 'Delete preferences' button. Added alert to give user chance to 'opt out'
    @IBAction func deletePrefsBtn(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Preferences?", message: "Do you really want to delete your preferences?", preferredStyle: .alert)
        
        // .destructive to color 'Yes' in red...
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
            action in
            if let prefModel = self.modelGamePrefs {
                prefModel.deletePreferences()
            }
            // So after deleting the preferences return to the previous VC. Kind of hacky but it
            // bypasses saving the currently set values so that when game is restarted it will use the
            // default values.
            self.navigationController?.popToRootViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    @IBAction func dismissRequest(_ sender: Any) {
        
        // Normally it would be nice to alert user if the pref model unwrapping failed via an else
        // However this shouldn't fail. We initially checked them model availability in
        // viewDidLoad when populating the text fields and background colors. If it wasn't available
        // we sent user back to previous segue. If we've made it this far model is available
        // (but we still safely unwrap...)
        
        if let prefModel = modelGamePrefs {
            
            // Save the name in the text box. If empty don't change name in the model
            // So the text field is an optional and it can also be empty. If it's either, we don't want
            // to change the name. So unwrap and if unwrapped value isn't nil or empty, update name,
            // otherwise do nothing and model name will stay the same
            
            // 1. Is textBoxName nil?
            if let textBoxName = playerOneNameText.text {
                // 2. Not nil but is it NOT empty. If not empty then store value, otherwise do nothing
                if  !(textBoxName.isEmpty) {
                    prefModel.playerOneName = textBoxName
                }
            }
            
            if let textBoxName = playerTwoNameText.text {
                if  !(textBoxName.isEmpty) {
                    prefModel.playerTwoName = textBoxName
                }
            }
            
            if let textBoxName = gameNameText.text {
                if  !(textBoxName.isEmpty) {
                    prefModel.gameName = textBoxName
                }
            }
            
            //Update the background colors. We need to change to HSB via helper function as they are in UIColor
            if let buttonBackgroundColor = playerOneColorBtn.backgroundColor {
                prefModel.playerOneColor = uiColorToHSB(color: buttonBackgroundColor)
            }
            else {
                print("Button 1 background color not set. Unable to save to preferences")
            }
            
            if let buttonBackgroundColor = playerTwoColorBtn.backgroundColor {
                prefModel.playerTwoColor = uiColorToHSB(color: buttonBackgroundColor)
            }
            else {
                print("Button 2 background color not set. Unable to save to preferences")
            }
            
            //TODO: - Look at saving this in the model logic vice the pref model
            // UPdate our game grid size rows/colunns. This won't be reflected immediately as it's
            // only used when the view is be initialized
            prefModel.numRows = Int(rowsSlider.value)
            prefModel.numColumns = Int(columnsSlider.value)
            
            self.navigationController?.popToRootViewController(animated: true)
            // Initially set a nameChanged listener here but made more sense to set in the model where
            // the name actually changes.
            
            
        }
    }
}



extension PreferencesVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Have preferences setter reflect the current values stored in the model...
        
        if let prefModel = modelGamePrefs {
            playerOneNameText.text = prefModel.playerOneName
            playerTwoNameText.text = prefModel.playerTwoName
            gameNameText.text = prefModel.gameName
            rowsSlider.value = Float(prefModel.numRows)
            rowsText.text = Int(rowsSlider.value).description
            columnsSlider.value = Float(prefModel.numColumns)
            columnsText.text = Int(columnsSlider.value).description
            
            playerOneColorBtn.backgroundColor = hsbToUIColor(color: prefModel.playerOneColor)
            playerTwoColorBtn.backgroundColor = hsbToUIColor(color: prefModel.playerTwoColor)
        }
            // So if the preferences model isn't available this segue provides no value. Let the user know
            // via an alert and then when alert is dismissed return to previous VC.
        else {
            let alert = UIAlertController(title: "Preferences Unavailable", message: "Unable to set preferences (model is unavailable).", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: {
                action in
                // So this is the same code used for the dismiss ('Save preferences') button...
                self.navigationController?.popToRootViewController(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let colorPickerVC = segue.destination as? ColorPickerViewController {
            colorPickerVC.dataListener = self
        }
        // Get the button pressed via the tags that I set in storyboard. I used the same technique (mostly) for the calculator
        if let buttonPressed = sender as? UIButton {
            buttonTag = buttonPressed.tag
        }
    }
}


//MARK: - GameLogicModel Listener extension
extension PreferencesVC: ColorPickerChoiceListener {
    func userDidPick(color: UIColor) {
        
        switch buttonTag {
        case 0:
            playerOneColorBtn.backgroundColor = color
        case 1:
            playerTwoColorBtn.backgroundColor = color
        default:
            print("Unable to set background color")
        }
    }
}





