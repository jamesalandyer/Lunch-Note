//
//  ProfileCell.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import Firebase

class ProfileCell: UITableViewCell {

    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var lunchBoxButton: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var profileImageView: CustomImageView!
    
    private var user: String {
        return FirebaseClient.sharedInstance.currentUser!
    }
    
    private var currentNote: Note!
    private var lunchBoxGesture: UITapGestureRecognizer!
    private var lunchboxNote: FIRDatabaseReference!
    
    var deleteDelegate: NoteCellDeleteDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lunchBoxGesture = UITapGestureRecognizer(target: self, action: #selector(lunchBoxGesturePressed))
        lunchBoxGesture.numberOfTapsRequired = 1
        lunchBoxButton.userInteractionEnabled = true
    }
    
    func configureCell(note: Note) {
        currentNote = note
        lunchboxNote = FirebaseClient.sharedInstance.lunchBoxReference.child(currentNote.noteKey)
        
        profileImageView.image = UIImage(named: "defaultpicture.png")
        
        if currentNote.noteAuthorImage != DEFAULT_PICTURE {
            if let cachedImage = FirebaseClient.Constants.LocalImages.imageCache.objectForKey(note.noteAuthor) as? UIImage {
                self.profileImageView.image = cachedImage
            }
        }
        
        lunchBoxButton.image = UIImage(named: "lunchbox_add.png")
        lunchBoxButton.addGestureRecognizer(lunchBoxGesture)
        
        if user == currentNote.noteAuthor {
            lunchBoxButton.image = UIImage(named: "notetrash.png")
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
            delegate.showDeleteAlert(currentNote.noteKey)
        }
    }

}
