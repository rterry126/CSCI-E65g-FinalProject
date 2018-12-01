////
////  GameModel.swift
////  Assignment7-rterry126
////
////  Created by Robert Terry on 10/11/18.
////  Copyright © 2018 Robert Terry. All rights reserved.
////

// Codable sources given in GameBoardVC


import Foundation


enum GameLogicError: String,Error {
    case gameOver = "The game is over."
    case outOfTurn = "It's not your turn to move."
    case invalidLocation = "You have clicked on a location that is out of bounds. Try again"
    case gridOccupied = "That square is already occupied. Try again"
}



class GameLogicModel: NSObject, Codable {
    
    
    //TODO: Look at other instances which conform to more restrictive protocols, i.e. read only???
    
    // Used to retrieve game board size. It has to be set internally vice from an external initializer.
    let defaults = UserDefaults.standard
    
    // So Codeabel will use the keys below to ONLY code these values
    // CaseIterable added to know what values to save to Firestore
    enum CodingKeys: String, CodingKey, CaseIterable {
        case _gameBoard
        case _moveCount
        case _whoseTurn
//        case _gameState
    }
    
    // Set game state from persisted data IF it exists
    required init(from decoder: Decoder) throws {
        
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
        
        super.init()
    }
    
    
    // This is our default init IF game state isn't saved/persisted
    override init() {
        
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
        _maxTurns = Int.random(in: Int(gridSize * 0.5) ..< Int(gridSize * 0.65))
        // For now set to a constant until I upload to Firstore and download to player 2
        _maxTurns = 22
        print("Max turns \(_maxTurns)")
        
        
        
        
        _gameBoard  = Array(repeating: Array(repeating: GridState.empty, count: _numColumns), count: _numRows)
        _moveCount = 0
        _whoseTurn = GridState.playerOne
        
        // This will need to be replaced by state machine variable when restoring game, which will vary
        // depending on turn
//        _gameState = GameState.ongoing
        
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
            
            // Robert - if the listener isn't nil, as it's an optional, then call the appropriate listener (end of game or update player)
            
            //TODO:
            // Figure out how to have game end simultaneously on both sides...
            // Game will end when below is true, so...
            // 1) Update state variable 2) send the other player a message to update their state variable
            if oldValue == (_maxTurns)  {
                
                
                // So result is hard coded for now
                //TODO: future implementation let the game playing logic set this...
                
                // Commented out 12.1.18 - Superceded by state machine
//                _gameState = .completedDraw
                
                StateMachine.state = .gameOver
            }
            else {
                
                NotificationCenter.default.post(name: .turnCountIncreased, object: self)
                
            }
        }
    }
    
    // This is initially calculated regardless of whether or not player 1 or 2. That's just to keep
    // code cleaner. IF player 2 then we will update it via Firestore from the value calculated by
    // Player 1
    private var _maxTurns: Int // Random and set in init()
    private var _whoseTurn: GridState // Start with player one
    
    // When game starts the state is .ongoing, however if state changes notification should happen
    
    // Commented out 12.1.18 - variable decpreciated and superceded by state machine
    
//    private var _gameState: GameState {
//        didSet {
//            Util.log("Model ==> Model: didSet(_gameState) updated to \(_gameState)")
//            NotificationCenter.default.post(name: .gameState, object: self)
//
//        }
//    }
    
    private var _amIPlayerOne = false
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
    func executeMove(playerID ID: GridState, moveCoordinates coordinates: GridCoord) throws  {
        /*
         1. Check if game is over
         2. Check if valid player
         3. Check if valid location, i.e. on the board
         4. Check if valid location, i.e. unoccupied.
         
         IF all above is OK
         1. Observer updates
         2. Move - Set observer to update
         3. Check end of game - set Observer to update
         
         
         */
        // Commented out 12.1.18 If game is over then board is locked, plus this variable is depreciated
//        guard _gameState == .ongoing else {
//            // Game is over
//            throw GameLogicError.gameOver
//        }
        guard ID == _whoseTurn else {
            // Play out of turn
            throw GameLogicError.outOfTurn
        }
        guard  inBounds(untrustedInput: coordinates) else {
            throw GameLogicError.invalidLocation
        }
        guard locationState(at: coordinates) == GridState.empty else {
            throw GameLogicError.gridOccupied
        }
        
        // Normal case - valid move
        print(moveCount)
        
        
        StateMachine.state = .waitingForMoveConfirmation

        // 11/24 so set a listener here to trigger cloud call, add move positions and ID to listener
        NotificationCenter.default.post(name: .executeMoveCalled, object: self, userInfo: ["playerID": ID, "coordinates": coordinates, "moveCount": moveCount ])
        
        
        
        // 11/24 Since move is valid  we send the move to the cloud. ONLY after confirmation from the cloud
        // do we do updating below...
        
        
//        _gameBoard[coordinates.row][coordinates.column] = ID
//
//
//        // Notify controller that successful move was executed
//        NotificationCenter.default.post(name: .moveExecuted, object: self)

        
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
    
    //TODO: - Not curently used 11/30
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
//        _gameState = GameState.ongoing // Commented out 12.1.18
        
        Util.log("Model has been reset")
        
    }
    
    // Called by .executiveMove. Needs to know whose turn it is...
    //TODO: -
    // 11/25 Ideally we can eliminate this for network version as the device making the move will
    // be assigned P1 or P2. We're don't need to manually alternate the player in the model
    var whoseTurn:GridState {
        get {
            return _whoseTurn
        }
    }
    
//    var gameState: GameState {
//        get {
//            return _gameState
//        }
//        
//    }
    
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
