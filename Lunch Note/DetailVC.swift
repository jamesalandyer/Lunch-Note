//
//  DetailVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import Firebase

class DetailVC: UIViewController, UITableViewDelegate, UITableViewDataSource, NoteCellDeleteDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mainProfileImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var detailForUser: String!
    var imageForUser: String!
    var notes = [Note]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        getUserData()
    }
    
    //MARK: - TableView
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
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
            
            cell.deleteDelegate = self
            
            cell.configureCell(note)
            
            return cell
        } else {
            return ProfileCell()
        }
    }
    
    private func getUserData() {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        if imageForUser != nil && imageForUser != DEFAULT_PICTURE {
            if let cachedImage = FirebaseClient.Constants.LocalImages.imageCache.objectForKey(detailForUser) as? UIImage {
                mainProfileImageView.image = cachedImage
            } else {
                let imageReference = FIRStorage.storage().referenceForURL(imageForUser)
                FirebaseClient.sharedInstance.downloadImage(imageForUser, url: imageReference, completionHandler: { (result) in
                    if let image = result {
                        self.mainProfileImageView.image = image
                        self.tableView.reloadData()
                    }
                })
            }
        }
        
        FirebaseClient.Constants.Database.REF_USERS.child(detailForUser).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let dataDict = snapshot.value as? Dictionary<String, AnyObject> {
                if let displayName = dataDict["displayName"] as? String {
                    self.navigationItem.title = displayName
                }
                if let notesDict = dataDict["notes"] as? Dictionary<String, AnyObject> {
                    let notes = Array(notesDict.keys)
                    self.loadNotes(notes)
                }
            } else {
                self.showAlert("Unable To Download Data", msg: "Please try again.")
                self.activityIndicator.hidden = true
            }
        })
    }
    
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
    
    private func showAlert(title: String, msg: String) {
        let action = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        
        action.addAction(ok)
        presentViewController(action, animated: true, completion: nil)
    }
    
    func showDeleteAlert(note: FIRDatabaseReference) {
        let deleteController = UIAlertController(title: "Delete This Post?", message: "Are you sure you want to delete this post? This action cannot be undone.", preferredStyle: .Alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
            note.removeValue()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        deleteController.addAction(deleteAction)
        deleteController.addAction(cancelAction)
        
        presentViewController(deleteController, animated: true, completion: nil)
    }

}
