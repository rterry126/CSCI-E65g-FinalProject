////
////  ModelGameLogic.swift
////  Final_Project-rterry126
////
////  Created by Robert Terry on 10/11/18.
////  Copyright © 2018 Robert Terry. All rights reserved.
////

// Codable sources given in GameBoardVC


import Foundation


enum GameLogicError: String,Error {
    //    case gameOver = "The game is over."
    case outOfTurn = "It's not your turn to move."
    case invalidLocation = "You have clicked on a location that is out of bounds. Try again"
    case gridOccupied = "That square is already occupied. Try again"
}



class GameLogicModel: NSObject, Codable {
    
    static let instance: GameLogicModelProtocol = GameLogicModel()
    
    
    
    // Used to retrieve game board size. It has to be set internally vice from an external initializer.
    let defaults = UserDefaults.standard
    
    // So Codeabel will use the keys below to ONLY code these values
    // CaseIterable added to know what values to save to Firestore
    enum CodingKeys: String, CodingKey, CaseIterable {
        case _gameBoard
        case _moveCount
        case _whoseTurn
        // case - add power square used??
        //        case _gameState
    }
    
    // Set game state from persisted data IF it exists
    
    // Below changed 12.8.18 when modify Singleton. Not sure if correct...
    internal required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self) // defining our (keyed) container
        let gameBoardVal: [[GridState]] = try container.decode([[GridState]].self, forKey: ._gameBoard)
        let moveCountVal: Int = try container.decode(Int.self, forKey: ._moveCount) // extracting the data
        let whoseTurnVal: GridState = try container.decode(GridState.self, forKey: ._whoseTurn) // extracting the data
        //        let gameStateVal: GameState = try container.decode(GameState.self, forKey: ._gameState)
        
        // Now set the 4 items that we decided were important enough to save
        _gameBoard = gameBoardVal
        _moveCount = moveCountVal
        _whoseTurn = whoseTurnVal
        //        _gameState = gameStateVal
        
        //TODO: - Placeholder for _maxTurns to get it to compile. Working on non-persisted first
        _maxTurns = 10
        _amIPlayerOne = false
        _powerSquareUsed = false
        
        super.init()
    }
    
    
    // This is our default init IF game state isn't saved/persisted
    private override init() {
        
        //Board Size, retrieve from preferences
        // Returns 0 if key is non-existent
        // Sets to default value stored in enum if key is non existent
        var _numRows = defaults.integer(forKey: "\(PrefKeys.BoardSize.rows)")
        if _numRows == 0 {
            _numRows = PrefKeys.BoardSize.rows.rawValue
        }
        
        var _numColumns = defaults.integer(forKey: "\(PrefKeys.BoardSize.columns)")
        if _numColumns == 0 {
            _numColumns = PrefKeys.BoardSize.columns.rawValue
        }
        let gridSize = Double(_numRows * _numColumns)
        _maxTurns = Int.random(in: Int(gridSize * 0.5) ..< Int(gridSize * 0.75))
        //Set number of turns to even
        _maxTurns += (_maxTurns % 2 == 0) ? 0 : 1
        
        print("Max turns \(_maxTurns)")
        
        
        
        
        
        _gameBoard  = Array(repeating: Array(repeating: GridState.empty, count: _numColumns), count: _numRows)
        _moveCount = 0
        _whoseTurn = GridState.playerOne
        _amIPlayerOne = false
        _powerSquareUsed = false
        
        
        super.init()
    }
    
    
    
    private var _gameBoard = [[ GridState ]]()
    
    
    
    private func inBounds(untrustedInput: GridCoord) -> Bool {
        
        return untrustedInput <=> bounds
    }
    
    
    // State of location of game board
    // we're checking boundaries previous to this so don't need to check here
    private func locationState(at location: GridCoord) -> GridState {
        
        return  _gameBoard[location.row][location.column]
    }
    
    
    //MARK: - Game Logic
    
    private var _moveCount: Int {
        didSet {
            
            print("Model ==> Model: didSet(_moveCount) updated to \(_moveCount.description)")
            
            if oldValue == (_maxTurns - 1)  {
                
                Util.log("getting ready to initialize .gameOver state")
                StateMachine.state = .gameOver
            }
            else {
                
                // 12.1.18 This is ugly too, however if it's not the end of game then change to appropriate state...
                if StateMachine.state == .waitingForOpponentMove {
                    StateMachine.state = .waitingForUserMove
                }
                else {
                    StateMachine.state = .initialSnapshotOfGameBoard
                }
                
                //- 12.1.18 Eventually get rid of this and incorporate into simplier logic
                NotificationCenter.default.post(name: .turnCountIncreased, object: self)
                
                
                
            }
        }
    }
    
    // This is initially calculated regardless of whether or not player 1 or 2. That's just to keep
    // code cleaner. IF player 2 then we will update it via Firestore from the value calculated by
    // Player 1
    private var _maxTurns: Int // Random and set in init()
    private var _whoseTurn: GridState // Start with player one
    
    private var _amIPlayerOne: Bool
    private var _powerSquareUsed: Bool
    
    
}



