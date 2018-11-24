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
        case _totalTurns
        case _whoseTurn
        case _gameState
    }
    
    // Set game state from persisted data IF it exists
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self) // defining our (keyed) container
        let gameBoardVal: [[GridState]] = try container.decode([[GridState]].self, forKey: ._gameBoard)
        let totalTurnsVal: Int = try container.decode(Int.self, forKey: ._totalTurns) // extracting the data
        let whoseTurnVal: GridState = try container.decode(GridState.self, forKey: ._whoseTurn) // extracting the data
        let gameStateVal: GameState = try container.decode(GameState.self, forKey: ._gameState)
        
        // Now set the 4 items that we decided were important enough to save
        _gameBoard = gameBoardVal
        _totalTurns = totalTurnsVal
        _whoseTurn = whoseTurnVal
        _gameState = gameStateVal
        
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
        
        _gameBoard  = Array(repeating: Array(repeating: GridState.empty, count: _numColumns), count: _numRows)
        _totalTurns = 0
        _whoseTurn = GridState.playerOne
        _gameState = GameState.ongoing
        
        super.init()
    }
    
    
    
    private var _gameBoard = [[ GridState ]]()
    
    
    // Public gameBoard
    var gameBoard:[[GridState]] {
        get {
            return _gameBoard
        }
    }
    
    
    
    private func inBounds(untrustedInput: GridCoord) -> Bool {
        
        return untrustedInput <=> bounds
    }
    
    
    // State of location of game board
    // we're checking boundaries previous to this so don't need to check here
    private func locationState(at location: GridCoord) -> GridState {
        
        return  _gameBoard[location.row][location.column]
    }
    
    
    //MARK: - Game Logic
    
    private var _totalTurns: Int {
        didSet {
            
            print("Model ==> Model: didSet(_totalTurns) updated to \(_totalTurns.description)")
            
            // Robert - if the listener isn't nil, as it's an optional, then call the appropriate listener (end of game or update player)
            
            //TODO:
            // Changed 11/1/18 - Discovered maxTurns was actually number of moves. Since each turn
            // should count as 2 moves, double _maxTurns. Refactor in the future to address correctly
            if oldValue == (_maxTurns) * 2 - 1 {
                
                
                // So result is hard coded for now
                //TODO: future implementation let the game playing logic set this...
                _gameState = .completedDraw
            }
            else {
                
                NotificationCenter.default.post(name: .turnCountIncreased, object: self)
                
            }
        }
    }
    // TODO: - this logic is faulty as it advances after each move, not 'turn'. so multiply by 2
    // or some other hack so that every player gets same number of turns
    private let _maxTurns = 5
    private var _whoseTurn: GridState // Start with player one
    
    // When game starts the state is .ongoing, however if state changes notification should happen
    private var _gameState: GameState {
        didSet {
            Util.log("Model ==> Model: didSet(_gameState) updated to \(_gameState)")
            NotificationCenter.default.post(name: .gameState, object: self)

        }
    }
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
        guard _gameState == .ongoing else {
            // Game is over
            throw GameLogicError.gameOver
        }
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
        
        // 11/24 so set a listener here to trigger cloud call, add move positions and ID to listener
        NotificationCenter.default.post(name: .executeMoveCalled, object: self)
        
        
        // 11/24 Since move is valid  we send to the cloud. ONLY after confirmation from the cloud
        // do we do updating below...
        _gameBoard[coordinates.row][coordinates.column] = ID
        
        
        // Notify controller that successful move was executed
        NotificationCenter.default.post(name: .moveExecuted, object: self)

        
        print("Player who just moved was \(ID)")
        print("move at \(coordinates)")
        print("turns \(_totalTurns)")
    }
    
    
    // Called by observer in GameViewController successfulBoardMove
    func incrementTotalTurns() {
        print("Controller ==> Model: incrementTotalTurns:")
        _totalTurns += 1
    }
    
    
    func setTurn() {
        // Alternate turns based upon current turn
        _whoseTurn = (self._whoseTurn == .playerOne) ? GridState.playerTwo :  .playerOne
        
    }
    
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
        _totalTurns = 0
        _whoseTurn = GridState.playerOne
        _gameState = GameState.ongoing
        
        Util.log("Model has been reset")
        
    }
    
    // Called by .executiveMove. Needs to know whose turn it is...
    var whoseTurn:GridState {
        get {
            return _whoseTurn
        }
    }
    
    var gameState: GameState {
        get {
            return _gameState
        }
        
    }
}
