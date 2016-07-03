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
    
    //Outlets
    @IBOutlet weak var mainProfileImageView: CustomImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noNotesLabel: UILabel!
    
    //Properties
    var notes = [Note]()
    
    //MARK: - Stack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //If the user is logged in, get data
        if FIRAuth.auth()?.currentUser != nil {
            let displayName = FirebaseClient.sharedInstance.currentDisplayName!
            self.navigationItem.title = displayName.uppercaseString
            
            getUserData()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //If the user is logged out, show login screen and switch to feed tab
        if FIRAuth.auth()?.currentUser == nil {
            performSegueWithIdentifier("showLogout", sender: nil)
            self.navigationController?.tabBarController?.selectedIndex = 0
        }
    }
    
    //MARK: - Actions
    
    /**
     Shows the edit screen.
     */
    func editButtonPressed() {
        performSegueWithIdentifier("showEdit", sender: nil)
    }
    
    /**
     Shows the lunchbox screen.
     */
    func lunchboxButtonPressed() {
        performSegueWithIdentifier("showLunchbox", sender: nil)
    }
    
    //MARK: - Adjusting UI
    
    /**
     Sets the navigation and tab bar.
    */
    private func setView() {
        setNavigation()
        setTabBar()
    }
    
    /**
     Sets the navigation back button, lunchbox button, and edit button.
     */
    private func setNavigation() {
        //Set Back Navigation Button
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        //Sets Lunchbox Button In Navigation
        let lunchbox = UIImage(named: "lunchbox_unselected.png")
        let lunchboxButton = UIButton()
        lunchboxButton.setImage(lunchbox, forState: .Normal)
        lunchboxButton.frame = CGRectMake(0, 0, 34, 28)
        lunchboxButton.addTarget(self, action: #selector(lunchboxButtonPressed), forControlEvents: .TouchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = lunchboxButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        //Sets Edit Button In Navigation
        let leftBarButton = UIBarButtonItem(title: "Edit", style: .Done, target: self, action: #selector(editButtonPressed))
        leftBarButton.tintColor = lightRedColor
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    /**
     Sets the tab bar text color.
     */
    private func setTabBar() {
        //Set Title Colors
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: lightGreyColor], forState: .Normal)
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
            
            cell.deleteDelegate = self
            
            cell.configureCell(note)
            
            return cell
        } else {
            return ProfileCell()
        }
    }
    
    //MARK: - Retrieve Data
    
    /**
     Gets the user's  current profile image and notes.
     */
    private func getUserData() {
        self.noNotesLabel.hidden = true
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        if FirebaseClient.sharedInstance.currentUserImage != DEFAULT_PICTURE {
            //Check cache
            if let cachedImage = FirebaseClient.Constants.LocalImages.imageCache.objectForKey(FirebaseClient.sharedInstance.currentUser!) as? UIImage {
                mainProfileImageView.image = cachedImage
            } else {
                //If not in chache, download it
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
                    //No notes
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
     Shows an delete alert to the user.
     
     - Parameter note: The key to the note the user wants to delete.
     */
    func showDeleteAlert(note: String) {
        let deleteController = UIAlertController(title: "Delete This Post?", message: "Are you sure you want to delete this post? This action cannot be undone.", preferredStyle: .Alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
            //Delete note from the feed and user profile
            let notesInFeed = FirebaseClient.Constants.Database.REF_NOTES.child(note)
            notesInFeed.removeValue()
            let notesInProfile = FirebaseClient.sharedInstance.notesReference.child(note)
            notesInProfile.removeValue()
            self.getUserData()
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
