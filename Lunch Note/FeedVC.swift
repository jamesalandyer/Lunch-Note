//
//  FeedVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import AVFoundation

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, NoteCellAuthorDelegate, NoteCellDeleteDelegate {
    
    //Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //Properties
    var notes = [Note]()
    var notesLoaded = false
    var authorDetail: String!
    var userImage: String!
    var sndClick: AVAudioPlayer!

    //MARK: - Stack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.tabBarController?.delegate = self
        
        do {
            
            try sndClick = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("click", ofType: "wav")!))
            
            sndClick.volume = 0.5
            sndClick.prepareToPlay()
            
            try sndSwoosh = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("swoosh", ofType: "wav")!))
            
            sndSwoosh.volume = 1.0
            sndSwoosh.prepareToPlay()
            
        } catch {
            print("Could Not Load Sound")
        }
        
        setView()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loadNotes), name: "Block", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //If the user is logged in, load notes
        if FIRAuth.auth()?.currentUser != nil && FirebaseClient.sharedInstance.currentDisplayName != nil {
            loadNotes(nil)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //If the user is not logged in or doesn't have a display name, show the login screen
        if FIRAuth.auth()?.currentUser == nil || FirebaseClient.sharedInstance.currentDisplayName == nil {
            performSegueWithIdentifier("showLogin", sender: nil)
        }
        
        tableView.reloadData()
    }
    
    //MARK: - Actions
    
    /**
     Shows the post screen.
    */
    func postButtonPressed() {
        performSegueWithIdentifier("showPost", sender: nil)
    }
    
    /**
     Shows the logging out alert.
    */
    func logoutButtonPressed() {
        let action = UIAlertController(title: "Logging Out", message: "Are you sure that you want to log out?", preferredStyle: .Alert)
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let logout = UIAlertAction(title: "Logout", style: .Destructive) { (logout) in
            self.logout()
        }
        
        action.addAction(cancel)
        action.addAction(logout)
        
        let subview = action.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        alertContentView.backgroundColor = UIColor.whiteColor()
        alertContentView.layer.cornerRadius = 13
        
        presentViewController(action, animated: true, completion: nil)
        
        action.view.tintColor = UIColor.blackColor()
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
        //Set Center Image
        let imageView = navAnimation()
        self.navigationItem.titleView = imageView
        //Set Back Navigation Button
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        //Sets Post Button In Navigation
        let post = UIImage(named: "post_tab.png")
        let postButton = UIButton()
        postButton.setImage(post, forState: .Normal)
        postButton.frame = CGRectMake(0, 0, 28, 29)
        postButton.addTarget(self, action: #selector(postButtonPressed), forControlEvents: .TouchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = postButton
        //Sets Logout Button In Navigation
        self.navigationItem.rightBarButtonItem = rightBarButton
        let leftBarButton = UIBarButtonItem(title: "Logout", style: .Done, target: self, action: #selector(logoutButtonPressed))
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
    
    //MARK: - TabBar
    
    /**
     Plays the sound. If the sound is already playing it stops it and plays it again.
     */
    private func playSound() {
        if sndClick.playing {
            sndClick.stop()
        }
        
        sndClick.play()
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        playSound()
    }
    
    //MARK: - TableView
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //For iPads
        cell.backgroundColor = UIColor.clearColor()
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
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("NoteCell") as? NoteCell {
            
            cell.authorDelegate = self
            cell.deleteDelegate = self
            
            cell.configureCell(note)
            
            return cell
        } else {
            return NoteCell()
        }
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let note = notes[indexPath.row]
        
        let report = UITableViewRowAction(style: .Normal, title: "Report") { action, index in
            FirebaseClient.Constants.Database.REF_REPORTS.child(note.noteKey).setValue(true)
        }
        report.backgroundColor = lightRedColor
        
        return [report]
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let note = notes[indexPath.row]
        let currentUser = FirebaseClient.sharedInstance.currentUser
        
        if note.noteAuthor != currentUser {
            return true
        }
        
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    //MARK: - Retrieve Data
    
    /**
     Gets all of the notes for the feed.
     */
    func loadNotes(notif: NSNotification?) {
        if notif?.object != nil {
            notesLoaded = false
        }
        
        if !notesLoaded {
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
            
            FirebaseClient.Constants.Database.REF_NOTES.observeEventType(.Value, withBlock: { snapshot in
                FirebaseClient.sharedInstance.userReference.child("blocked").observeSingleEventOfType(.Value, withBlock: { snapshotBlock in
                    self.notes = []
                    var blocked = [String]()
                    
                    if let blockedUsers = snapshotBlock.children.allObjects as? [FIRDataSnapshot] {
                        for blockedUser in blockedUsers {
                            blocked.append(blockedUser.key)
                        }
                    }
                    
                    if let notes = snapshot.children.allObjects as? [FIRDataSnapshot] {
                        for note in notes {
                            if let noteDict = note.value as? Dictionary<String, AnyObject> {
                                let key = note.key
                                let note = Note(noteKey: key, dictionary: noteDict)
                                if blocked.count > 0 {
                                    for block in blocked {
                                        if block != note.noteAuthor {
                                            self.notes.insert(note, atIndex: 0)
                                        }
                                    }
                                } else {
                                    self.notes.insert(note, atIndex: 0)
                                }
                            }
                            self.tableView.reloadData()
                        }
                    }
                    
                    self.notesLoaded = true
                    
                    performUIUpdatesOnMain {
                        self.activityIndicator.hidden = true
                    }
                })
            })
        }
    }
    
    /**
     Logs the user out and shows the login screen.
    */
    private func logout() {
        do {
            try FIRAuth.auth()!.signOut()
            notesLoaded = false
            notes = []
            FirebaseClient.Constants.Database.REF_NOTES.removeAllObservers()
            tableView.reloadData()
            performSegueWithIdentifier("showLogin", sender: nil)
        } catch {
            showAlert("Unable To Logout", msg: "Please try logging out again.")
        }
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
            //Delete the note from the users profile and feed
            let notesInFeed = FirebaseClient.Constants.Database.REF_NOTES.child(note)
            notesInFeed.removeValue()
            let notesInProfile = FirebaseClient.sharedInstance.notesReference.child(note)
            notesInProfile.removeValue()
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
    
    //MARK: - Segue
    
    /**
     Shows the author's profile page.
     
     - Parameter author: The string uid of the current author.
     - Parameter image: The string url of the author's image.
     */
    func showAuthorDetail(author: String, image: String) {
        authorDetail = author
        userImage = image
        performSegueWithIdentifier("showFeedDetail", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFeedDetail" {
            if let controller = segue.destinationViewController as? DetailVC {
                controller.detailForUser = authorDetail
                controller.imageForUser = userImage
            }
        }
    }

}

