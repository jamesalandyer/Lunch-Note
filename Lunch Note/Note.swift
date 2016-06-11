//
//  Note.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import Foundation

class Note {
    
    //Properties
    private var _note: String!
    private var _noteDate: String!
    private var _noteAuthor: String!
    private var _noteAuthorImage: String!
    private var _noteKey: String!
    
    var noteKey: String {
        return _noteKey
    }
    
    var note: String {
        return _note
    }
    
    var noteDate: String {
        return _noteDate
    }
    
    var noteAuthor: String {
        return _noteAuthor
    }
    
    var noteAuthorImage: String {
        return _noteAuthorImage
    }
    
    init(noteKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._noteKey = noteKey
        
        if let date = dictionary["date"] as? String {
            self._noteDate = date.uppercaseString
        }
        
        if let note = dictionary["note"] as? String {
            self._note = note
        }
        
        if let author = dictionary["author"] as? String {
            self._noteAuthor = author
        }
        
        if let authorImage = dictionary["authorImage"] as? String {
            self._noteAuthorImage = authorImage
        }
    }
}