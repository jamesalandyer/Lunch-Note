//
//  FirebaseConstants.swift
//  Lunch Note
//
//  Created by James Dyer on 6/9/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import Firebase
import FirebaseDatabase

extension FirebaseClient {
    
    struct Constants {
        
        struct Database {
            static let REF = FIRDatabase.database().reference()
            static let REF_NOTES = REF.child("notes")
            static let REF_USERS = REF.child("users")
            static let REF_REPORTS = REF.child("reports")
        }
        
        struct LocalImages {
            static var imageCache = NSCache()
        }
        
    }
    
}
