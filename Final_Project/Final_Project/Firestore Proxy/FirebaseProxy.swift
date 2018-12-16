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
    
    // Use this for now but would eventually like to pass preferences in via VC
    var modelGamePrefs: GamePrefModelProtocol = {
        Util.log("FirebaseProxy ==> Preferences Model: instantiate")
        return GamePrefModel.instance
    }()
    
    var modelGameLogic: GameLogicModelProtocol = GameLogicModel.instance
    
    // Don't necessarily like having proxy go directly to the model. Would like to pass in via VC
    
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
    
    
    
    
    
    
   
    
    
    
    
    
    
    
   
    
    
    
    // Async closure so call completion handler when done to continue
    func requestInitialize()  {
        
//        let rootCollectionRef: CollectionReference = Firestore.firestore().collection("activeGame")
        let rootCollectionRef: CollectionReference = FirebaseProxy.db.collection("activeGame")

        
        rootCollectionRef.getDocuments { [unowned self] // avoid strong reference to self in closure
            
            (snapshot: QuerySnapshot?, error: Error?)  in
            
            guard let rootObjSnapshot: QueryDocumentSnapshot = snapshot?.documents.first else {
                
                //TODO:- Move this to calling function and return the error.
//                UIViewController.present(Factory.createAlert(error), animated: true, completion: nil)
                
                NSLog("Cannot find active game: \(error?.localizedDescription ?? "Missing Error")")
                
                // Robert - so if there is no active game we'll need to initialize the activeRoot
                // when the game is started I think...
//                self.activeRootObj = nil // see didSet observer for handling
                
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
           
            // Initializing is successful, change state
//            StateMachine.state = .readyForGame
            if self.modelGameLogic.amIPlayerOne {
                StateMachine.state = .waitingForPlayer2 // added to wait until 2nd player joins
            }
            else {
                StateMachine.state = .waitingForGameStart // Player2's start
            }

            
        }
    }
    
        private var activeRootObj: DocumentReference? {
    
            didSet {
    
                if let _ = activeRootObj {
                    
                    
//                    activeRootObj?.setData(documentData, mergeFields: mergeFields, completion: nil)
                    
                    Util.log("activeRootObj didSet run, preferences loaded into Firebase")
                    
                    
                    // Robert - So this is if there is an active game???
                    // If so then it shouldn't go to readForGame but pick up game in route...
                    
                    // Switch state from initializing to initialized; notify everyone
//                    StateMachine.state = .readyForGame
//                    if self.modelGameLogic.amIPlayerOne {
//                        StateMachine.state = .waitingForPlayer2 // added to wait until 2nd player joins
//                    }
//                    else {
//                        StateMachine.state = .waitingForGameStart // Player2's state
//                    }

                    
                    
                }
                else {
    
                    // Switch to permanent error state; don't worry about recovery now
                }
            }
        }
    
    

    
    
    
    
    
    
    
    
    
    
   
    
    /************** Outbound (mostly) Firestore Functions  ****************/
    func storeGameBoardImage(image: UIImage) {
        
        let resizedImage = resizeImage(image: image, newWidth: 80.0)
        let imageData = resizedImage?.pngData()
        var docData = [String: Data]()
        
        // TODO: - Since this is unwrapped, only try to store it below if the unwrapping was successful.
        // Might have to move storing into the 'if let' statement.
        
        // Will address later when this is moved into the storing of entire history.
        if let imageToStore = imageData {
            docData = ["gameBoardView": imageToStore]
        }
        
        // Update one field, creating the document if it does not exist.
        Firestore.firestore().collection("history_test").document("WOqD3gIpLTBn0pxljXqJ").setData(docData, merge: true) { err in
            if let err = err {
                print("Error writing document: \(err)")
            }
            else {
                print("Document successfully written!")
            }
        }
    }
    
    func storeMoveFirestore(row: Int?, column: Int?, playerID: String, moveNumber: Int, completion: @escaping (Error?) -> Void) {
        
        var docData: [String: Any] = ["moveTime": FieldValue.serverTimestamp(), "player": playerID]
        
        // Coordinates are optionals, in case of forfeited move. Only store the fields IF they have values. Will make checking
        // much easier for the other player...
        if let rowExists = row, let columnExists = column {
            docData["row"] = rowExists
            docData["column"] = columnExists
            
        }
        for item in docData {
            print(item.value)
        }
        
        // Update one field, creating the document if it does not exist.
        // setData runs asynchronously. completion() is the 'callback' function to let us know that it was or not successful.
        // If successful then we will update our board logical state and view state and change our state Machine
        
        
        Firestore.firestore().collection("activeGame").document("\(moveNumber + 1)").setData(docData, merge: false) { err in
            if let err = err {
                print("Error writing document: \(err)")
                completion(err)
            }
            else {
                Util.log("Document successfully written!")
                completion(nil)
            }
        }
    }
    
    
}


// Put in helper functions eventually

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
    
    let newHeight = newWidth // Make it square. Current thumbnail looks strange
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
    
}



