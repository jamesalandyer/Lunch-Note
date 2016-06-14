//
//  CustomNavigationAnimation.swift
//  Lunch Note
//
//  Created by James Dyer on 6/14/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import Foundation

func navAnimation() -> UIImageView {
    
    let image = UIImage(named: "lunchbox_nav.png")
    let imageView = UIImageView(image: image!)
    
    imageView.animationImages = nil
    
    var imgArray = [UIImage]()
    
    let img = UIImage(named: "lunchbox_nav.png")
    let img2 = UIImage(named: "lunchbox_nav2.png")
    let img3 = UIImage(named: "lunchbox_nav3.png")
    imgArray.append(img!)
    imgArray.append(img2!)
    imgArray.append(img3!)
    
    imageView.animationImages = imgArray
    imageView.animationDuration = 3.0
    imageView.animationRepeatCount = 0
    imageView.startAnimating()
    
    return imageView
}