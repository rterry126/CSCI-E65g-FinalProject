//
//  FirebaseProxy.swift
//  Final_Project
//
//
//
import Firebase


class MinimalFirebaseProxy {
    
    private let _db: Firestore = {
        
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
