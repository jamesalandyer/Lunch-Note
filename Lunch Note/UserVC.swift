//
//  UserVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import Firebase

class UserVC: UIViewController, UITableViewDelegate, UITableViewDataSource, NoteCellDeleteDelegate {
    
    @IBOutlet weak var mainProfileImageView: CustomImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noNotesLabel: UILabel!
    
    var notes = [Note]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if FIRAuth.auth()?.currentUser != nil {
            let displayName = FirebaseClient.sharedInstance.currentDisplayName!
            self.navigationItem.title = displayName.uppercaseString
            
            getUserData()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if FIRAuth.auth()?.currentUser == nil {
            performSegueWithIdentifier("showLogout", sender: nil)
            self.navigationController?.tabBarController?.selectedIndex = 0
        }
    }
    
    private func setView() {
        setNavigation()
        setTabBar()
    }
    
    private func setNavigation() {
        //Set Back Navigation Button
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        //Sets Post Button In Navigation
        let lunchbox = UIImage(named: "lunchbox_unselected.png")
        let lunchboxButton = UIButton()
        lunchboxButton.setImage(lunchbox, forState: .Normal)
        lunchboxButton.frame = CGRectMake(0, 0, 34, 28)
        lunchboxButton.addTarget(self, action: #selector(lunchboxButtonPressed), forControlEvents: .TouchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = lunchboxButton
        //Sets Logout Button In Navigation
        self.navigationItem.rightBarButtonItem = rightBarButton
        let leftBarButton = UIBarButtonItem(title: "Edit", style: .Done, target: self, action: #selector(editButtonPressed))
        leftBarButton.tintColor = lightRedColor
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    private func setTabBar() {
        //Set Title Colors
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: lightGreyColor], forState: .Normal)
    }
    
    func editButtonPressed() {
        performSegueWithIdentifier("showEdit", sender: nil)
    }
    
    func lunchboxButtonPressed() {
        performSegueWithIdentifier("showLunchbox", sender: nil)
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
        self.noNotesLabel.hidden = true
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        if FirebaseClient.sharedInstance.currentUserImage != DEFAULT_PICTURE {
            if let cachedImage = FirebaseClient.Constants.LocalImages.imageCache.objectForKey(FirebaseClient.sharedInstance.currentUser!) as? UIImage {
                mainProfileImageView.image = cachedImage
            } else {
                let imageReference = FIRStorage.storage().referenceForURL(FirebaseClient.sharedInstance.currentUserImage)
                FirebaseClient.sharedInstance.downloadImage(FirebaseClient.sharedInstance.currentUser!, url: imageReference, completionHandler: { (result) in
                    if let image = result {
                        self.mainProfileImageView.image = image
                        self.tableView.reloadData()
                    }
                })
            }
        } else {
            mainProfileImageView.image = UIImage(named: "defaultpicture_large.png")
        }
        
        FirebaseClient.sharedInstance.userReference.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let dataDict = snapshot.value as? Dictionary<String, AnyObject> {
                self.notes = []
                
                if let notesDict = dataDict["notes"] as? Dictionary<String, AnyObject> {
                    let notes = Array(notesDict.keys)
                    self.loadNotes(notes)
                } else {
                    self.noNotesLabel.hidden = false
                    self.activityIndicator.hidden = true
                    self.tableView.reloadData()
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
    
    func showDeleteAlert(note: String) {
        let deleteController = UIAlertController(title: "Delete This Post?", message: "Are you sure you want to delete this post? This action cannot be undone.", preferredStyle: .Alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
            let notesInFeed = FirebaseClient.Constants.Database.REF_NOTES.child(note)
            notesInFeed.removeValue()
            let notesInProfile = FirebaseClient.sharedInstance.notesReference.child(note)
            notesInProfile.removeValue()
            self.getUserData()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        deleteController.addAction(deleteAction)
        deleteController.addAction(cancelAction)
        
        presentViewController(deleteController, animated: true, completion: nil)
    }

}
