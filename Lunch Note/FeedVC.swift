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

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, NoteCellAuthorDelegate, NoteCellDeleteDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var notes = [Note]()
    var notesLoaded = false
    var authorDetail: String!
    var userImage: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if FIRAuth.auth()?.currentUser != nil && FirebaseClient.sharedInstance.currentDisplayName != nil {
            loadNotes()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if FIRAuth.auth()?.currentUser == nil || FirebaseClient.sharedInstance.currentDisplayName == nil {
            performSegueWithIdentifier("showLogin", sender: nil)
        }
        
        tableView.reloadData()
    }
    
    private func setView() {
        setNavigation()
        setTabBar()
    }
    
    private func setNavigation() {
        //Set Center Image
        let logo = UIImage(named: "lunchbox_nav.png")
        let imageView = UIImageView(image: logo)
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
    
    private func setTabBar() {
        //Set Title Colors
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: lightGreyColor], forState: .Normal)
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
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("NoteCell") as? NoteCell {
            
            cell.authorDelegate = self
            cell.deleteDelegate = self
            
            cell.configureCell(note)
            
            return cell
        } else {
            return NoteCell()
        }
    }
    
    func postButtonPressed() {
        performSegueWithIdentifier("showPost", sender: nil)
    }
    
    func logoutButtonPressed() {
        let action = UIAlertController(title: "Logging Out", message: "Are you sure that you want to log out?", preferredStyle: .Alert)
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let logout = UIAlertAction(title: "Logout", style: .Destructive) { (logout) in
            self.logout()
        }
        
        action.addAction(cancel)
        action.addAction(logout)
        
        presentViewController(action, animated: true, completion: nil)
    }
    
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
    
    private func showAlert(title: String, msg: String) {
        let action = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        
        action.addAction(ok)
        presentViewController(action, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //For iPads
        cell.backgroundColor = UIColor.clearColor()
    }
    
    private func loadNotes() {
        if !notesLoaded {
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
            
            FirebaseClient.Constants.Database.REF_NOTES.observeEventType(.Value, withBlock: { snapshot in
                self.notes = []
                
                if let notes = snapshot.children.allObjects as? [FIRDataSnapshot] {
                    for note in notes {
                        if let noteDict = note.value as? Dictionary<String, AnyObject> {
                            let key = note.key
                            let note = Note(noteKey: key, dictionary: noteDict)
                            self.notes.insert(note, atIndex: 0)
                        }
                        self.tableView.reloadData()
                    }
                }
                self.activityIndicator.hidden = true
                self.notesLoaded = true
            })
        }
    }
    
    func showDeleteAlert(note: String) {
        let deleteController = UIAlertController(title: "Delete This Post?", message: "Are you sure you want to delete this post? This action cannot be undone.", preferredStyle: .Alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
            let notesInFeed = FirebaseClient.Constants.Database.REF_NOTES.child(note)
            notesInFeed.removeValue()
            let notesInProfile = FirebaseClient.sharedInstance.notesReference.child(note)
            notesInProfile.removeValue()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        deleteController.addAction(deleteAction)
        deleteController.addAction(cancelAction)
        
        presentViewController(deleteController, animated: true, completion: nil)
    }
    
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

