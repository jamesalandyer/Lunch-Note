//
//  NoteCellDelegate.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import Foundation
import Firebase

protocol NoteCellAuthorDelegate {
    /**
     Shows the author's profile page.
     
     - Parameter author: The string uid of the current author.
     - Parameter image: The string url of the author's image.
    */
    func showAuthorDetail(author: String, image: String)
}

protocol NoteCellDeleteDelegate {
    /**
     Shows the delete alert to delete a note and delete it.
     
     - Parameter note: The string of the note key.
    */
    func showDeleteAlert(note: String)
}