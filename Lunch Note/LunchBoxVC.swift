//
//  LunchBoxVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import Firebase

class LunchBoxVC: UIViewController, UITableViewDelegate, UITableViewDataSource, NoteCellAuthorDelegate {

    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noNotesStackView: UIStackView!
    
    var lunchbox: [String]?
    var notes = [Note]()
    var authorDetail: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        setNavigation()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        getCurrentLunchbox { (success) in
            if self.lunchbox != nil {
                self.loadNotes()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        FirebaseClient.sharedInstance.lunchBoxReference.removeAllObservers()
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
        let lunchbox = UIImage(named: "lunchbox_selected.png")
        let lunchboxButton = UIButton()
        lunchboxButton.setImage(lunchbox, forState: .Normal)
        lunchboxButton.frame = CGRectMake(0, 0, 34, 28)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = lunchboxButton
        navigationItem.rightBarButtonItem = rightBarButton
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
            
            cell.configureCell(note)
            
            return cell
        } else {
            return NoteCell()
        }
    }
    
    private func getCurrentLunchbox(completionHandler: (success: Bool) -> Void) {
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
        noNotesStackView.hidden = true
        
        FirebaseClient.sharedInstance.lunchBoxReference.observeSingleEventOfType(.Value, withBlock: { snapshot in
            self.notes = []
            
            if let dict = snapshot.value as? Dictionary<String, AnyObject> {
                self.lunchbox = Array(dict.keys)
                
                completionHandler(success: true)
            } else {
                self.tableView.reloadData()
                self.activityIndicator.hidden = true
                self.noNotesStackView.hidden = false
            }
        })
    }
    
    private func loadNotes() {
        
        for lunch in lunchbox! {
            FirebaseClient.Constants.Database.REF_NOTES.child(lunch).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let noteDict = snapshot.value as? Dictionary<String, AnyObject> {
                    let note = Note(noteKey: lunch, dictionary: noteDict)
                    self.notes.insert(note, atIndex: 0)
                    self.tableView.reloadData()
                }
            })
        }
        tableView.reloadData()
        activityIndicator.hidden = true
    }
    
    func showAuthorDetail(author: String, image: String) {
        authorDetail = author
        performSegueWithIdentifier("showLunchboxDetail", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showLunchboxDetail" {
            if let controller = segue.destinationViewController as? DetailVC {
                controller.detailForUser = authorDetail
            }
        }
    }

}
