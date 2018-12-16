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
// Sources - Firestore batch writing - https://firebase.google.com/docs/firestore/manage-data/transactions

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
    
    
    func uploadGame(_ gameModel: GameLogicModelProtocol, completion: @escaping () -> Void) {
        
        
//     print(gameModel.gameBoard)
        var fakeMoveNumber = 1
        // Get new write batch
        let batch = Firestore.firestore().batch()
        
        // Create 'header' document
        let headerToStore: [String : Any] = ["playerOneName": modelGamePrefs.playerOneName, "playerTwoName": modelGamePrefs.playerTwoName, "moveTime": FieldValue.serverTimestamp() ]
        
        // Setup our header document
        let header = Firestore.firestore().collection("activeGame").document("\(0)")
        batch.setData(headerToStore, forDocument: header)
        
        for row in 0..<gameModel.gameBoard.count {
            for column in 0..<gameModel.gameBoard[0].count {
                
                let grid = gameModel.gameBoard[row][column]
                if grid != .empty {
                    
                    print("\(gameModel.gameBoard[row][column].rawValue) \(row) \(column)")
                    
                    // Write the moves as a batch. We won't have the actual move time as it wasn't persisted, however I'm going to
                    // add a moveTime field to keep the data consistent. Move numbers won't correspond to the actual move numbers
                    // but this doesn't matter, we're just resetting the board state.
                    
                    
                    // Create moves to upload
                    let dataToStore:[String : Any] = ["moveTime": FieldValue.serverTimestamp(),"column": column, "row": row, "player": gameModel.gameBoard[row][column].rawValue ]
                    
                    
                    // Setup our moves document
                    let gameMoves = Firestore.firestore().collection("activeGame").document("\(fakeMoveNumber)")
                    batch.setData(dataToStore, forDocument: gameMoves)
                    
                    fakeMoveNumber += 1
                }
            }
        }
        
        // Commit the batch
        batch.commit() { err in
            if let err = err {
                print("Error writing batch \(err)")
            } else {
                print("Batch write succeeded.")
                completion()
            }
        }
    }
    
    // Called at end of game
    func resetPlayerOne()  {
    
        let reference = FirebaseProxy.db.collection("elect_leader").document("123456")
        reference.updateData(["leader_bit": false])
        reference.updateData(["gameStarted": false])
    }
    
    
    
    
    // Called app startup...
    // 1) Determines P1 & P2 2) Sets maxNum of turns 3) Uploads each player's name 4) Sets P1's name
    // when for P2 when it calls.
    func electPlayerOne(completion: @escaping ( Bool, String ) -> Void ) {
        
        let reference = FirebaseProxy.db.collection("elect_leader").document("123456")
        let maxTurns = self.modelGameLogic.maxTurns
        var playerOneName = self.modelGamePrefs.myNameIs
        let playerTwoName = self.modelGamePrefs.myNameIs
        
        FirebaseProxy.db.runTransaction({ (transaction, errorPointer) -> (Bool?, String?) in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(reference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return (nil,nil)
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
                return (nil,nil)
            }
            print("leader Bit from Firestore \(leaderBit)")
            // leaderBit is current false, i.e. no player one. Go ahead and set
            if !leaderBit {
                Util.log("\nUpdated leader bit\n")
                
                let dataToUpdate = ["leader_bit": true,"gameStarted": false, "maxTurns": maxTurns, "playerOneName": playerOneName] as [String : Any]
                transaction.updateData(dataToUpdate, forDocument: reference)

            }
            // Else this is Player 2 logic
            else {
                
                Util.log("\nUpdated leader reset for next game\n")
                // Download number of turns
                guard let maxTurns = document.data()?["maxTurns"] as? Int else {
                    fatalError("Could not set maximum number of turns")
                }
                //TODO:  This sets maxTurns for Player 2. Not sure how to get it out of here...
                self.modelGameLogic.maxTurns = maxTurns
                
                playerOneName = document.data()?["playerOneName"] as? String ?? "Player 11"
                    
               let dataToUpdate = ["leader_bit": false, "playerTwoName": playerTwoName] as [String : Any]
               
                transaction.updateData(dataToUpdate, forDocument: reference)
            }
            return (!leaderBit, playerOneName) // Ideally this should return True and in completion block below we set in model
        })
        {(object, error) in
            guard let object = object as? (leaderBit: Bool, playerOneName: String) else {
                Util.log("Unable to set leader bit")
                return
            }
            if let error = error {
                Util.log("Transaction failed: \(error)")
            } else {
                Util.log("Transaction successfully committed!")
                completion(object.leaderBit, object.playerOneName)

            }
        }
    }
    
    
    
    
    func startGame(completion: @escaping () -> Void) {
    
        Util.log("startGame function")
        FirebaseProxy.db.collection("elect_leader").document("123456").setData(["gameStarted": true], merge: true) { error in
            if let error = error {
                Factory.displayAlert(target: GameBoardVC.self, error: error)
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
                print("Error fetching document: \(String(describing: error))")
                    return
                }

            snapshot.documentChanges.forEach { diff in
                
                var temp: [String: Any]
                
                if (diff.type == .modified) {
                    temp = diff.document.data()

                    completion(temp, nil, self.listenerJoin)

                }
            }
        }
    }
    
    func equestInitialize() {
        
        let rootCollectionRef: CollectionReference = FirebaseProxy.db.collection("activeGame")
    
        // Different initialization logic depending on which player. Election is complete when this is called
        if modelGameLogic.amIPlayerOne {
            
            // 1) Clean up any orphaned game moves
//            deleteGameMoves()
            
            // 2) Set 'header' document
//            rootCollectionRef.document("\(0)").setData(["moveTime": FieldValue.serverTimestamp() ])
            rootCollectionRef.document("\(0)").setData(self.documentData, mergeFields: self.mergeFields, completion: nil)
//             { err in
//                if let err = err {
//                    print("Error writing document: \(err)")
//                } else {
//                    StateMachine.state = .waitingForPlayer2 // added to wait until 2nd player joins
//
//                    print("Document successfully written!")
//                }
//            }
            
            // 3) Upload saved game if it exists
            
            
            
        }
        else {
            
            StateMachine.state = .waitingForGameStart // Player2's state
            
        }
    }
    
    
    
    // Async closure so call completion handler when done to continue
    func requestInitialize()  {
        
        if modelGameLogic.amIPlayerOne {
            
            Util.log("requestInitialize thinks I am Player one")
            
            // 1) Clean up any orphaned game moves
            deleteGameMoves() {
            
                // 2) Initialize previous game if it exists
            
                do {
                    let restoredObject = try Persistence.restore()
                    guard let mdo = restoredObject as? GameLogicModelProtocol else {
                        print("Got the wrong type: \(type(of: restoredObject)), giving up on restoring")
                        return
                    }
                    // Let's try setting a reference to our restored state
                    self.modelGameLogic = mdo
                    
                    
                    // Call proxy to upload state to Firestore
                    self.uploadGame(self.modelGameLogic) {
                    
                        print("Success: in restoring game state")
                    }
                }
                catch let e {
                    print("Restore failed: \(e).")
                    
                    // So evidently if it fails here to restore saved model it uses the default init()
                    // defined in the model. Code below isn't needed (saved as a reminder as to flow of init)
                    
                    //            var modelGameLogic: GameLogicModelProtocol =
                    //               GameLogicModel()
                }
            }
            
        }
        
  
            print(self.modelGameLogic.amIPlayerOne)
            if self.modelGameLogic.amIPlayerOne {
                
                StateMachine.state = .waitingForPlayer2 // added to wait until 2nd player joins
            }
            else {
                FirebaseProxy.db.collection("activeGame").getDocuments() { (querySnapshot, err) in
                    
                    
                    if let err = err {
                        print("Error getting documents: \(err)")
                    }
                    else {
                        
                        for document in querySnapshot!.documents {
                            if document.documentID != "\(0)" {
                                print("\(document.documentID) => \(document.data())")
                                
                                let move = document.data()
                                
                                guard let gridState = move["player"] as? String else {
                                    print("Error retrieving move player ID")
                                    return
                                }
                                var player = GridState(rawValue: gridState) ?? .empty
                                guard let row = move["row"] as? Int else {
                                    print("Error retrieving move row")
                                    return
                                }
                                guard let column = move["column"] as? Int  else {
                                    print("Error retrieving move column")
                                    return
                                }
                               
                                self.modelGameLogic.gameBoard[row][column] = player
                            }
                            
                            // Restore player 2 function goes here
                        }
                    }
                }

                StateMachine.state = .waitingForGameStart // Player2's start
            }
        }



    /************** Inbound (mostly) Firestore Functions  ****************/
    
    private var documents: [DocumentSnapshot] = []
    
    // Pretty cool. Because of listener we don't have to refresh tableView when data is added on backend
    // It automatically updates
    private var listenerHistory : ListenerRegistration!
    var listener : ListenerRegistration!

    
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
    
    
    func opponentMoveFirestore(completion: @escaping ([String: Any], ListenerRegistration) -> Void ) {
        print("opponent move Firestore function")
        
        moveQuery = Firestore.firestore().collection("activeGame").order(by: "moveTime", descending: true ).limit(to: 1)
        
        listener =  moveQuery?.addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(String(describing: error))")
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
            
            imageData = resizeImage(image: image, newWidth: 80.0)?.pngData()
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
    
    func deleteGameMoves(completion: @escaping () -> Void) {
    
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
            completion()
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
        
        listenerHistory =  historyQuery?.addSnapshotListener { ( documents, error) in
            
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



