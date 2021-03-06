//
//  GameViewController.swift
//  Final_Project-rterry126
//
//  Created by Robert Terry on 10/11/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

// Source - Alert with no handler - https://learnappmaking.com/uialertcontroller-alerts-swift-how-to/
// Source - @objc devide width/height - https://stackoverflow.com/questions/24084941/how-to-get-device-width-and-height
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
// Sources - passing userinfo via notifications - https://stackoverflow.com/questions/24892454/how-to-access-a-dictionary-passed-via-nsnotification-using-swift

// Source - display countdown timer - https://teamtreehouse.com/community/swift-countdown-timer-of-60-seconds
// Source - Sound IDs - https://github.com/TUNER88/iOSSystemSoundsLibrary
// Source - color conversion for textbox boarder - https://stackoverflow.com/questions/38460327/how-set-swift-3-uitextfield-border-color

import UIKit
import Firebase
import AVFoundation


class GameBoardVC: UIViewController {
    @IBOutlet weak var textPlayer1: UILabel!
    @IBOutlet weak var textPlayer2: UILabel!
    @IBOutlet weak var textGameStatus: UILabel!
    @IBOutlet weak var textGameName: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newGameButtonOutlet: UIButton!
    @IBOutlet weak var readyPlayerOne: UIImageView!
    @IBOutlet weak var readyPlayerTwo: UIImageView!
    @IBOutlet weak var textTimer: UILabel! // Initially hidden via storyboard...
    @IBOutlet weak var newGameBtnText: UIButton!
    
    
    @IBAction func newGameButton(_ sender: UIButton) {
        
        // New game button pressed. Change state
        
        updateUI()
        
        sharedFirebaseProxy.startGame {
            StateMachine.state = .waitingForUserMove
        }
        
    }
    
    
    
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
    
    // TODO: - See if I can clean this up into 1 variable; maybe us in/out var
    
    var timeToMakeMove: Double  // Timer interval which triggers move forfeiture
    var timeDisplay: Int // variable that is modified and used to display time remaining. Initially set from above
    
    var timerCountDown = Timer() // Display countdown timer
    
    // Set a light gray for empty. Scale is 0.0 to 1.0 for these RGB values so divide by 255 to
    // normalize to this scale. Normally they are 0 to 255.
    var colorEmpty = UIColor.init(hue: 0.0, saturation: 0.0, brightness: 0.93, alpha: 1.0)
    
    
    
    //Listeners and their selectors
    //Keep them all in one place and then initialize in viewDidLoad via Helper Function
    // 'observerArray' is type alias
    
