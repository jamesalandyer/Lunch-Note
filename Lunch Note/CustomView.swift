//
//  CustomView.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit

class CustomView: UIView {
    
    let borderColor: CGFloat = 139.0 / 255.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 10.0
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(red: borderColor, green: borderColor, blue: borderColor, alpha: 1.0).CGColor
    }
    
}
