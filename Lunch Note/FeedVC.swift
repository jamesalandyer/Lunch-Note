//
//  FeedVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit

class FeedVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
        navigationController?.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: lightGreyColor], forState: .Normal)
        
        let logo = UIImage(named: "lunchbox_nav.png")
        let imageView = UIImageView(image: logo)
        self.navigationItem.titleView = imageView
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        //Sets Post Button In Navigation
        let post = UIImage(named: "post_tab.png")
        let navButton = UIButton()
        navButton.setImage(post, forState: .Normal)
        navButton.frame = CGRectMake(0, 0, 28, 29)
        navButton.addTarget(self, action: #selector(postButtonPressed), forControlEvents: .TouchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = navButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        let leftBarButton = UIBarButtonItem(title: "Logout", style: .Done, target: self, action: #selector(postButtonPressed))
        leftBarButton.tintColor = lightRedColor
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func postButtonPressed() {
        
    }


}

