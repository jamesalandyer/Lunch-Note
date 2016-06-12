//
//  CustomCircleView.swift
//  Lunch Note
//
//  Created by James Dyer on 6/11/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit

class CustomCircleView: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = layer.frame.size.width / 2
    }

}