    var observerLogicModel: observerArray = [(.turnCountIncreased, #selector(updatePlayer)),
                                             /* (.gameState, #selector(endOfGame)), */
        /*(.moveExecuted, #selector(successfulBoardMove))*/]
    
    var observerPreferencesModel: observerArray = [(.namesChanged, #selector(namesChanged)),
                                                   (.colorsChanged, #selector(colorsChanged))]
    
    var observerStateMachine: observerArray = [(.stateChanged, #selector(updateGameStateLabel)),(.electPlayerOne, #selector(stateElectPlayerOne)),(.initializing, #selector(stateInitializing)), (.waitingForPlayer2, #selector(stateWaitingToStartGame)),
                                               (.waitingForGameStart, #selector(stateWaitingToStartGame)), (.readyForGame, #selector(stateReadyForGame)),(.waitingForUserMove, #selector(stateWaitingForUserMove)),
                                               (.waitingForUserMove, #selector(startTimer)), (.executeMoveCalled, #selector(stateWaitingForMoveConfirmation)),
                                               (.moveStoredFirestore, #selector(updateGameView)),(.moveStoredFirestore, #selector(successfulBoardMove)),
                                               (.initialSnapshotOfGameBoard , #selector(stateWaitingForOpponent)),(.gameOver, #selector(stateEndOfGame))]
    
    
    //MARK: - Init()
    // Get saved grid size. Since we only fetch these values at init, we can change during game
    // without consequences via our preferences setter
    required init?(coder aDecoder: NSCoder) {
        
        
        //MARK: - Set size of game grid...
        self.numOfGridRows = modelGamePrefs.numRows
        self.numOfGridColumns = modelGamePrefs.numColumns
        
        self.timeToMakeMove = Double(modelGamePrefs.moveTime)
        self.timeDisplay = Int(timeToMakeMove)
        
        super.init(coder: aDecoder)
    }
    
    
    
    //MARK:- Instances Created - Singletons
    var modelGameLogic: GameLogicModelProtocol = GameLogicModel.instance
    
    var modelGamePrefs: GamePrefModelProtocol = {
        Util.log("GameBoardVC ==> Preferences Model: instantiate")
        return GamePrefModel.instance
    }()
    
    var sharedFirebaseProxy: FirebaseProxy = {
        Util.log("GameBoardVC ==> FirebaseProxy: get Singleton")
        return FirebaseProxy.instance
    }()
    
    
    
    
    //MARK: - Functions
    
    func updateUI() {
        
        // Update player colors
        // Boarder stroke taken (mostly) from preferences. Additioal sources cited above.
        // Use UILabel extension (SharedandHelpers), override defaults to add stroke
        
        let colorP1 = hsbToUIColor(color: modelGamePrefs.playerOneColor).cgColor
        let colorP2 = hsbToUIColor(color: modelGamePrefs.playerTwoColor).cgColor
        
        switch modelGameLogic.whoseTurn {
            
        case .playerOne:
            textPlayer1.border(2.5, colorP1)
            textPlayer2.border(0.0)
            
            
            // Only display dot when it's player's turn
            readyPlayerOne.isHidden = modelGameLogic.amIPlayerOne ? false : true
            readyPlayerTwo.isHidden = true
            
            
        case .playerTwo:
            textPlayer2.border(2.5, colorP2)
            textPlayer1.border(0.0)
            
            readyPlayerTwo.isHidden = !modelGameLogic.amIPlayerOne ? false : true
            readyPlayerOne.isHidden = true
            
        default: //Switch needs to be exhaustive. This should never execute.
            return
        }
        
        
        //Update player names and game name
        textPlayer1.text = modelGamePrefs.playerOneName
        textPlayer2.text = modelGamePrefs.playerTwoName
        textGameName.text = modelGamePrefs.gameName
        
        
    }
}

// Used to save game state after each turn. Threaded to not block main game or affect UX
func saveGameState(_ modelGameLogic: GameLogicModelProtocol) {
    
    DispatchQueue.global(qos: .background).async {
        
        Util.log("Saving game after each turn \(modelGameLogic)")
        //Returns an optional
        if let data = modelGameLogic.toJSONData() {
            
            do {
                try Persistence.save(data)
            }
            catch let e {
                Util.log("Saving game failed: \(e)")
            }
        }
        else {
            Util.log("Unable to save game after this turn.")
        }
    }
}




extension GameBoardVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pass our state observers and selectors to our factory function to create the observers
        Factory.createObserver(observer: self, listeners: observerStateMachine)
        
        StateMachine.state = .electPlayerOne
        
        
        // Setup Custom View, i.e. game board
        // A height of 75% of the screen size gives us enough room at the bottm for names, controls, etc.
        let gameView = GameBoardView()
        
        gameView.frame = CGRect(x: 0, y: 94, width: screenWidth, height: screenHeight * 0.75 )
        
        view.addSubview(gameView) // View hierarchy
        Util.log("Added custom view - gameView")
        
        self.gameView = gameView
        
        gameView.dataSource = self
        gameView.delegate = self
        
        // Initialize grid in view
        gameView.createGrid()
        
        
        
        
        // Pass our observers and selectors to our factory function to create the observers
        Factory.createObserver(observer: self, listeners: observerLogicModel)
        Factory.createObserver(observer: self, listeners: observerPreferencesModel)
        
        
        // Initialize state of board - colors, game status, etc
        updateUI()
        
    } // End viewDidLoad
    
    
    
    
    
    // Segue to the Preferences view....
    // Pass reference to modelGamePrefs to PreferencesVC (injection dependancy?).
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let preferencesVC = segue.destination as? PreferencesVC {
            preferencesVC.modelGamePrefs = modelGamePrefs
            
            // Add our delegate here 
            //preferencesVC.delegate = self  // Commented out 12.11.18 due to cleaning up Preferences page. Don't need button to save
        }
    }
    
    
    
    // Time fired, turn is forfeited. Need to bypass most of move logic, but still advance the game state.
    
    // @objc required because this is passed to #selector
    @objc func timerTurnForfeitedFired() {
        Util.log("Move Timer Fired, turn forfeited")
        
        // Post a notificaton just identical to one in .executeMove in Model EXCEPT we won't pass
        // coordinates, empty move to change the state to waiting for move confirmation.
        // we need some type of move posted in Firestore to change state of both users.
        NotificationCenter.default.post(name: .executeMoveCalled, object: self, userInfo: ["playerID": modelGameLogic.whoseTurn, "moveCount": modelGameLogic.moveCount ])
        
        
        
    }
    
    //TODO: - Figure out best place to place this
    
    @objc func updateGameView(_ notification :Notification) {
        
        Util.log("update Game View called via listener")
        
        // 1) Get coordinates, only update view if we have coordinates, otherwise forfeited move so skip
        if let location = notification.userInfo?["coordinates"] as? (row:Int, column:Int) {
            
            
            guard let playerID = notification.userInfo?["playerID"] as? GridState else {
                Factory.displayAlert(target: self, message: "Error retrieving or unwrapping playerID", title: "Move Confirmation")
                fatalError("Cannot retrieve playerID")
                
            }
            
            // Reminder - this is only running IF there are coordinates, i.e. IF move wasn't forfeited
            
            // 2) Update the Logic Model Array
            modelGameLogic.gameBoard[location.row][location.column] = playerID
            
            // 3) Update the View Grid
            gameView?.changeGridState(x: location.column, y: location.row)
            
            // 4) Still need to update the game state, via listenr that triggers this function
            
        }
        
        // Otherwise do NOT update board view or game model, as move was FORFEITED (no coordinates passed)
        
    }
    
    
    @objc func startTimer() {
        
        timerCountDown = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(displayTimer), userInfo: nil, repeats: true)
        
        // Supposedly if timing isn't critical this is energy efficient.
        
        timerCountDown.tolerance = 0.1
    }
    
    
    
    @objc func displayTimer () {
        // Since this is called every 1 seconds, we need a persistent variable to 'remember' where in the countdown we are:
        
        // This is here so visual timer is in sync
        textTimer.isHidden = false // initialized as hidden via storyboard
        
        
        // timeDisplay is modified and we need it to persist.  It's a global variable.
        
        textTimer.text = "\(timeFormatted(timeDisplay))" // Helper fuction to format
        
        if timeDisplay == 2 { // play warning...
            AudioServicesPlayAlertSound(SystemSoundID(1103))
        }
        
        if timeDisplay != 0 {
            timeDisplay -= 1
        }
        else {
            textTimer.isHidden = true
            timerCountDown.invalidate()
            //TODO: this is slopppy I think
            timeDisplay = Int(timeToMakeMove) // Reset for next move....
            timerTurnForfeitedFired()
        }
    }
    
    
    // Used when game is resumed. Logic model is correct but view doesn't reflect it.
    func redrawView() {
        
        for y in 0..<numOfGridRows {
            for x in 0..<numOfGridColumns {
                gameView?.changeGridState(x: x, y: y)
            }
        }
        
        // Now that I've told it above what colors belong to each square set a 'needs update'
        gameView?.reloadAllSquares()
        
    }
    
}

//MARK: - GameLogicModel Observer extension
extension GameBoardVC: GameLogicModelObserver {
    
    
    @objc func successfulBoardMove() {
        
        
        // A couple of possibilities here:
        // 1. Player makes move within alloted time. Invalidate timer
        // 2. Player does NOT make move in time. This triggers (via timer) func timerExpired and it handles the logic
        
        
        textTimer.isHidden = true
        timeDisplay = Int(timeToMakeMove) // Reset for next move....
        textTimer.text = "\(timeFormatted(timeDisplay))" // label has reset time value for next time
        // otherwise it would have old/previous value before it's updated.
        
        
        // Model informs controller successful move has occurred then controller
        // 1) tells model to change player turn 2) Update turn count 3) updates the view via updatePlayer()
        Util.log("GameModel ==> GameBoardVC: successful move executed:")
        
        // First increment count. If moves are remaining then a observer to update the player will be called
        // Otherwise, if last move, a observer to execute end of game routines will be called
        
        // Set timer for next move. If end of game then these will be invalidated in endOfGame.
        
        // First increment count. If moves are remaining then a listener to update the player will be called
        // Otherwise, if last move, a listener to execute end of game routines will be called
        modelGameLogic.incrementMoveCount()
        
        // .incrementMoveCount has two observers set 1) if it's end of game, then that function is run
        // 2) if not end of game then updatePlayer is run
        
    }
    
    
    
    // Called by .incrementMoveCount. It's not the end of game so call update player logic
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


