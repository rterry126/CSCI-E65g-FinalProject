//  Persistence.swift
//
//  Created by Daniel Bromberg on 7/20/15.
//  Copyright (c) 2015 S65. All rights reserved.

import Foundation

// Limitations of NSUserDefaults: No custom types or object hierarchiesß
class Persistence {
    static let ModelFileName = "Final_Project_rterry.serialized"
    
   // So we just need a unique name for the thumbnails/actual images
    static let ThumbnailFileName = "\(Date().timeIntervalSince1970)_Thumb"
    static let FileMgr = FileManager.default
    
    // Resources on disk: URLs: "file:///path/to/file"
    static func getStorageURL(storageFileName: String) throws -> URL {
        // Important: searchpath API
        
        // Get the root of the App Sandbox, and a particular kind of subdirecotry
        let dirPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationSupportDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if dirPaths.count == 0 {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "No paths found"])
        }
        // Application support directory does not automatically get created
        // First time run of App, have to create it
        let urlPath = URL(fileURLWithPath: dirPaths[0])
        if !FileMgr.fileExists(atPath: dirPaths[0]) {
            try mkdir(urlPath)
        }
        
        // Create a filename to store things
        // Valid characters: A-Za-z0-9_. (also valid are: + - , but avoid)
        return urlPath.appendingPathComponent(ModelFileName)
    }
    
    
    // think of it as black box to create a directory on iOS filesystem
    static func mkdir(_ newDirURL: URL) throws {
        try FileManager.default.createDirectory(at: newDirURL, withIntermediateDirectories: false, attributes: nil)
    }
    
    
    // Model must inherit from NSObject -- and be a reference type -- structs don't
    // Rather than using full hierarchical capabilities of NSKeyedArchiver,
    // just one object, so it's the "root" object of the file
    
    //This function is called from two places - func saveGameState, which is called after each player's
    // turn AND func preferencesVC which is a delegate.
    static func save(_ data: Data) throws {
        let saveURL = try Persistence.getStorageURL(storageFileName: ModelFileName) // file:///
        print("saveURL: \(saveURL)")
        print("image file \(ThumbnailFileName)")
        // This is a recursive process that will push archiving to the children if set up that way
        // A fast, more fragile, binary format
        
        
        // Robert changes to codable below
        // Not sure what this does or if it's needed with Codable. Model saves and retrieves
        // fine. Was able to save it using this but when retrieving received 'no root found' eeor
//        let data = try NSKeyedArchiver.archivedData(withRootObject: model, requiringSecureCoding: false)
        
        // So data is result of modelGameLogic.toJSONData()
        
        /******* Attempt to append data to file **************/
        // 1) Get current data
        if var previousHistory = try? Data(contentsOf: URL(fileURLWithPath: saveURL.path)) {
            previousHistory.append(data)
            try previousHistory.write(to: saveURL)
        }
            
        else {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve archived data"])
        }
        
        
        
//        try data.write(to: saveURL)
//        print("saved model success \(Date()) to path: \(saveURL)")
    }
    
    
    static func restore() throws -> NSObject {
        let saveURL = try Persistence.getStorageURL(storageFileName: ModelFileName)
        print(saveURL)
        guard let rawData = try? Data(contentsOf: URL(fileURLWithPath: saveURL.path)) else {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve archived data"])
        }
        
        //Take the 'rawData' , run through the decoder per the requested fields in required init of
        // GameLogicModel. decodedObj is returned, cast as 'GameLogicModelProtocol' and then
        // the current model, modelGameLogic is referenced to it. This happens during viewDidLoad()
        let decodedObj =  try? JSONDecoder().decode(GameLogicModel.self, from: rawData)
        
        // Since NSKeyedARchiever wasn't used on encode, skip it here.
//        let decodedObj = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rawData)
        guard let model = decodedObj  else {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to find root object"])
        }
        print("restored model successfully at \(Date()): \(type(of: model))")
        return model
    }
    
    // We're caught in a loop of always restoring if the file exists. So delete it upon game
    // completion automatically. Then next game is started with default values, i.e. fresh.
    static func deleteSavedGame() throws {
        
        // 12.4.18 commented to test appending data into file...
        //        let saveURL = try Persistence.getStorageURL(storageFileName: ModelFileName)
//        try FileMgr.removeItem(at: saveURL)
        
    }
}
