//
//  GameViewController.swift
//  Assignment7-rterry126
//
//  Created by Robert Terry on 10/11/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

// Source - Alert with no handler - https://learnappmaking.com/uialertcontroller-alerts-swift-how-to/
// Source - devide width/height - https://stackoverflow.com/questions/24084941/how-to-get-device-width-and-height
// Source - sharing state (i.e. models) between VC - https://code.tutsplus.com/tutorials/the-right-way-to-share-state-between-swift-view-controllers--cms-28474

// Source - view controller initializer - https://www.hackingwithswift.com/example-code/language/fixing-class-viewcontroller-has-no-initializers

// So getting codable to work and save my model took a mashup of various sources and the class code
// Sources - Codable - https://hackernoon.com/everything-about-codable-in-swift-4-97d0e18a2999
//   https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types

// I couldn't pass the model to the function that encoded without this
// Sources - U -https://stackoverflow.com/questions/51058292/why-can-not-use-protocol-encodable-as-a-type-in-the-func
// Sources - More Codable - https://medium.com/swiftly-swift/swift-4-decodable-beyond-the-basics-990cc48b7375
// Sources - Codable - https://medium.com/tsengineering/swift-4-0-codable-decoding-subclasses-inherited-classes-heterogeneous-arrays-ee3e180eb556

// After getting the game state to save I wanted to then save after each turn. To ensure UX wasn't affected
// I used simple threading and put the saving function in a asyn background thread.
//https://medium.com/@abhimuralidharan/understanding-threads-in-ios-5b8d7ab16f09

// Sources - Resetting View Controller - stackoverflow.com/questions/33374272/swift-ios-set-a-new-root-view-controller

// Sources - How to pass #selector to function - https://stackoverflow.com/questions/37022780/pass-a-function-to-a-selector
// Sources - Audio - https://stackoverflow.com/questions/31126124/using-existing-system-sounds-in-ios-app-swift

import UIKit
import AVFoundation // Used to notify when timer/turn is about to expire via audio.


class GameBoardVC: UIViewController {
    @IBOutlet weak var textPlayer1: UILabel!
    @IBOutlet weak var textPlayer2: UILabel!
    @IBOutlet weak var textGameStatus: UILabel!
    @IBOutlet weak var textGameName: UILabel!
    
    
    // Taken from class code example. Create our custom view
    weak var gameView: GameBoardView?
    
    //MARK: - Properties
    
    // Source cited
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    // Size of game board. Set values in initializer below. Need to do this to pass the values to
    // the constructor of the custom view when that object is instantiated
    var numOfGridRows: Int
    var numOfGridColumns: Int
    
    
    var timerMove = Timer()
    var timerWarning = Timer() // Warning timer
    // TODO: - Put this timer interval into Preferences
    let timeToMakeMove = 5.0
    
    //Listeners and their selectors
    //Keep them all in one place and then initialize in viewDidLoad via Helper Function
    // 'listenerArray' is type alias
    
