//
//  Constants.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit

let lightGreyColor = UIColor(red: 195 / 255, green: 195 / 255, blue: 195 / 255, alpha: 1.0)
let lightRedColor = UIColor(red: 255 / 255, green: 130 / 255, blue: 130 / 255, alpha: 1.0)

let EMPTY = "EMPTY"
let DEFAULT_PICTURE = "https://firebasestorage.googleapis.com/v0/b/lunchnote-bdd83.appspot.com/o/profilepictures%2Fdefaultpicture%403x.png?alt=media&token=278dc1ab-b638-44af-8738-b85a8b4a702a"

//Switchs to the main queue to update UI
func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}