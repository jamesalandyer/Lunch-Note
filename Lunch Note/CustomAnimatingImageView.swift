//
//  CustomAnimatingImageView.swift
//  Lunch Note
//
//  Created by James Dyer on 6/14/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit

class CustomAnimatingImageView: UIImageView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgAnimation()
    }
    
    func imgAnimation() {
        
        self.image = UIImage(named: "lunchbox_load_login.png")
        
        self.animationImages = nil
        
        var imgArray = [UIImage]()
        
        let img = UIImage(named: "lunchbox_load_login.png")
        let img2 = UIImage(named: "lunchbox_load_login2.png")
        let img3 = UIImage(named: "lunchbox_load_login3.png")
        imgArray.append(img!)
        imgArray.append(img2!)
        imgArray.append(img3!)
        
        self.animationImages = imgArray
        self.animationDuration = 3.0
        self.animationRepeatCount = 0
        self.startAnimating()
        
    }

}