    var observerLogicModel: observerArray = [(.turnCountIncreased, #selector(updatePlayer)),
                                             (.gameState, #selector(endOfGame)),(.moveExecuted, #selector(successfulBoardMove))]
    
    var observerPreferencesModel: observerArray = [(.namesChanged, #selector(namesChanged)),
                                                   (.colorsChanged, #selector(colorsChanged))]
    
    //MARK: - Init()
    // Get saved grid size. Since we only fetch these values at init, we can change during game
    // without consequences via our preferences setter
    required init?(coder aDecoder: NSCoder) {
        //MARK: - Set size of game grid...
        self.numOfGridRows = modelGamePrefs.numRows
        self.numOfGridColumns = modelGamePrefs.numColumns
        super.init(coder: aDecoder)
    }
    
    
    
    //MARK:- Model Instance Created
   // Lazy because the rows/columns aren't necessarily available yet. Not sure if there is a better way...
//    lazy var modelGameLogic: GameLogicModelProtocol =
//        GameLogicModel(numOfRows: numOfGridRows, numOfColumns: numOfGridColumns)
    lazy var modelGameLogic: GameLogicModelProtocol = GameLogicModel.instance
    
    
    var modelGamePrefs: GamePrefModelProtocol = {
        print("Controller ==> Preferences Model: instantiate")
        return GamePrefModel()
    }()
    
    
    // Set a light gray for empty. Scale is 0.0 to 1.0 for these RGB values so divide by 255 to
    // normalize to this scale. Normally they are 0 to 255.
    var colorEmpty = UIColor.init(hue: 0.0, saturation: 0.0, brightness: 0.93, alpha: 1.0)
    
    
    //MARK: - Functions
    
    func displayAlert(message: String) {
        
        let alert = UIAlertController(title: "Game Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateUI() {
        
        // Update player colors
        switch modelGameLogic.whoseTurn {
            
        case .playerOne:
            textPlayer1.backgroundColor = hsbToUIColor(color: modelGamePrefs.playerOneColor)
            textPlayer2.backgroundColor = UIColor.white
            
        case .playerTwo:
            textPlayer1.backgroundColor = UIColor.white
            textPlayer2.backgroundColor = hsbToUIColor(color: modelGamePrefs.playerTwoColor)
            
        case .empty: //Switch needs to be exhaustive. This should never execute
            return
        }
        
        
        //Update player names
        textPlayer1.text = modelGamePrefs.playerOneName
        textPlayer2.text = modelGamePrefs.playerTwoName
        
        // Update game state text field.
        textGameStatus.text = modelGameLogic.gameState.rawValue
        
        // Update game name
        textGameName.text = modelGamePrefs.gameName
        
    }
}

// Used to save game state after each turn. Threaded to not block main game or affect UX
// After further reading, not sure I should be making a copy of the model prior to
// saving. Highly unlikel that it would be modified (move made) while this is reading model
// but proper form should I make a copy of it?

func saveGameState(_ modelGameLogic: GameLogicModelProtocol) {
    
    DispatchQueue.global(qos: .background).async {
        
        print("Saving after each turn \(modelGameLogic)")
        //Returns an optional
        if let data = modelGameLogic.toJSONData() {
        
            do {
                try Persistence.save(data)
            }
            catch let e {
                print("Sving failed: \(e)")
            }
        }
        else {
            print("Unable to save state after this turn.")
        }
    }
}

// A move timer and a 2 second (untile move expires) timer are created and returned via tuple.
// Purpose of timerWarning is to play audio alert so it's action is 'hardcoded' in the closure.
func createTimers(timeToMakeMove timeInterval: TimeInterval, target: Any, functionToRun selector: Selector ) -> (Timer,Timer) {
    
    let timerMove = Timer.scheduledTimer(timeInterval: timeInterval, target: target, selector: selector, userInfo: nil, repeats: false)
    
    let timerWarning = Timer.scheduledTimer(withTimeInterval: timeInterval - 2.0, repeats: false) { timer2 in
        AudioServicesPlayAlertSound(SystemSoundID(1103))
    }
    
    // Supposedly if timing isn't critical this is energy efficient.
    timerMove.tolerance = 0.4
    timerWarning.tolerance = 0.2
    
    return (timerMove, timerWarning)
}




//MARK: - GameLogicModel Observer extension
extension GameBoardVC: GameLogicModelObserver {
    
    @objc func successfulBoardMove() {
        
        
        // A couple of possibilities here:
        // 1. Player makes move within alloted time AND before warning. Invalidate BOTH timers since
        // they aren't needed.
        // 2. Play makes move within alloted time but NOT before warning sound. timerWarning is already
        // invalid (it doesn't repeat) but need to invalidate timerMove.
        // 3. Player does NOT make move in time. This functions is triggered by timerMove. Both
        // timers are invalid so code below does nothing.
        
        timerMove.invalidate()
        timerWarning.invalidate()
        
        // Model informs controller successful move has occurred then controller
        // 1) tells model to change player turn 2) Update turn count 3) updates the view via updatePlayer()
        print("Model ==> Controller: successful move executed:")
        
        // First increment count. If moves are remaining then a observer to update the player will be called
        // Otherwise, if last move, a observer to execute end of game routines will be called
       
        // Set timers for next move. If end of game then these will be invalidated in endOfGame. Could
        // complicate this by having endOfGame return a bool, move this below .incrementTotalTurns
        // and put in if/else. OR just have endOfGame invalidate. Kind of sloppy but keeps code
        // cleaner
        
        (timerMove, timerWarning) = createTimers(timeToMakeMove: timeToMakeMove, target: self, functionToRun: #selector(timerFired))
        
        // First increment count. If moves are remaining then a listener to update the player will be called
        // Otherwise, if last move, a listener to execute end of game routines will be called
        modelGameLogic.incrementTotalTurns()
        
        // .incrementTotalTurns has two observers set 1) if it's end of game, then that function is run
        // 2) if not end of game then updatePlayer is run
        
        
    }
    
    @objc func endOfGame() {
        // Called when num of turns in model is increased to max turns.
        
        // Disable inputs
        gameView?.isUserInteractionEnabled = false
        
        // Kill/delete the move timers as they are no longer needed.
        // Could possibly delete these if 'in game' timer creation was moved from successfulBoardMove
        // but how it's coded now is simple and it works.
        timerMove.invalidate()
        timerWarning.invalidate()
        
        updateUI()
        
        // Delete saved game, otherwise we are in a loop that just fetches saved game
        do {
            print("End of game. Deleting saved game state \(modelGameLogic)")
            
            try Persistence.deleteSavedGame()
        }
        catch let e {
            print("Deleting previous game failed: \(e)")
        }
        
        
        // Play again?
        // So as I understand the code that is the action, we are resetting the view controller,
        // which causes it to reload. This is what I want, as viewDidLoad will run again and
        // the default initialization will be run.
        
        // commented out on 11/10. Initializing new game code has been modifed due to singleton/Firebase
        
//        let alert = UIAlertController(title: "Shall we play a game?", message: "", preferredStyle: .alert)
//
//        if let gameBoardVC =  window?.rootViewController?.children[0] as? GameBoardVC {
//            //            gameBoardVC.modelGamePrefs = GamePrefModel()
//            //        }
//        // .destructive to color 'Yes' in red...
//        alert.addAction(UIAlertAction(title: "Yes", style: .default , handler: {
//            action in
//            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
//            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "GameBoardVC") as! GameBoardVC
//            let navigationController = UINavigationController(rootViewController: nextViewController)
//            let appdelegate = UIApplication.shared.delegate as! AppDelegate
//            appdelegate.window!.rootViewController = navigationController
//
//        }))
//        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
//        self.present(alert, animated: true)
        
        
    }
    
    
    // Called by .incrementTotalTurns. It's not the end of game so call update player logic
    @objc func updatePlayer() {
        
        // Simple function that alternates turns and returns whose turn it is
        modelGameLogic.setTurn()
        
        // Save game state in background and asynchronously
        saveGameState(modelGameLogic)
        updateUI()
    }
}



//MARK: - GamePrefModel Observer extension
extension GameBoardVC: GamePrefModelObserver {
    
    @objc func namesChanged() {
        updateUI()
    }
    
    @objc func colorsChanged() {
        // So in the game view, the 'board' is normally only set to draw new squares, setNeedsDisplay(rect)
        // vice the whole board. However when colors are changed, this leaves the old and new colors
        // on the board. Call reloadAllSquares (which is really wrapper for setNeedsDisplay() ) so that the whole board will be redrawn with a new color
        
        gameView?.reloadAllSquares()
        updateUI()
    }
}

extension GameBoardVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: - Not sure of the sequencing here. Does this write over default init if below exists?
        // OR if it doesn't exist below is default init() triggered?
        // Try to restore saved game state
        
        modelGameLogic.initializeGameBoard(rows: numOfGridRows, cols: numOfGridColumns)

        // Below commented on 11/9 when implementing singleton pattern
//        do {
//            let restoredObject = try Persistence.restore()
//            guard let mdo = restoredObject as? GameLogicModelProtocol else {
//                print("Got the wrong type: \(type(of: restoredObject)), giving up on restoring")
//                return
//            }
//            // Let's try setting a reference to our restored state
//            modelGameLogic = mdo
//
//            print("Success: in restoring game state")
//        }
//        catch let e {
//            print("Restore failed: \(e).")
//
//            // So evidently if it fails here to restore saved model it uses the default init()
//            // defined in the model. Code below isn't needed (saved as a reminder as to flow of init)
//
////            var modelGameLogic: GameLogicModelProtocol =
////                GameLogicModel(numOfRows: numOfGridRows, numOfColumns: numOfGridColumns)
//        }

        
        
        
        // Initialize the game state label
        textGameStatus.text = modelGameLogic.gameState.rawValue
        
        // A height of 75% of the screen size gives us enough room at the bottm for names, controls, etc.
        let gameView = GameBoardView() // Object palette
        
        gameView.frame = CGRect(x: 0, y: 94, width: screenWidth, height: screenHeight * 0.75 ) // Autolayout
        print("About to add gameView")
        view.addSubview(gameView) // View hierarchy
        print("Done adding gameView")
        
        self.gameView = gameView
        
        gameView.dataSource = self
        gameView.delegate = self
        
        // Pass our observers and selectors to our helper function to create the observers
        createObserver(observer: self, listeners: observerLogicModel)
        createObserver(observer: self, listeners: observerPreferencesModel)

        
        // Initialize grid in view
        gameView.createGrid()
        
        // Now redraw the view
        
        //TODO: - This is not well thought out. Fix in next iteration.
        
        // So when the game is restored, the underlying logic is correct, i.e. which squares are
        // occupied and by whom. However the custom view doens't reflect this, so we have an 'empty'
        // viewable board overlying an occupied board. This forces the view to go over each square
        // and determine it's color. Last minute to get the restore working; where it fits in MVC
        // not fully thought out
        
        //commented 11/9
//        for y in 0..<numOfGridRows {
//            for x in 0..<numOfGridColumns {
//                gameView.changeGridState(x: x, y: y)
//            }
//        }
//
//        // Now that I've told it above what colors belong to each square set a 'needs update'
//        gameView.reloadAllSquares()
        
        // Initialize state of board - colors, game status, etc
        updateUI()
        
        // TODO: - This is initial timer creation. Should be put in a 'Start Game' function at some point.
        (timerMove, timerWarning) = createTimers(timeToMakeMove: timeToMakeMove, target: self, functionToRun: #selector(timerFired))

    }
    
    
    // Pass reference to modelGamePrefs to PreferencesVC (injection dependancy?). Evidently another approach
    // for a single instance is the singleton pattern, which from my basic reading is highly discouraged.
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let preferencesVC = segue.destination as? PreferencesVC {
            preferencesVC.modelGamePrefs = modelGamePrefs
            
            // Add our delegate here 
            preferencesVC.delegate = self
        }
    }
    
    // This just serves as a function to pass in .successfulBoardMove to create the timers.
    // There are 2 separate locatins where the timers are created: 1) When the game first starts
    // 2) After each move (they are non-repeating timers). Instead of hard coding the selector or
    // what action I wanted to happen upon expiration, I just pass in this function.
    
    // @objc required because this is passed to #selector
    @objc func timerFired() {
        print("played times up tone")
        self.successfulBoardMove()
        
    }
}
