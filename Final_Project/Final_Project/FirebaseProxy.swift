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

import Foundation  // needed for notification center
import UIKit // needed for alerts
import Firebase


class FirebaseProxy {
    
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
    
    // Called at end of game
    func resetPlayerOne()  {
    
        let reference = FirebaseProxy.db.collection("elect_leader").document("123456")
        reference.updateData(["leader_bit": false])
        reference.updateData(["gameStarted": false])
    }
    
    
    
    
    // Called app startup...
    func electPlayerOne(completion: @escaping ( Bool ) -> Void ) {
        
        let reference = FirebaseProxy.db.collection("elect_leader").document("123456")
        let maxTurns = self.modelGameLogic.maxTurns
        
        FirebaseProxy.db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(reference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            guard let leaderBit = document.data()?["leader_bit"] as? Bool else {
                
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve leader_bit from snapshot \(document)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            print("leader Bit from Firestore \(leaderBit)")
            // leaderBit is current false, i.e. no player one. Go ahead and set
            if !leaderBit {
                Util.log("\nUpdated leader bit\n")
                // Go ahead and upload our player names.
                // For now we'll use the playerOneName from each player to be THEIR name
//                transaction.updateData(["playerOneName": self.modelGamePrefs.playerOneName], forDocument: reference)
                let dataToUpdate = ["leader_bit": true,"gameStarted": false, "maxTurns": maxTurns] as [String : Any]
                transaction.updateData(dataToUpdate, forDocument: reference)

                // Update in model as well
            }
                
            // Already have a player one
            else {
                
                Util.log("\nUpdated leader reset for next game\n")
                // Download number of turns
                guard let maxTurns = document.data()?["maxTurns"] as? Int else {
                    fatalError("Could not set maximum number of turns")
                    
                }
                self.modelGameLogic.maxTurns = maxTurns
                
                // We'll use each device's PlayerOneName for the player's names
//                transaction.updateData(["playerTwoName": self.modelGamePrefs.playerOneName], forDocument: reference)
                transaction.updateData(["leader_bit": false], forDocument: reference)
            }
            
            return (!leaderBit) // Ideally this should return True and in completion block below we set in model
        })
        {(object, error) in
            guard let leaderBit = object as? Bool else {
                Util.log("Unable to set leader bit")
                return
            }
            if let error = error {
                Util.log("Transaction failed: \(error)")
            } else {
                Util.log("Transaction successfully committed!")
                completion(leaderBit)

            }
        }
    }
    
    func startGame(completion: @escaping () -> Void) {
    
        Util.log("startGame function")
        FirebaseProxy.db.collection("elect_leader").document("123456").setData(["gameStarted": true], merge: true) { error in
            if let error = error {
                Factory.displayAlert(target: GameBoardVC.self, error: error)
//                Util.log("Game is on!")
//                completion()
            }
            Util.log("Game is on!")
            completion()
        }
        
        
    }
    
    var listenerJoin : ListenerRegistration!
    //TODO: - Fix returning errors if we have them to calling function
    func listenPlayersJoin(completion: @escaping ([String: Any], Error?, ListenerRegistration) -> Void) {
        
        let joinQuery = Firestore.firestore().collection("elect_leader").limit(to: 1)
        
        listenerJoin =  joinQuery.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
//                guard let data = document.data() else {
//                    print("Document data was empty.")
//                    return
//                }
//                let source = document.metadata.hasPendingWrites ? "Local" : "Server"
//                print("\(source) data: \(document.data() ?? [:])")
//
//                print("Current data: \(data)")
//                completion(data, nil, self.listener)
        
        
            snapshot.documentChanges.forEach { diff in
                
                var temp: [String: Any]
                
                if (diff.type == .modified) {
                    temp = diff.document.data()

    //              print("Modified city: \(diff.document.data())")
                    completion(temp, nil, self.listenerJoin)

                }
            }
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
    
    
//
//    //Added by Robert
//    static func saveHistory(endOfGameState data: Data) {
//

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
    
    // Set Firestore listener
    //TODO: - DO I need spearate queries? What does the listener removal do?
    var moveQuery: Query? {
        didSet {
            if let listener = listener {
                listener.remove()
            }
        }
    }
    
    
    func opponentMoveFirestore(completion: @escaping ([String: Any], ListenerRegistration) -> Void ) {
        print("opponent move Firestore function")
        
        moveQuery = Firestore.firestore().collection("activeGame").order(by: "moveTime", descending: true ).limit(to: 1)
        
        listener =  moveQuery?.addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
//                print(snapshot.documentChanges.count)
            
           
            snapshot.documentChanges.forEach { diff in
                
                var temp: [String: Any]
                
                    if (diff.type == .added) {
                        print("New move: \(diff.document.data())")
                        temp = diff.document.data()
                        print("temp is \(temp)")
                        completion(temp, self.listener)

                    }
//                    if (diff.type == .modified) {
//                        temp = diff.document.data()
//
////                        print("Modified city: \(diff.document.data())")
//                        completion(temp)
//
//                    }
//                    if (diff.type == .removed) {
//                        print("Removed city: \(diff.document.data())")
//                    }
                
                
                }
        }
    }
    
    
    
