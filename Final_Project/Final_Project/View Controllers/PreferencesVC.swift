//
//  PreferencesVC.swift
//  Final_Project_rterry126
//
//  Created by Robert Terry on 10/20/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

// Sources - Return to main view using button. Dismiss doesn't work for nav controllers - https://stackoverflow.com/questions/47322379/swift-how-to-dismiss-all-of-view-controllers-to-go-back-to-root
// sources - Alert tutorial - https://learnappmaking.com/uialertcontroller-alerts-swift-how-to/
// Sources - styling labels - https://stackoverflow.com/questions/2311591/how-to-draw-border-around-a-uilabel
// Sources - ScrollView - https://www.youtube.com/watch?v=nfHBCQ3c4Mg
// Sources - Dismiss Keyboard via Return - https://stackoverflow.com/questions/24180954/how-to-hide-keyboard-in-swift-on-pressing-return-key
// Sources - Dismiss Keyboard via Tap gesture - https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
// Sources - Extensions review - https://docs.swift.org/swift-book/LanguageGuide/Extensions.html
// Sources - Adding bottom constraint to scroll view - https://stackoverflow.com/questions/43835290/ios-scroll-view-allows-scrolling-past-content
// Sources - UISwitch - https://stackoverflow.com/questions/48623771/loading-ison-or-isoff-for-a-uiswitch-using-swift-4


// Note - Preferences restyles to more resemble iOS settings. Ideally these would be in a table for this
// look, however I don't want to start all over with a new view controller, etc. This is quick way to
// get the 'look' and not break anything...

import UIKit

internal class PreferencesVC : UIViewController, UITextFieldDelegate {

    private let colorPickerVC = ColorPickerViewController()

    // GameBoardVC in instantiating the modelGamePref and passing this VC a reference. This is optional
    // as it can't be guaranteed that object was created or passed.
    var modelGamePrefs: GamePrefModelProtocol?

    //    // Delegate to save the model state. This VC has no knowledge of the model
    //    weak open var delegate: PreferencesVCDelegate?// default is nil. weak reference

    // Used to determine which button was pressed for color picker
    var buttonTag: Int = 0 //  Set to 0 (Player 1 button) so we can declare it here. Otherwise it needs to go into init() or viewDidLoad


    @IBOutlet weak var gameNameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var player1ColorLabel: UILabel!
    @IBOutlet weak var player2ColorLabel: UILabel!
    @IBOutlet weak var gridSizeLabel: UILabel!
    @IBOutlet weak var moveTimerLabel: UILabel!
    @IBOutlet weak var spacerLabel1: UILabel!
    @IBOutlet weak var spacerLabel2: UILabel!
    @IBOutlet weak var spacerLabel3: UILabel!
    @IBOutlet weak var spacerLabel4: UILabel!
    @IBOutlet weak var spacerLabel5: UILabel!
    @IBOutlet weak var spacerLabel6: UILabel!

    @IBOutlet weak var gameNameText: UITextField!
    @IBOutlet weak var myNameIsText: UITextField!

    @IBOutlet weak var playerOneColorBtn: UIButton!
    @IBOutlet weak var playerTwoColorBtn: UIButton!
    @IBOutlet weak var rowsSlider: UISlider!
    @IBOutlet weak var columnsSlider: UISlider!
    @IBOutlet weak var timerSlider: UISlider!
    @IBOutlet weak var localHistory: UISwitch!


    @IBOutlet weak var rowsText: UILabel!
    @IBOutlet weak var columnsText: UILabel!
    @IBOutlet weak var timerText: UILabel!



    // Update the number of rows label when the slider is moved
    @IBAction func rowsSliderSet(_ sender: Any) {
        rowsText.text = Int(rowsSlider.value).description
    }
    @IBAction func columnsSliderSet(_ sender: Any) {
        columnsText.text = Int(columnsSlider.value).description
    }
    @IBAction func timerSliderSet(_ sender: Any) {
        timerText.text = Int(timerSlider.value).description
    }

    // Need to reset Firestore. Could use proxy but this is easier and since we are using singletons...
    var sharedFirebaseProxy: FirebaseProxy = {
        Util.log("GameBoardVC ==> FirebaseProxy: get Singleton")
        return FirebaseProxy.instance
    }()


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

    @IBAction func deleteSavedGame(_ sender: Any) {

        do {
            Util.log("Delete game button pressed from Preferences")
            try Persistence.deleteSavedGame()
            Factory.displayAlert(target: self, message: "Game successfully deleted", title: "")
        }
        catch let e {
            Util.log("Deleting  game failed: \(e)")
            Factory.displayAlert(target: self, message: "Unable to delete (maybe no saved game?)", title: "")
        }
    }


    @IBAction func resetFirestore(_ sender: Any) {

        let alert = UIAlertController(title: "Reset Firestore?", message: "Do you really want to reset Firestore? You will need to retart app to redo the election.", preferredStyle: .alert)

        // .destructive to color 'Yes' in red...
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
            action in
            self.sharedFirebaseProxy.deleteCompletedGame() {}
            self.sharedFirebaseProxy.resetElection()

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
            if let textBoxName = myNameIsText.text {
                // 2. Not nil but is it NOT empty. If not empty then store value, otherwise do nothing
                if  !(textBoxName.isEmpty) {
                    prefModel.myNameIs = textBoxName
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

            // Update our game grid size rows/colunns. This won't be reflected immediately as it's
            // only used when the view is be initialized
            prefModel.numRows = Int(rowsSlider.value)
            prefModel.numColumns = Int(columnsSlider.value)
            prefModel.moveTime = Int(timerSlider.value)

            prefModel.localHistory = localHistory.isOn

            self.navigationController?.popToRootViewController(animated: true)
            // Listeners set in model for changes in names/colors. Less important since I don't
            // set individual player names here anymore...

        }
    }
}



extension PreferencesVC {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Used to dismiss keyboard on actual device via 'Return' key
        self.gameNameText.delegate = self
        self.myNameIsText.delegate = self

        // Dismiss editing text boxes via tap
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)


        // A better preferences page would use a table view; however since this VC was already in program it was easier to modify
        // to look like a table. Wrote quick extension to clean up code (included at end of file)
        gameNameLabel.border()
        nameLabel.border()
        player1ColorLabel.border()
        player2ColorLabel.border()
        gridSizeLabel.border()
        moveTimerLabel.border()
        spacerLabel1.border()
        spacerLabel2.border()
        spacerLabel3.border()
        spacerLabel4.border()
        spacerLabel5.border()
        spacerLabel6.border()




        // Have preferences setter reflect the current values stored in the model...

        if let prefModel = modelGamePrefs {

            myNameIsText.text = prefModel.myNameIs
            gameNameText.text = prefModel.gameName
            rowsSlider.value = Float(prefModel.numRows)
            rowsText.text = Int(rowsSlider.value).description
            columnsSlider.value = Float(prefModel.numColumns)
            columnsText.text = Int(columnsSlider.value).description
            timerSlider.value = Float(prefModel.moveTime)
            timerText.text = Int(timerSlider.value).description
            self.localHistory.setOn(prefModel.localHistory, animated: true)

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

    // Remove keyboard on 'Return'. Sources cited above
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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

// UILabel extension moved to SharedandHelpers. Going to modify to use with main game board
