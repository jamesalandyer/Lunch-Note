//
//  DataService.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import Foundation

class DataService {
    
    static let sharedInstance = DataService()
    
    private var _uid: String = EMPTY
    private var _displayName: String = EMPTY
    private var _photoURL: NSURL!
    
    var uid: String {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey("uid") ?? _uid
        }
        set {
            _uid = newValue
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "uid")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var displayName: String {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey("displayName") ?? _displayName
        }
        set {
            _displayName = newValue
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "displayName")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var photoURL: NSURL? {
        if let savedPhotoURL = NSUserDefaults.standardUserDefaults().URLForKey("photoURL") {
            return savedPhotoURL
        } else if let photoURL = _photoURL {
            return photoURL
        }
        
        return nil
    }
    
    func setPhotoURL(url: NSURL) {
        _photoURL = url
        NSUserDefaults.standardUserDefaults().setURL(url, forKey: "photoURL")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func deletePhotoURL() {
        _photoURL = nil
        NSUserDefaults.standardUserDefaults().removeObjectForKey("photoURL")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func deleteDisplayName() {
        _displayName = EMPTY
        NSUserDefaults.standardUserDefaults().removeObjectForKey("displayName")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func deleteUid() {
        _uid = EMPTY
        NSUserDefaults.standardUserDefaults().removeObjectForKey("uid")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func logoutUser() {
        deletePhotoURL()
        deleteDisplayName()
        deleteUid()
    }
    
}