//
//  FeedVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import FirebaseDatabase

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        FirebaseClient.Constants.Database.REF_NOTES.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            print(snapshot)
        })
        
        setView()
    }
    
    func setView() {
        setNavigation()
        setTabBar()
    }
    
    func setNavigation() {
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
        let leftBarButton = UIBarButtonItem(title: "Logout", style: .Done, target: self, action: #selector(postButtonPressed))
        leftBarButton.tintColor = lightRedColor
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func setTabBar() {
        //Set Title Colors
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: lightGreyColor], forState: .Normal)
    }
    
    //MARK: - TableView
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("NoteCell") as? NoteCell {
            
            return cell
        } else {
            return NoteCell()
        }
    }
    
    func postButtonPressed() {
        
    }


}

