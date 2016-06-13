//
//  NoteCellDelegate.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol NoteCellAuthorDelegate {
    func showAuthorDetail(author: String, image: String)
}

protocol NoteCellDeleteDelegate {
    func showDeleteAlert(note: String)
}