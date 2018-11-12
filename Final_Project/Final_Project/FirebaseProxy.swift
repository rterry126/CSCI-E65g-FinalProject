//
//  FirebaseProxy.swift
//  Final_Project
//
//
//
import Firebase


class MinimalFirebaseProxy {
    

    static var db: Firestore {
        get {
            return self._db
        }
    }
    
    //Added by Robert
    static func saveHistory(endOfGameState data: Data) {
        
//        // Add a new document with a generated ID
//        var ref: DocumentReference? = nil
//        ref = db.collection("history_test").addDocument(data: [
//            "playerOneName": playerOneName,
//            "playerTwoName": playerTwoName,
//            "playerOneScore": playerOneScore,
//            "playerTwoScore": playerTwoScore,
//            "created_at": NSDate()
//        ]) { err in
//            if let err = err {
//                print("Error adding document: \(err)")
//            } else {
//                print("Document added with ID: \(ref!.documentID)")
//            }
//        }
        
        // Basic writes
        
        let collection = Firestore.firestore().collection("history_test")
        
        let restaurant = Restaurant(
            name: name,
            category: category,
            city: city,
            price: price,
            ratingCount: 10,
            averageRating: 0,
            photo: photo
        )
        
        let restaurantRef = collection.addDocument(data: restaurant.dictionary)
        
        let batch = Firestore.firestore().batch()
        guard let user = Auth.auth().currentUser else { continue }
        var average: Float = 0
        for _ in 0 ..< 10 {
            let rating = Int(arc4random_uniform(5) + 1)
            average += Float(rating) / 10
            let text = rating > 3 ? "good" : "food was too spicy"
            let review = Review(rating: rating,
                                userID: user.uid,
                                username: user.displayName ?? "Anonymous",
                                text: text,
                                date: Date())
            let ratingRef = restaurantRef.collection("ratings").document()
            batch.setData(review.dictionary, forDocument: ratingRef)
        }
        batch.updateData(["avgRating": average], forDocument: restaurantRef)
        batch.commit(completion: { (error) in
            guard let error = error else { return }
            print("Error generating reviews: \(error). Check your Firestore permissions.")
        })
        
    }
    
    // Static added by Robert
    static private let _db: Firestore = {
        
        // Locally bound to where it's needed. Keep related things close together!
        
        FirebaseApp.configure()
        
        let db: Firestore = Firestore.firestore()
        
        // This little extra is just from console output if you fail to do so
        
        let settings: FirestoreSettings = db.settings
        
        settings.areTimestampsInSnapshotsEnabled = true
        
        db.settings = settings
        
        return db
        
    }()
    
    
    
    private var activeRootObj: DocumentReference? {
        
        didSet {
            
            if let _ = activeRootObj {
                
                // Switch state from initializing to initialized; notify everyone
            }
            else {
                
                // Switch to permanent error state; don't worry about recovery now
            }
        }
    }
    
    
    
    func requestInitialize() {
        
        let rootCollectionRef: CollectionReference = Firestore.firestore().collection("RootKey")
        
        rootCollectionRef.getDocuments { [unowned self] // avoid strong reference to self in closure
            
            (snapshot: QuerySnapshot?, error: Error?) in
            
            guard let rootObjSnapshot: QueryDocumentSnapshot = snapshot?.documents.first else {
                
                NSLog("Cannot find active game: \(error?.localizedDescription ?? "Missing Error")")
                
                self.activeRootObj = nil // see didSet observer for handling
                
                return
                
            }
            
            let rootID: String = rootObjSnapshot.documentID
            
            // Take an active game reference and turn it into the actual data
            
            self.activeRootObj = rootCollectionRef.document(rootID)
            
        }
        
    }
    
}
