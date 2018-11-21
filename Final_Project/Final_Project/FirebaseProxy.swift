//
//  FirebaseProxy.swift
//  Final_Project
//
//
//
import Firebase


class FirebaseProxy {
    
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
        
        print("Private Firebase variable set")
        return db
    }()


    
    static var db: Firestore {
        get {
            print("Firebase Proxy --> db handle created")
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
    
    func requestInitialize() {
        
        let rootCollectionRef: CollectionReference = Firestore.firestore().collection("activeGame")
        
        rootCollectionRef.getDocuments { [unowned self] // avoid strong reference to self in closure
            
            (snapshot: QuerySnapshot?, error: Error?) in
            
            guard let rootObjSnapshot: QueryDocumentSnapshot = snapshot?.documents.first else {
                
                NSLog("Cannot find active game: \(error?.localizedDescription ?? "Missing Error")")
                
                self.activeRootObj = nil // see didSet observer for handling
                
                return
                
            }
            
            let rootID: String = rootObjSnapshot.documentID
            print("FirebaseProxy --> Root ID is \(rootID)")
            
            // Take an active game reference and turn it into the actual data
            
            self.activeRootObj = rootCollectionRef.document(rootID)
            
        }
    }
    
        private var activeRootObj: DocumentReference? {
    
            didSet {
    
                if let _ = activeRootObj {
                    let documentData = ["playerOneName": "Sammy", "playerTwoName": "Joanna"]
                    let mergeFields = ["playerOneName", "playerTwoName"]
                    activeRootObj?.setData(documentData, mergeFields: mergeFields, completion: nil)
                    
                    print("activeRootObj didSet run")
                    
                    // Set preferences
    
                    // Switch state from initializing to initialized; notify everyone
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


    

    /************** Inbound Firestore Functions (mostly) ****************/

//    static func baseQuery( collection: String, orderBy: String, limit: Int) -> Query {
//        return Firestore.firestore().collection(collection).order(by: orderBy, descending: true ).limit(to: limit)
//    }
    
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
        
//        historyQuery.getDocuments { snapshot, error in
        /*listener =*/  historyQuery?.addSnapshotListener { ( documents, error) in
            
            guard let snapshot = documents else {
                if let error = error {
                    print(error)
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
                completion(resultsArray, nil)
            
        }
        
    }




}
