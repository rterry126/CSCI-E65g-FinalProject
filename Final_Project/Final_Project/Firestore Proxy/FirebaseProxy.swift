//
//  FirebaseProxy.swift
//  Final_Project
//
//
//
// Sources - Closures and @escaping - https://firebase.googleblog.com/2018/07/swift-closures-and-firebase-handling.html
// Sources - https://code.tutsplus.com/tutorials/getting-started-with-cloud-firestore-for-ios--cms-30910
// Sources - Firestore listeners - https://firebase.google.com/docs/firestore/query-data/listen
// Sources - copying Firestore Collection - https://stackoverflow.com/questions/50788184/firestore-creating-a-copy-of-a-collection
// Sources - basic code to delete documents in a collection - https://stackoverflow.com/questions/51792471/cloud-firestore-swift-how-to-delete-a-query-of-documents?rq=1

// Sources - resize UIImage (thumbnail creation) - https://stackoverflow.com/questions/31966885/resize-uiimage-to-200x200pt-px

import Foundation  // needed for notification center
import UIKit // needed for alerts
import Firebase


class FirebaseProxy {
    
    //MARK: - Stored Properties
    var documents: [DocumentSnapshot] = []
    var listenerHistory : ListenerRegistration!
    var listener : ListenerRegistration!
    var listenerJoin : ListenerRegistration!
    var historyLimit = 10
    
    
    // Set Firestore listener
    var historyQuery: Query? {
        didSet {
            if let listener = listenerHistory{
                listener.remove()
            }
        }
    }
    
    // Set Firestore listener
    var moveQuery: Query? {
        didSet {
            if let listener = listener {
                listener.remove()
            }
        }
    }
    
    
    //MARK: - Instances
    
    // Use this for now but would eventually like to pass preferences in via VC
    var modelGamePrefs: GamePrefModelProtocol = {
        Util.log("FirebaseProxy ==> Preferences Model: instantiate")
        return GamePrefModel.instance
    }()
    
    var modelGameLogic: GameLogicModelProtocol = GameLogicModel.instance
    
    
    // Set preferences
    lazy var documentData = ["playerOneName": modelGamePrefs.playerOneName, "playerTwoName": modelGamePrefs.playerTwoName, "moveTime": FieldValue.serverTimestamp() ]
    let mergeFields = ["playerOneName", "playerTwoName", "moveTime"]
    
    static let instance = FirebaseProxy()
    private init() {}
    
    // Static added by Robert
    static private let _db: Firestore = {
        
        // Locally bound to where it's needed. Keep related things close together!
        FirebaseApp.configure()
        
        let db: Firestore = Firestore.firestore()
        
        // This little extra is just from console output if you fail to do so
        
        let settings: FirestoreSettings = db.settings
        
        settings.areTimestampsInSnapshotsEnabled = true
        
        db.settings = settings
        
        Util.log("Private Firebase variable set")
        return db
    }()
    
    
    
    static var db: Firestore {
        get {
            Util.log("Firebase Proxy --> db handle created")
            return self._db
        }
    }
    
    
    
    func requestInitialize() {
        
        if modelGameLogic.amIPlayerOne {
            
            deleteCompletedGame() { [unowned self] in // cleanup first
            
                // if there is saved game
                if restoreModel(&self.modelGameLogic) {
                    self.uploadGame(self.modelGameLogic) { [unowned self] in
                        print("printing from initialize")
                        print(self.modelGameLogic.gameBoard)
                        self.modelGameLogic.amIPlayerOne = true // overwritten by restore
                        self.requestInitialize2()
                        
                    }
                }
                else {
                    // No game to restore. Initialize normally
                    self.requestInitialize2()
                }
            }
        }
        //Player 2
        else {
            self.requestInitialize2()
        }
    }
    
    // Async closure so call completion handler when done to continue
    func requestInitialize2()  {
        
        //        let rootCollectionRef: CollectionReference = Firestore.firestore().collection("activeGame")
        let rootCollectionRef: CollectionReference = FirebaseProxy.db.collection("activeGame")
        
        rootCollectionRef.getDocuments { [unowned self] // avoid strong reference to self in closure
            
            (snapshot: QuerySnapshot?, error: Error?)  in
            
            guard let rootObjSnapshot: QueryDocumentSnapshot = snapshot?.documents.first else {
                
                
                NSLog("Cannot find active game: \(error?.localizedDescription ?? "Missing Error")")
                
    

                //No active game to upload the preferences into document zero '0'
                rootCollectionRef.document("\(0)").setData(self.documentData, mergeFields: self.mergeFields, completion: nil)
                // Initializing is successful, change state
                //                StateMachine.state = .readyForGame
                if self.modelGameLogic.amIPlayerOne {
                    
                    
                    StateMachine.state = .waitingForPlayer2 // added to wait until 2nd player joins
                }
                else {
                    StateMachine.state = .waitingForGameStart // Player2's state
                }
                return
                
            }
            
            let rootID: String = rootObjSnapshot.documentID
            Util.log("FirebaseProxy --> Root ID is \(rootID)")
            
            // Take an active game reference and turn it into the actual data
            
            self.activeRootObj = rootCollectionRef.document(rootID)
            
            print("printing from initialize2")
            print(self.modelGameLogic.gameBoard)
            if self.modelGameLogic.amIPlayerOne {
                StateMachine.state = .waitingForPlayer2 // added to wait until 2nd player joins
            }
            else {
                
                if let documentCount = snapshot?.count{
                    if documentCount > 1 {
                        self.restorePlayerTwo() {
                            StateMachine.state = .waitingForGameStart // Player2's start
                        }
                    }
                    
                }
                StateMachine.state = .waitingForGameStart // Player2's start
            }
            
            
        }
    }
    
    private var activeRootObj: DocumentReference? {
        
        didSet {
            
            if let _ = activeRootObj {
                Util.log("activeRootObj didSet run, preferences loaded into Firebase")
                
            }
            else {
                
                // Switch to permanent error state; don't worry about recovery now
            }
        }
    }
}