    // Stores game results in Firestore; moves are stored in a separate colleciton with a reference to them.
    // Might use the moves later for a detail hisotry view..
    func storeGameResults(_ image: UIImage?, completion: @escaping (Error?) -> Void) {
        
        // Create unique name to reference this collection. Current time will always be unique.
        // Fetch as Epoch time so it's simply a number, convert to string
        let gameMoves = "\(Date().timeIntervalSince1970)"
        copyGameMoves(referenceName: gameMoves )
        
        var imageData: Data? = nil
        // This should be passed in Via listener or something but use here for temporary
        let scores = CalculateScore.gameTotalBruteForce(passedInArray: modelGameLogic.gameBoard)
        
        // Get image of gameboard
        
        //TODO: Force unwrapping now just to test
        
//        let resizedImage = resizeImage(image: image, newWidth: 80.0)
//        let imageData = resizedImage.pngData()
        
        if let image = image {
            
            imageData = resizeImage(image: image, newWidth: 80.0).pngData()
        }
        
        FirebaseProxy.db.collection("history").addDocument(data: [
            "playerOneName": modelGamePrefs.playerOneName,
            "playerTwoName": modelGamePrefs.playerTwoName,
            "playerOneScore": scores.playerOne,
            "playerTwoScore": scores.playerTwo,
            "gameDate": NSDate(),
            "gameBoardView": imageData,
            "gameMoves": gameMoves // Simply a reference to the collection where the moves are stored.
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                completion(err)
            } else {
                print("New History Document added ")
                completion(nil)
            }
        }
    }
    
    func deleteGameMoves() {
    
        let oldGame = Firestore.firestore().collection("activeGame")
        oldGame.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            }
            else {
                
                if let snapshot = querySnapshot {
                    for document in snapshot.documents {
                        document.reference.delete()
                    }
                }
            }
        }
    }
    
    
    
    // Make copy of finished game in Firestore so we can play it back later...
    // Source cited
    func copyGameMoves (referenceName: String) { //completion: @escaping ([Game], Error?) -> Void) {
    
//        let oldGame = Firestore.firestore().collection("activeGame")
        
        
        
        let oldGame = Firestore.firestore().collection("activeGame")
//        let historicalGame = Firestore.firestore().collection("testAgain")
        
        oldGame.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            }
            else {
                if let snapshot = querySnapshot {
                    for document in snapshot.documents {
                        let data = document.data()
                        let batch = Firestore.firestore().batch()
                        let docset = querySnapshot
                        
                        let historicalGame = Firestore.firestore().collection(referenceName).document()
                        
                        docset?.documents.forEach {_ in batch.setData(data, forDocument: historicalGame)}
                        
                        batch.commit(completion: { (error) in
                            if let error = error {
                                print("\(error)")
                            }
                            else {
//                                document
                                print("success")
                            
                            }
                        })
                    }
                }
            }
        }
    }
    
    
    
    func downloadHistory( completion: @escaping ([Game], Error?) -> Void) {
        
        print("Function downloadHistory called")
        
        var resultsArray = [Game]()
        // Create query.
        historyQuery = Firestore.firestore().collection("history").order(by: "gameDate", descending: true ).limit(to: 10)
        
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

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    
//    let scale = newWidth / image.size.width
    let newHeight = newWidth // Make it square. Current thumbnail looks strange
//    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    //TODO: Remove optional
    return newImage!
    
}