//MARK: Extension Game Model Protocol
extension GameLogicModel: GameLogicModelProtocol {
    
    
    // Size of game board
    var bounds: GridCoord {
        return ( row: _gameBoard.count,  column: _gameBoard[0].count)
    }
    
    
    // Public implementation of locationState. Might modify in future
    func gridState(at location: GridCoord) -> GridState {
        return  _gameBoard[location.row][location.column]
    }
    
    
    
    // Or above like I previously thought on gameState. It will also change with successful move.
    // Logic - if it doesn't throw an error then it was successful. Observers will carry the rest??
    // Called by tap handler delegate
    func executeMove(playerID ID: GridState, moveCoordinates coordinates: GridCoord) throws  {
        /*
         Check if game is over
         2. Check if valid player
         3. Check if valid location, i.e. on the board
         4. Check if valid location, i.e. unoccupied.
         
         IF all above is OK
         1. Observer updates
         2. Move - Set observer to update
         3. Check end of game - set Observer to update
         
         
         */
        
        // Need to modify ID for power square, assign to local variable
        var localID = ID
        
        guard localID == _whoseTurn else { // probably not needed any more but keep in for now
            // Play out of turn
            throw GameLogicError.outOfTurn
        }
        guard  inBounds(untrustedInput: coordinates) else {
            throw GameLogicError.invalidLocation
        }
        let state = locationState(at: coordinates)
        guard state == GridState.empty else {
            
            print(gameBoard)
            // Determine if Power Square is available, previously used or already a Power Square
            if powerSquareUsed || state == GridState.playerOnePower || state == GridState.playerTwoPower {
                throw GameLogicError.gridOccupied
            }
                
                // else powerSquare NOT used
            else {
                switch localID {
                    
                case .playerOne:
                    localID = .playerOnePower
                case .playerTwo:
                    localID = .playerTwoPower
                default:
                    return
                }
                powerSquareUsed = true
                
            }
            
            print("\(localID.rawValue)")
            // Normal move
            // 11/24 so set a listener here to trigger cloud call, add move positions and ID to listener
            NotificationCenter.default.post(name: .executeMoveCalled, object: self, userInfo: ["playerID": localID, "coordinates": coordinates, "moveCount": moveCount ])
            return
        }
        
        
        
        // This is for GridState.empty, i.e. forfeited move
        // 11/24 so set a listener here to trigger cloud call, add move positions and ID to listener
        NotificationCenter.default.post(name: .executeMoveCalled, object: self, userInfo: ["playerID": localID, "coordinates": coordinates, "moveCount": moveCount ])
        
        
        
        
        print("Player who just moved was \(ID)")
        print("move at \(coordinates)")
        print("turns \(_moveCount)")
    }
    
    
    // Called by observer in GameViewController successfulBoardMove
    func incrementMoveCount() {
        print("Controller ==> Model: incrementMoveCount:")
        _moveCount += 1
    }
    
    
    func setTurn() {
        // Alternate turns based upon current turn
        _whoseTurn = (self._whoseTurn == .playerOne) ? GridState.playerTwo :  .playerOne
        
    }
    
    // Used if want to play another game. Just copied default init(); seems to be no way to trigger acutal init again so duplicating code. Drawback of singleton...
    func resetModel() {
        
        //Board Size, retrieve from preferences
        // Returns 0 if key is non-existent
        // Sets to default value stored in enum if key is non existent
        var _numRows = defaults.integer(forKey: "\(PrefKeys.BoardSize.rows)")
        if _numRows == 0 {
            _numRows = PrefKeys.BoardSize.rows.rawValue
        }
        
        var _numColumns = defaults.integer(forKey: "\(PrefKeys.BoardSize.columns)")
        if _numColumns == 0 {
            _numColumns = PrefKeys.BoardSize.columns.rawValue
        }
        
        _gameBoard  = Array(repeating: Array(repeating: GridState.empty, count: _numColumns), count: _numRows)
        _moveCount = 0
        _whoseTurn = GridState.playerOne
        _amIPlayerOne = false
        _powerSquareUsed = false
        
        Util.log("Model has been reset")
        print("printing game board after reseting")
        print(_gameBoard)
        
    }
    
    
    // Used to track certain display items, plus useful for saving/restoring game.
    var whoseTurn:GridState {
        get {
            return _whoseTurn
        }
    }
    
    
    var moveCount: Int {
        get {
            return _moveCount
        }
    }
    
    // Public gameBoard
    var gameBoard:[[GridState]] {
        get {
            return _gameBoard
        }
        set {
            _gameBoard = newValue
        }
    }
    
    // Set during election. Shouldn't change afterwards
    var amIPlayerOne: Bool {
        get {
            return _amIPlayerOne
        }
        set {
            _amIPlayerOne = newValue
            print("amIPlayerOne set via setter. Value is \(_amIPlayerOne)")
        }
    }
    
    var powerSquareUsed: Bool {
        get {
            return _powerSquareUsed
        }
        set {
            _powerSquareUsed = newValue
        }
    }
    
    var maxTurns: Int {
        get {
            return _maxTurns
        }
        set {
            _maxTurns = newValue
            print("max turns set via setter. Value is \(_maxTurns)")
        }
    }
    
}
