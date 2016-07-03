//
//  DetailVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import Firebase

class DetailVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mainProfileImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noNotesLabel: UILabel!
    
    //Properties
    var detailForUser: String!
    var imageForUser: String!
    var notes = [Note]()
    
    //MARK: - Stack
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setNavigation()
        getUserData()
    }
    
    //MARK: - Adjusting UI
    
    private func setNavigation() {
        //Sets Block Button In Navigation
        let rightBarButton = UIBarButtonItem(title: "Block", style: .Done, target: self, action: #selector(showBlockAlert))
        rightBarButton.tintColor = lightRedColor
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    //MARK: - TableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let note = notes[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("ProfileCell") as? ProfileCell {
            
            cell.configureCell(note)
            
            return cell
        } else {
            return ProfileCell()
        }
    }
    
    //MARK: - Retrieve Data
    
    /**
     Gets the user's current profile image, notes, and display name.
     */
    private func getUserData() {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        if imageForUser != nil && imageForUser != DEFAULT_PICTURE {
            //Check cache
            if let cachedImage = FirebaseClient.Constants.LocalImages.imageCache.objectForKey(detailForUser) as? UIImage {
                mainProfileImageView.image = cachedImage
            } else {
                //If not in cache, download it
                let imageReference = FIRStorage.storage().referenceForURL(imageForUser)
                FirebaseClient.sharedInstance.downloadImage(detailForUser, url: imageReference, completionHandler: { (result) in
                    if let image = result {
                        self.mainProfileImageView.image = image
                        self.tableView.reloadData()
                    }
                })
            }
        }
        
        FirebaseClient.Constants.Database.REF_USERS.child(detailForUser).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            self.notes = []
            
            if let dataDict = snapshot.value as? Dictionary<String, AnyObject> {
                if let displayName = dataDict["displayName"] as? String {
                    self.navigationItem.title = displayName
                }
                if let notesDict = dataDict["notes"] as? Dictionary<String, AnyObject> {
                    let notes = Array(notesDict.keys)
                    self.loadNotes(notes)
                    self.noNotesLabel.hidden = true
                } else {
                    //No notes
                    self.noNotesLabel.hidden = false
                    self.activityIndicator.hidden = true
                    self.tableView.reloadData()
                }
            } else {
                self.activityIndicator.hidden = true
                self.noNotesLabel.hidden = false
                self.showAlert("Unable To Download Data", msg: "Please try again.")
            }
        })
    }
    
    /**
     Gets the user's notes data.
     
     - Parameter notes: The array of the keys for the user's notes.
     */
    private func loadNotes(notes: [String]) {
        for note in notes {
            FirebaseClient.Constants.Database.REF_NOTES.child(note).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let noteDict = snapshot.value as? Dictionary<String, AnyObject> {
                    let key = note
                    let note = Note(noteKey: key, dictionary: noteDict)
                    self.notes.insert(note, atIndex: 0)
                }
                self.tableView.reloadData()
            })
        }
        self.activityIndicator.hidden = true
    }
    
    //MARK: - Alerts
    
    /**
     Shows an alert to the user.
     
     - Parameter title: The header of the alert.
     - Parameter msg: The message of the alert.
     */
    private func showAlert(title: String, msg: String) {
        let action = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        
        action.addAction(ok)
        
        let subview = action.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        alertContentView.backgroundColor = UIColor.whiteColor()
        alertContentView.layer.cornerRadius = 13
        
        presentViewController(action, animated: true, completion: nil)
        
        action.view.tintColor = UIColor.blackColor()
    }
    
    /**
     Shows a block alert to the user.
     */
    func showBlockAlert() {
        let deleteController = UIAlertController(title: "Block This User?", message: "Are you sure you want to block this user? This action cannot be undone.", preferredStyle: .Alert)
        
        let deleteAction = UIAlertAction(title: "Block", style: .Destructive, handler: { action in
            //Delete note from the feed and user profile
            FirebaseClient.sharedInstance.blockUserReference.child(self.detailForUser).setValue(true)
            
            FirebaseClient.sharedInstance.lunchBoxReference.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let lunchNotes = snapshot.children.allObjects as? [FIRDataSnapshot] {
                    for lunchNote in lunchNotes {
                        for note in self.notes {
                            if lunchNote.key == note.noteKey {
                                FirebaseClient.sharedInstance.lunchBoxReference.child(lunchNote.key).removeValue()
                            }
                        }
                    }
                    
                    performUIUpdatesOnMain {
                        NSNotificationCenter.defaultCenter().postNotificationName("Block", object: true)
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }
            })
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        deleteController.addAction(deleteAction)
        deleteController.addAction(cancelAction)
        
        let subview = deleteController.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        alertContentView.backgroundColor = UIColor.whiteColor()
        alertContentView.layer.cornerRadius = 13
        
        presentViewController(deleteController, animated: true, completion: nil)
        
        deleteController.view.tintColor = UIColor.blackColor()
    }

}
