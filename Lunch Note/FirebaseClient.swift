//
//  FirebaseClient.swift
//  Lunch Note
//
//  Created by James Dyer on 6/9/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import Foundation
import Firebase

class FirebaseClient {
    
    //Properties
    static let sharedInstance = FirebaseClient()
    
    var downloadTask: FIRStorageDownloadTask!
    
    var userReference: FIRDatabaseReference {
        return FirebaseClient.Constants.Database.REF_USERS.child(FirebaseClient.sharedInstance.currentUser!)
    }
    var lunchBoxReference: FIRDatabaseReference {
        return userReference.child("lunchbox")
    }
    var blockUserReference: FIRDatabaseReference {
        return userReference.child("blocked")
    }
    var notesReference: FIRDatabaseReference {
        return userReference.child("notes")
    }
    
    var storageReference: FIRStorageReference {
        return FIRStorage.storage().reference().child("profilepictures/\(FirebaseClient.sharedInstance.currentUser!)")
    }
    
    var currentUser: String? {
        let user = FIRAuth.auth()?.currentUser
        let uid = user?.uid
        return uid
    }
    
    var currentDisplayName: String? {
        let user = FIRAuth.auth()?.currentUser
        let displayName = user?.displayName
        return displayName
    }
    
    var currentUserImage: String {
        let user = FIRAuth.auth()?.currentUser
        let currentImage = user?.photoURL?.absoluteString
        return currentImage!
    }
    
    /**
     Downloads an image from firebase storage.
     
     - Parameter author: The uid of the author of the image.
     - Parameter url: The storage reference for the image.
     - Parameter completionHandler: Handles what to do once the request is done.
     - Parameter success: A Bool of whether the request was successful.
     */
    func downloadImage(author: String, url: FIRStorageReference, completionHandler: (result: UIImage?) -> Void) {
        
        let localURL: NSURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(author)
        
        downloadTask = url.writeToFile(localURL) { (URL, error) -> Void in
            if (error != nil) {
                completionHandler(result: nil)
            } else {
                let imageData = NSData(contentsOfURL: localURL)
                let image = UIImage(data: imageData!)!
                FirebaseClient.Constants.LocalImages.imageCache.setObject(image, forKey: author)
                completionHandler(result: image)
            }
        }
    }
    
}