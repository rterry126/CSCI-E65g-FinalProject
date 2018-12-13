//
//  ModelGamePref.swift
//  Final_Project_rterry126
//
//  Created by Robert Terry on 10/20/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
// Sources - nil coalescing operator for retrieving user defaults - https://www.hackingwithswift.com/read/12/2/reading-and-writing-basics-userdefaults
// Sources - UserDefaults - https://www.hackingwithswift.com/read/12/2/reading-and-writing-basics-userdefaults
// Sources - Dependency Injection - https://code.tutsplus.com/tutorials/the-right-way-to-share-state-between-swift-view-controllers--cms-28474
import Foundation


class GamePrefModel {
    
    let defaults = UserDefaults.standard
    
    // Singleton creation
    
    static let instance: GamePrefModelProtocol = GamePrefModel()
    
    
    // Initialize our player names and colors by either retrieving saved values OR initializing to our
    // default values here instead of when the private variable is declared
    //MARK: - Set stored or default preferences
    private init() {
        
        // Returns 0 if key is non-existent
        // Set to default value stored in enum if key is non existent. 
        _moveTime = defaults.integer(forKey: "\(PrefKeys.GameTime.moveTime)")
        if _moveTime == 0 {
            _moveTime = PrefKeys.GameTime.moveTime.rawValue
        }
        
        _myNameIs = defaults.string(forKey: "\(PrefKeys.MiscPrefs.myNameIs)") ?? PrefKeys.MiscPrefs.myNameIs.rawValue
        
        //MARK: - Set Player names
        //Game Name
        // Player One name
        // Either set the saved value OR if that is nil retrieve the default value from enum
        _playerOneName = defaults.string(forKey: "\(PrefKeys.Players.playerOne)") ?? PrefKeys.Players.playerOne.rawValue
        
        // Player Two name
        _playerTwoName = defaults.string(forKey: "\(PrefKeys.Players.playerTwo)") ?? PrefKeys.Players.playerTwo.rawValue
        
        //Game Name
        _gameName = defaults.string(forKey: "\(PrefKeys.MiscPrefs.gameName)") ?? PrefKeys.MiscPrefs.gameName.rawValue
        
        
        //MARK: - Set Player Colors
        // savedColor is Array<Any> if it exists. Typecast as [Double] and then convert to HSBColor
        // if it doesn't exist (nil), provide default color value
        let savedColor1 = defaults.array(forKey: "\(PrefKeys.Colors.playerOneColor)")
        _playerOneColor = arrayToTuple(savedColor1 as? [Double] ?? PrefKeys.Colors.playerOneColor.rawValue)
        
        // same as above
        let savedColor2 = defaults.array(forKey: "\(PrefKeys.Colors.playerTwoColor)")
        _playerTwoColor = arrayToTuple(savedColor2 as? [Double] ?? PrefKeys.Colors.playerTwoColor.rawValue)
        
        
        //Board Size
        // So this ins't an optional like the others but returns 0 if key is non-existent
        // Set to default value stored in enum if key is non existent
        _numRows = defaults.integer(forKey: "\(PrefKeys.BoardSize.rows)")
        if _numRows == 0 {
            _numRows = PrefKeys.BoardSize.rows.rawValue
        }
        
        _numColumns = defaults.integer(forKey: "\(PrefKeys.BoardSize.columns)")
        if _numColumns == 0 {
            _numColumns = PrefKeys.BoardSize.columns.rawValue
        }
        
    }
    
    
    
    //MARK: Private variables
    private var _moveTime: Int {
        
        didSet {
            print("Model ==> Model: didSet(__movetime) updated to \(_moveTime)")
            // Persist time anytime it is changed
            defaults.set("\(_moveTime)", forKey: "\(PrefKeys.GameTime.moveTime)")
            
          
        }
    }
    
    private var _myNameIs: String {
        
        didSet {
            print("Model ==> Model: didSet(_myNameIs) updated to \(_myNameIs)")
            
            // Persist name anytime it is changed
            defaults.set("\(_myNameIs)", forKey: "\(PrefKeys.MiscPrefs.myNameIs)")
            
            // So we will use the same observer as for the names... No reason to make a separate one.
            
//            NotificationCenter.default.post(name: .namesChanged, object: self)
            
        }
        
        
    }
    
    private var _playerOneName: String {
        didSet {
            print("Model ==> Model: didSet(_playerOneName) updated to \(_playerOneName)")
            // Persist name anytime it is changed
            defaults.set("\(_playerOneName)", forKey: "\(PrefKeys.Players.playerOne)")
            
            NotificationCenter.default.post(name: .namesChanged, object: self)
            
        }
    }
    
