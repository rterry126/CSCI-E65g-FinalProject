//
//  FirebaseProxy.swift
//  Final_Project
//
//
//
// Sources - Closures and @escaping - https://firebase.googleblog.com/2018/07/swift-closures-and-firebase-handling.html
// Sources - https://code.tutsplus.com/tutorials/getting-started-with-cloud-firestore-for-ios--cms-30910

import Foundation  // needed for notification center
import Firebase


class FirebaseProxy {
    
    // Use this for now but would eventually like to pass preferences in via VC
    var modelGamePrefs: GamePrefModelProtocol = {
        Util.log("FirebaseProxy ==> Preferences Model: instantiate")
        return GamePrefModel.instance
    }()
    
    // Don't necessarily like having proxy go directly to the model. Would like to pass in via VC
    
    // Set preferences
    lazy var documentData = ["playerOneName": modelGamePrefs.playerOneName, "playerTwoName": modelGamePrefs.playerTwoName]
    let mergeFields = ["playerOneName", "playerTwoName"]
    
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
    
    static func electLeader() {
        
        let sfReference = FirebaseProxy.db.collection("elect_leader").document("123456")
        
    
        FirebaseProxy.db.runTransaction({ (transaction, errorPointer) -> Any? in
            let sfDocument: DocumentSnapshot
            do {
                try sfDocument = transaction.getDocument(sfReference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let leaderBit = sfDocument.data()?["leader_bit"] as? Bool else {
                
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve leader_bit from snapshot \(sfDocument)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            if !leaderBit {
                print("\nUpdated leader bit\n")
                transaction.updateData(["leader_bit": true], forDocument: sfReference)
                // Update in model as well
            }
            return nil // Ideally this should return True and in completion block below we set in model
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            } else {
                print("Transaction successfully committed!")
            }
        }

    }
    
    // Async closure so call completion handler when done to continue
    func requestInitialize(completion: @escaping () -> Void) {
        
//        let rootCollectionRef: CollectionReference = Firestore.firestore().collection("activeGame")
        let rootCollectionRef: CollectionReference = FirebaseProxy.db.collection("activeGame")

        
        rootCollectionRef.getDocuments { [unowned self] // avoid strong reference to self in closure
            
            (snapshot: QuerySnapshot?, error: Error?) in
            
            guard let rootObjSnapshot: QueryDocumentSnapshot = snapshot?.documents.first else {
                
                NSLog("Cannot find active game: \(error?.localizedDescription ?? "Missing Error")")
                
                self.activeRootObj = nil // see didSet observer for handling
                
                completion() // Should we throw a fatal error above??
                return
                
            }
            
            let rootID: String = rootObjSnapshot.documentID
            Util.log("FirebaseProxy --> Root ID is \(rootID)")
            
            // Take an active game reference and turn it into the actual data
            
            self.activeRootObj = rootCollectionRef.document(rootID)
            completion()
            
        }
    }
    
        private var activeRootObj: DocumentReference? {
    
            didSet {
    
                if let _ = activeRootObj {
                    
                    
                    activeRootObj?.setData(documentData, mergeFields: mergeFields, completion: nil)
                    
                    Util.log("activeRootObj didSet run, preferences loaded into Firebase")
                    
                    
    
                    // Switch state from initializing to initialized; notify everyone
                    StateMachine.state = .readyForGame
                    // I.e. a listener should trigger the stateReadyForGame function????
                    
                    // Can either put notifications at each state change OR attach to the enum 'state'
                    // Attaching to the enum means that we would have to also post which state it was changed to. This might be easier
                    // for now....
                    NotificationCenter.default.post(name: .readyForGame, object: self)
                    
                }
                else {
    
                    // Switch to permanent error state; don't worry about recovery now
                }
            }
        }
    
    
//
//    //Added by Robert
//    static func saveHistory(endOfGameState data: Data) {
//
////        // Add a new document with a generated ID
////        var ref: DocumentReference? = nil
////        ref = db.collection("history_test").addDocument(data: [
////            "playerOneName": playerOneName,
////            "playerTwoName": playerTwoName,
////            "playerOneScore": playerOneScore,
////            "playerTwoScore": playerTwoScore,
////            "created_at": NSDate()
////        ]) { err in
////            if let err = err {
////                print("Error adding document: \(err)")
////            } else {
////                print("Document added with ID: \(ref!.documentID)")
////            }
////        }
//
//        // Basic writes
//
//        let collection = Firestore.firestore().collection("history_test")
//
//        let restaurant = Restaurant(
//            name: name,
//            category: category,
//            city: city,
//            price: price,
//            ratingCount: 10,
//            averageRating: 0,
//            photo: photo
//        )
//
//        let restaurantRef = collection.addDocument(data: restaurant.dictionary)
//
//        let batch = Firestore.firestore().batch()
//        guard let user = Auth.auth().currentUser else { continue }
//        var average: Float = 0
//        for _ in 0 ..< 10 {
//            let rating = Int(arc4random_uniform(5) + 1)
//            average += Float(rating) / 10
//            let text = rating > 3 ? "good" : "food was too spicy"
//            let review = Review(rating: rating,
//                                userID: user.uid,
//                                username: user.displayName ?? "Anonymous",
//                                text: text,
//                                date: Date())
//            let ratingRef = restaurantRef.collection("ratings").document()
//            batch.setData(review.dictionary, forDocument: ratingRef)
//        }
//        batch.updateData(["avgRating": average], forDocument: restaurantRef)
//        batch.commit(completion: { (error) in
//            guard let error = error else { return }
//            print("Error generating reviews: \(error). Check your Firestore permissions.")
//        })
//
//    }
//
    
//
//
//

//
//
//


//    // Static added by Robert
//    static private let _db: Firestore = {
//
//        // Locally bound to where it's needed. Keep related things close together!
//
//        FirebaseApp.configure()
//
//        let db: Firestore = Firestore.firestore()
//
//        // This little extra is just from console output if you fail to do so
//
//        let settings: FirestoreSettings = db.settings
//
//        settings.areTimestampsInSnapshotsEnabled = true
//
//        db.settings = settings
//
//        return db
//
//    }()


    

    /************** Inbound (mostly) Firestore Functions  ****************/
    
    private var documents: [DocumentSnapshot] = []
    
    // Pretty cool. Because of listener we don't have to refresh tableView when data is added on backend
    // It automatically updates
    private var listener : ListenerRegistration!
    
    // Set Firestore listener
    var historyQuery: Query? {
        didSet {
            if let listener = listener {
                listener.remove()
            }
        }
    }
    
    
    
    func downloadHistory( completion: @escaping ([Game], Error?) -> Void) {
        
        print("Function downloadHistory called")
        
        var resultsArray = [Game]()
        // Create query.
        historyQuery = Firestore.firestore().collection("history_test").order(by: "created_at", descending: true ).limit(to: 10)
        
        /*listener =*/  historyQuery?.addSnapshotListener { ( documents, error) in
            
            guard let snapshot = documents else {
                if let error = error {
                    print(error)
                    // Return error to async calling closure in HistoryMasterVC
                    completion(resultsArray, error)
//                    return
                }
                return
            }
                // Basically go through the sequence and pull out the data...
                resultsArray = snapshot.documents.map { (document) -> Game in
                    if let game = Game(dictionary: document.data(), id: document.documentID) {
                        print("History \(game.id) => \(game.playerTwoName )")
                        return game
                    }
                    else {
                        fatalError("Unable to initialize type \(Game.self) with dictionary \(document.data())")
                    }
                }
                // Return results to async calling closure in HistoryMasterVC
                print("results array size is \(resultsArray.count)")
                completion(resultsArray, nil)
        }
    }
    
    /************** Outbound (mostly) Firestore Functions  ****************/
    func storeGameBoardImage(image: UIImage) {
        
        let resizedImage = resizeImage(image: image, newWidth: 80.0)
        let imageData = resizedImage.pngData()
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
    
    
}


// Put in helper functions eventually

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    //TODO: Remove optional
    return newImage!
    
}



