//
//  PostVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import Firebase

class PostVC: UIViewController, UITextViewDelegate {

    //Outlets
    @IBOutlet weak private var enterMessageStackView: UIStackView!
    @IBOutlet weak private var postLogoImageView: UIImageView!
    @IBOutlet weak private var messageTextView: CustomTextView!
    @IBOutlet weak private var buttonStackView: UIStackView!
    @IBOutlet weak var inspireButton: CustomButton!
    
    //Properties
    private let defaultText = "Enter Inspiration"
    
    //MARK: - Stack
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messageTextView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        subscribeToKeyboardNotifications()
        inspireEnabled(false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromKeyboardNotifications()
    }
    
    //MARK: - Actions
    
    @IBAction func inspireButtonPressed(sender: AnyObject) {
        postToFirebase()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - Adjusting UI
    
    /**
     Sets the inspire button.
     
     - Parameter enable: A Bool of whether the button is enabled.
    */
    private func inspireEnabled(enable: Bool) {
        inspireButton.enabled = enable
        inspireButton.alpha = enable ? 1.0 : 0.5
    }
    
    //MARK: - Post
    
    /**
     Gets the current date when called.
     
     - Returns: The string of the current date.
    */
    private func getCurrentDate() -> String {
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Day , .Month , .Year], fromDate: date)
        let month = getMonth(components.month)
        let today = "\(month) \(components.day), \(components.year)"
        
        return today
    }
    
    /**
     Posts the note to the firebase database.
     */
    func postToFirebase() {
        if let currentUser = FirebaseClient.sharedInstance.currentUser {
            let post: Dictionary<String, AnyObject> = [
                "note": "\(messageTextView.text)",
                "date": getCurrentDate(),
                "author": currentUser,
                "authorImage": FirebaseClient.sharedInstance.currentUserImage
                ]
            
            let firebasePost = FirebaseClient.Constants.Database.REF_NOTES.childByAutoId()
            firebasePost.setValue(post)
            let postId = firebasePost.key
            let userPosts = FirebaseClient.sharedInstance.notesReference.child(postId)
            userPosts.setValue(true)
        }
    }
    
    //MARK: - TextView
    
    func textViewDidBeginEditing(textView: UITextView) {
        //If the user has entered anything, clear the text
        if textView.text == defaultText {
            textView.text = ""
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        //If the default text isn't in the text view, allow the user to post
        if messageTextView.text != defaultText {
            inspireEnabled(true)
        } else {
            inspireEnabled(false)
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        //Rules for setting the display name
        if range.length == 1 {
            return true
        }
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else if textView.text.characters.count > 180 {
            return false
        }
        
        return true
    }
    
    //MARK: - Touches
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if messageTextView.text == "" {
            messageTextView.text = defaultText
        }
        
        messageTextView.resignFirstResponder()
    }
    
    //MARK: - Keyboard
    
    /**
     Subscribes to the keyboard will show and hide notifications.
     */
    private func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    /**
     Unsubscribes from the keyboard will show and hide notifications.
     */
    private func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    /**
     Adjusts the screen when the keyboard shows and hides the top button.
     
     - Parameter notification: The notification being passed through.
     */
    func keyboardWillShow(notification: NSNotification) {
        postLogoImageView.hidden = true
        view.frame.origin.y = getKeyboardHeight(notification) * -0.5
    }
    
    /**
     Adjusts the screen when the keyboard hides and shows the top button.
     
     - Parameter notification: The notification being passed through.
     */
    func keyboardWillHide(notification: NSNotification) {
        postLogoImageView.hidden = false
        view.frame.origin.y = 0
    }
    
    /**
     Gets the users keyboard height.
     
     - Parameter notification: The notification being passed through.
     */
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }

}
