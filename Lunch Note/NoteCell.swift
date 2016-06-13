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

    //Outlets
    @IBOutlet weak private var noteLabel: UILabel!
    @IBOutlet weak private var lunchBoxButton: UIImageView!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var profileButton: CustomImageView!
    
    //Properties
    private var user: String {
        return FirebaseClient.sharedInstance.currentUser!
    }
    
    private var currentNote: Note!
    
    var authorDelegate: NoteCellAuthorDelegate!
    var deleteDelegate: NoteCellDeleteDelegate!
    
    private var lunchBoxGesture: UITapGestureRecognizer!
    private var profileGesture: UITapGestureRecognizer!
    
    private var lunchboxNote: FIRDatabaseReference!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lunchBoxGesture = UITapGestureRecognizer(target: self, action: #selector(lunchBoxGesturePressed))
        lunchBoxGesture.numberOfTapsRequired = 1
        profileGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped(_:)))
        profileGesture.numberOfTapsRequired = 1
        
        lunchBoxButton.userInteractionEnabled = true
    }
    
    /**
     Configures the cell based on the note for the cell.
     
     - Parameter note: The note for the cell.
     */
    func configureCell(note: Note) {
        currentNote = note
        lunchboxNote = FirebaseClient.sharedInstance.lunchBoxReference.child(note.noteKey)
        
        profileButton.image = UIImage(named: "defaultpicture.png")
        
        if currentNote.noteAuthorImage != DEFAULT_PICTURE {
            if let cachedImage = FirebaseClient.Constants.LocalImages.imageCache.objectForKey(note.noteAuthor) as? UIImage {
                self.profileButton.image = cachedImage
            } else {
                let imageReference = FIRStorage.storage().referenceForURL(currentNote.noteAuthorImage)
                FirebaseClient.sharedInstance.downloadImage(currentNote.noteAuthor, url: imageReference, completionHandler: { (result) in
                    if let image = result {
                        self.profileButton.image = image
                    }
                })
            }
        }
        
        lunchBoxButton.addGestureRecognizer(lunchBoxGesture)
        
        if user == currentNote.noteAuthor {
            lunchBoxButton.image = UIImage(named: "notetrash.png")
            profileButton.userInteractionEnabled = false
        } else {
            lunchboxNote.observeSingleEventOfType(.Value, withBlock: { snapshot in
                if snapshot.value as? NSNull == nil {
                    self.lunchBoxButton.image = UIImage(named: "lunchbox_added.png")
                } else {
                    self.lunchBoxButton.image = UIImage(named: "lunchbox_add.png")
                }
            })
            profileButton.userInteractionEnabled = true
            profileButton.addGestureRecognizer(profileGesture)
        }
        
        noteLabel.text = "\"" + note.note + "\""
        dateLabel.text = note.noteDate
    }
    
    /**
     Selects what type of tap it is based on if the user made the note.
     */
    func lunchBoxGesturePressed() {
        if user == currentNote.noteAuthor {
            deleteTapped(lunchBoxGesture)
        } else {
            lunchTapped(lunchBoxGesture)
        }
    }
    
    /**
     Adjusts the users lunchbox when tapped.
     
     - Parameter sender: The tap gesture.
     */
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
            delegate.showDeleteAlert(currentNote.noteKey)
        }
    }
    
    /**
     Shows the author detail screen when the user taps the button.
     
     - Parameter sender: The tap gesture.
     */
    func profileTapped(sender: UITapGestureRecognizer) {
        if let delegate = authorDelegate {
            delegate.showAuthorDetail(currentNote.noteAuthor, image: currentNote.noteAuthorImage)
        }
    }

}
