//
//  CustomImageView.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit

class CustomImageView: UIImageView {

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = layer.frame.size.width / 2
    }

}
