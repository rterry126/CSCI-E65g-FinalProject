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
    
    
    // So Codabel will use the keys below to ONLY code these values
    enum CodingKeys: String, CodingKey {
        case _gameBoard
        case _totalTurns
        case _whoseTurn
        case _gameState
    }
    
    private var _gameBoard = [[ GridState ]]()
//    private weak var _dataListener: GameLogicModelListener?
    


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
    init(numOfRows rows: Int, numOfColumns columns: Int) {
        _gameBoard  = Array(repeating: Array(repeating: GridState.empty, count: columns), count: rows)
        _totalTurns = 0
        _whoseTurn = GridState.playerOne
        _gameState = GameState.ongoing
        super.init()
    }

    
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
                
                // Should the 'model' set the game state at end or should that be passed in?
                // So result is hard coded for now
                //TODO: future implementation
                _gameState = .completedDraw
            }
            else {
                
                NotificationCenter.default.post(name: .turnCountIncreased, object: self)
                //TODO: - Remove this old code once Notifications work
//                if let listener = _dataListener {
//                    print("Model ==> Controller: calling .updatePlayer listener:")
//                    print("Total turns was updated; not end of game.")
//                    listener.updatePlayer()
//                }
//                else {
//                    print("Warning: game model event occurred with no listener set.")
//                }
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
            print("Model ==> Model: didSet(_gameState) updated to \(_gameState)")
            NotificationCenter.default.post(name: .gameState, object: self)

            //TODO:- Remove below
//            if let listener = _dataListener {
//                listener.endOfGame()
//            }
//            else {
//                print("Warning: game model event occurred with no listener set.")
//            }
        }
    }
}



//MARK: Extension Game Model Protocol
extension GameLogicModel: GameLogicModelProtocol {
    
//    var dataListener: GameLogicModelListener? {
//        get {
//            return _dataListener
//        }
//        set {
//            print("Controller ==> Model: subscribing to model events")
//            // Example of tracking another likely source of errors
//            if newValue == nil {
//                print("Warning: listener was turned off.")
//            }
//            _dataListener = newValue
//        }
//    }
    
    
    // Size of game board
    var bounds: GridCoord {
        return ( row: _gameBoard.count,  column: _gameBoard[0].count)
    }
    
    
    // Public implementation of locationState. Might modify in future
    func gridState(at location: GridCoord) -> GridState {
        
        return  _gameBoard[location.row][location.column]
    }
    
    
    
    // Or above like I previously thought on gameState. It will also change with successful move.
    // Logic - if it doesn't throw an error then it was successful. Listeners will carry the rest??
    func executeMove(playerID ID: GridState, moveCoordinates coordinates: GridCoord) throws  {
        /*
         1. Check if game is over
         2. Check if valid player
         3. Check if valid location, i.e. on the board
         4. Check if valid location, i.e. unoccupied.
         
         IF all above is OK
         1. Listener updates
         2. Move - Set listener to update
         3. Check end of game - set listener to update
         
         
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
        
        // Normal case
        
        _gameBoard[coordinates.row][coordinates.column] = ID
        
        
        // Notify controller that successful move was executed
        NotificationCenter.default.post(name: .moveExecuted, object: self)

        
//        if let listener = _dataListener {
//            print("executeMove listener firing and calling .successfulBoardMove")
//            listener.successfulBoardMove()
//
//        }
//        else {
//            print("Warning: successful board move event occurred with no listener set.")
//        }
        
        print("Player who just moved was \(ID)")
        print("move at \(coordinates)")
        print("turns \(_totalTurns)")
    }
    
    
    // Called by listener in GameViewController successfulBoardMove
    func incrementTotalTurns() {
        print("Controller ==> Model: incrementTotalTurns:")
        _totalTurns += 1
    }
    
    
    func setTurn() {
        // Alternate turns based upon current turn
        _whoseTurn = (self._whoseTurn == .playerOne) ? GridState.playerTwo :  .playerOne
        
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
