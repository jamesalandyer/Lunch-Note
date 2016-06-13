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

func getMonth(month: Int) -> String {
    switch month {
    case 1:
        return "JANUARY"
    case 2:
        return "FEBRUARY"
    case 3:
        return "MARCH"
    case 4:
        return "APRIL"
    case 5:
        return "MAY"
    case 6:
        return "JUNE"
    case 7:
        return "JULY"
    case 8:
        return "AUGUST"
    case 9:
        return "SEPTEMBER"
    case 10:
        return "OCTOBER"
    case 11:
        return "NOVEMBER"
    case 12:
        return "DECEMBER"
    default:
        return ""
    }
}

func isValidEmail(testStr:String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(testStr)
}

//Switchs to the main queue to update UI
func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}