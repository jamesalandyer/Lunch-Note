//
//  NoteCell.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import Firebase

class NoteCell: UITableViewCell {

    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var lunchBoxButton: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var profileButton: CustomImageView!
    
    private let user = FirebaseClient.sharedInstance.currentUser
    private var currentNote: Note!
    
    var authorDelegate: NoteCellAuthorDelegate!
    var deleteDelegate: NoteCellDeleteDelegate!
    
    var lunchBoxGesture: UITapGestureRecognizer!
    var profileGesture: UITapGestureRecognizer!
    
    var lunchboxNote: FIRDatabaseReference!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lunchBoxGesture = UITapGestureRecognizer(target: self, action: #selector(lunchBoxGesturePressed))
        lunchBoxGesture.numberOfTapsRequired = 1
        profileGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped(_:)))
        profileGesture.numberOfTapsRequired = 1
        
        lunchBoxButton.userInteractionEnabled = true
    }
    
    func configureCell(note: Note) {
        currentNote = note
        lunchboxNote = FirebaseClient.Constants.Database.User.LUNCHBOX.child(currentNote.noteKey)
        
        profileButton.image = UIImage(named: "defaultpicture.png")
        
        if currentNote.noteAuthorImage != DEFAULT_PICTURE {
            if let cachedImage = FirebaseClient.Constants.LocalImages.imageCache.objectForKey(note.noteAuthor) as? UIImage {
                print("HAD IT")
                self.profileButton.image = cachedImage
            } else {
                let imageReference = FIRStorage.storage().referenceForURL(currentNote.noteAuthorImage)
                FirebaseClient.sharedInstance.downloadImage(currentNote.noteAuthor, url: imageReference, completionHandler: { (result) in
                    if let image = result {
                        print("GOT IT")
                        self.profileButton.image = image
                    }
                })
            }
        }
        
        lunchBoxButton.image = UIImage(named: "lunchbox_add.png")
        lunchBoxButton.addGestureRecognizer(lunchBoxGesture)
        
        if user == currentNote.noteAuthor {
            lunchBoxButton.image = UIImage(named: "notetrash.png")
            profileButton.userInteractionEnabled = false
        } else {
            profileButton.userInteractionEnabled = true
            profileButton.addGestureRecognizer(profileGesture)
        }
        
        lunchboxNote.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.value as? NSNull == nil {
                self.lunchBoxButton.image = UIImage(named: "lunchbox_added.png")
            }
        })
        
        noteLabel.text = "\"" + note.note + "\""
        dateLabel.text = note.noteDate
    }
    
    func lunchBoxGesturePressed() {
        if user == currentNote.noteAuthor {
            deleteTapped(lunchBoxGesture)
        } else {
            lunchTapped(lunchBoxGesture)
        }
    }
    
    func lunchTapped(sender: UITapGestureRecognizer) {
        
        lunchboxNote.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            //If it isn't in my lunchbox add it, if it is delete it.
            if snapshot.value as? NSNull != nil {
                self.lunchboxNote.setValue(true)
                self.lunchBoxButton.image = UIImage(named: "lunchbox_added.png")
            } else {
                self.lunchboxNote.removeValue()
                self.lunchBoxButton.image = UIImage(named: "lunchbox_add.png")
            }
            
        })
    }
    
    /**
     Shows an alert when the user taps the delete button.
     
     - Parameter sender: The tap gesture.
     */
    func deleteTapped(sender: UITapGestureRecognizer) {
        if let delegate = deleteDelegate {
            delegate.showDeleteAlert(FirebaseClient.Constants.Database.REF_NOTES.child(currentNote.noteKey))
        }
    }
    
    func profileTapped(sender: UITapGestureRecognizer) {
        if let delegate = authorDelegate {
            delegate.showAuthorDetail(currentNote.noteAuthor)
        }
    }

}