    private var _playerTwoName: String {
        didSet {
            print("Model ==> Model: didSet(_playerTwoName) updated to \(_playerTwoName)")
            
            // Persist name anytime it is changed
            defaults.set("\(_playerTwoName)", forKey: "\(PrefKeys.Players.playerTwo)")
            
            NotificationCenter.default.post(name: .namesChanged, object: self)

        }
    }
    
    // See comments by type alias declaration regarding why this is structured as it is.
    // Explicity do the normalization (divide by 255.0) so that we can see the initial HSB values
    // Default color is cyan
    private var _playerOneColor:HSBColor {
        didSet {
            print("Model ==> Model: didSet(_playerOneColor) updated to \(_playerOneColor)")
            
            // Persist color anytime it is changed
            defaults.set(tupleToArray(_playerOneColor) , forKey: "\(PrefKeys.Colors.playerOneColor)")
            
            NotificationCenter.default.post(name: .colorsChanged, object: self)
            
        }
    }
    
    private var _playerTwoColor:HSBColor  { //Default color is a green
        didSet {
            print("Model ==> Model: didSet(_playerTwoColor) updated to \(_playerTwoColor)")
            
            // Persist color anytime it is changed
            defaults.set(tupleToArray(_playerTwoColor), forKey: "\(PrefKeys.Colors.playerTwoColor)")
            
            NotificationCenter.default.post(name: .colorsChanged, object: self)

        }
    }
    
    private var _gameName: String {
        didSet {
            print("Model ==> Model: didSet(_gameName) updated to \(_gameName)")
            
            // Persist name anytime it is changed
            defaults.set("\(_gameName)", forKey: "\(PrefKeys.MiscPrefs.gameName)")
            
            // So we will use the same observer as for the names... No reason to make a separate one.
            
            NotificationCenter.default.post(name: .namesChanged, object: self)

        }
    }
    
    private var _numRows: Int {
        didSet {
            print("Model ==> Model: didSet(_numRows) updated to \(_numRows)")
            
            // Persist name anytime it is changed
            defaults.set("\(_numRows)", forKey: "\(PrefKeys.BoardSize.rows)")
            
            // No need for a listener as we aren't changing this mid game
        }
    }
    
    private var _numColumns: Int {
        didSet {
            print("Model ==> Model: didSet(_numColumns) updated to \(_numColumns)")
            
            // Persist name anytime it is changed
            defaults.set("\(_numColumns)", forKey: "\(PrefKeys.BoardSize.columns)")
            
            // No need for a listener as we aren't changing this mid game
        }
    }
    
}

//MARK: Extension - Game Model Protocol
extension GamePrefModel: GamePrefModelProtocol {
    
    var moveTime: Int {
        get {
            return _moveTime
        }
        set {
            _moveTime = newValue
        }
    }
    
    var myNameIs: String {
        get {
            return _myNameIs
        }
        set {
            _myNameIs = newValue
        }
    }
    
    var playerOneName: String {
        get {
            return _playerOneName
        }
        set {
            print("setting _playerOneName via newValue")
            _playerOneName = newValue
        }
    }
    
    var playerTwoName: String {
        get {
            return _playerTwoName
        }
        set {
            _playerTwoName = newValue
        }
    }
    
    var playerOneColor: HSBColor {
        get {
            return _playerOneColor
        }
        set {
            _playerOneColor = newValue
        }
    }
    
    var playerTwoColor: HSBColor {
        get {
            return _playerTwoColor
        }
        set {
            _playerTwoColor = newValue
        }
    }
    
    var gameName: String {
        get {
            return _gameName
        }
        set {
            _gameName = newValue
        }
    }
    
    var numRows: Int {
        get {
            return _numRows
        }
        set {
            _numRows = newValue
        }
    }
    
    var numColumns: Int {
        get {
            return _numColumns
        }
        set {
            _numColumns = newValue
        }
    }
    
    func deletePreferences() {
        
        print("testing that deletePreferences was triggered")
        
        // So there's no way that I can find to iterate through a nested enum, so this is ugly...
        // Brute force delete by all of the known keys
        // Delete colors
        for item in PrefKeys.Colors.allCases {
            defaults.removeObject(forKey: "\(item)")
            
        }
        // Names
        for item in PrefKeys.Players.allCases {
            defaults.removeObject(forKey: "\(item)")
        }
        
        // Board Size
        for item in PrefKeys.BoardSize.allCases {
            defaults.removeObject(forKey: "\(item)")
        }
        
        // Game Name
        for item in PrefKeys.MiscPrefs.allCases {
            defaults.removeObject(forKey: "\(item)")
        }
    }
}




