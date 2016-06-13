//
//  LoginVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak private var emailTextField: UITextField!
    @IBOutlet weak private var passwordTextField: UITextField!
    @IBOutlet weak private var submitButton: CustomButton!
    @IBOutlet weak private var forgotButton: CustomButton!
    @IBOutlet weak private var logoImageView: UIImageView!
    @IBOutlet weak private var loginStackView: UIStackView!
    @IBOutlet weak private var onBoardStackView: UIStackView!
    @IBOutlet weak private var displayNameStackView: UIStackView!
    @IBOutlet weak private var nameTextField: UITextField!
    @IBOutlet weak private var nameButton: CustomButton!
    
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    private var userEmail: String!
    private var userPassword: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.delegate = self
        passwordTextField.delegate = self
        nameTextField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        if FirebaseClient.sharedInstance.currentUser != nil {
            if FirebaseClient.sharedInstance.currentDisplayName == nil {
                showOnBoardScreen(true)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }

    @IBAction func submitButtonPressed(sender: AnyObject) {
        dismissKeyboard()
        setUI(false)
        
        guard let email = emailTextField.text where email != "" else {
            showErrorAlert("No Email Address Entered", msg: "Please enter an email address.", createUser: false)
            return
        }
        
        guard isValidEmail(email) else {
            showErrorAlert("Invalid Email Address", msg: "Please double check your email address.", createUser: false)
            return
        }
        
        guard let password = passwordTextField.text where password != "" else {
            showErrorAlert("No Password Entered", msg: "Please enter a password.", createUser: false)
            return
        }
        
        userEmail = email
        userPassword = password
        
        FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (user, error) in
            
            if let err = error {
                performUIUpdatesOnMain {
                    if err.code == 17011 {
                        self.showErrorAlert("Account Doesn't Exist", msg: "Do you want to create a new account?", createUser: true)
                    } else if err.code == 17009 {
                        self.showErrorAlert("Invalid Password", msg: "Please check your password.", createUser: false)
                    } else if err.code == 17020 {
                        self.showErrorAlert("Request Timed Out", msg: "Please check your connection.", createUser: false)
                    } else {
                        self.showErrorAlert("Error", msg: "Please try again.", createUser: false)
                    }
                }
            } else {
                performUIUpdatesOnMain {
                    if let userInfo = user {
                        if userInfo.displayName != nil {
                            self.dismissViewControllerAnimated(true, completion: nil)
                        } else {
                            self.showOnBoardScreen(true)
                            self.setUI(true)
                        }
                    } else {
                        self.showErrorAlert("Unable To Retrieve Data", msg: "Please try logging in again.", createUser: false)
                    }
                }
            }
            
        })
        
        
    }
    
    @IBAction func forgotButtonPressed(sender: AnyObject) {
        setUI(false)
        
        guard let email = emailTextField.text where email != "" else {
            showErrorAlert("No Email Address Entered", msg: "Please enter an email address.", createUser: false)
            return
        }
        
        guard isValidEmail(email) else {
            showErrorAlert("Invalid Email Address", msg: "Please double check your email address.", createUser: false)
            return
        }
        
        FIRAuth.auth()?.sendPasswordResetWithEmail(email, completion: { error in
            if let err = error {
                performUIUpdatesOnMain {
                    if err.code == 17011 {
                        self.showErrorAlert("Account Doesn't Exist", msg: "Please double check your email address.", createUser: false)
                    } else if err.code == 17020 {
                        self.showErrorAlert("Request Timed Out", msg: "Please check your connection.", createUser: false)
                    } else {
                        self.showErrorAlert("Error", msg: "Please try again.", createUser: false)
                    }
                    self.setUI(true)
                }
            } else {
                performUIUpdatesOnMain {
                    self.showErrorAlert("Email Sent", msg: "Please check your email to reset your password.", createUser: false)
                }
            }
        })
    }
    
    @IBAction func nameButtonPressed(sender: AnyObject) {
        setUI(false)
        
        guard let displayName = nameTextField.text where displayName != "" else {
            showErrorAlert("Invalid Display Name", msg: "Please enter a display name.", createUser: false)
            return
        }
        
        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let changeRequest = user.profileChangeRequest()
            
            changeRequest.displayName = displayName.uppercaseString
            changeRequest.photoURL = NSURL(string: DEFAULT_PICTURE)
            
            changeRequest.commitChangesWithCompletion({ error in
                performUIUpdatesOnMain {
                    if error != nil {
                        self.showErrorAlert("Unable To Save Display Name", msg: "Please try again.", createUser: false)
                    } else {
                        FirebaseClient.sharedInstance.userReference.child("displayName").setValue(displayName.uppercaseString)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            })
        } else {
            showErrorAlert("Unable To Save Display Name", msg: "Please try again.", createUser: false)
        }
    }
    
    private func showErrorAlert(title: String, msg: String, createUser: Bool) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        
        if createUser {
            let action = UIAlertAction(title: "Create", style: .Default, handler: { (action) in
                self.createUser()
            })
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alert.addAction(cancel)
            alert.addAction(action)
        } else {
            let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(action)
        }
        
        presentViewController(alert, animated: true, completion: nil)
        
        setUI(true)
    }
    
    private func setUI(enable: Bool) {
        dismissKeyboard()
        
        emailTextField.enabled = enable
        passwordTextField.enabled = enable
        submitButton.enabled = enable
        forgotButton.enabled = enable
        nameTextField.enabled = enable
        nameButton.enabled = enable
        
        let alpha: CGFloat = enable ? 1.0 : 0.5
        
        emailTextField.alpha = alpha
        passwordTextField.alpha = alpha
        submitButton.alpha = alpha
        forgotButton.alpha = alpha
        logoImageView.alpha = alpha
        onBoardStackView.alpha = alpha
        displayNameStackView.alpha = alpha
        
        loadingIndicator.frame = CGRectMake(0, 0, 40, 40)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        
        enable ? loadingIndicator.removeFromSuperview() : view.addSubview(loadingIndicator)
    }
    
    private func showOnBoardScreen(show: Bool) {
        loginStackView.hidden = show
        forgotButton.hidden = show
        
        onBoardStackView.hidden = !show
        displayNameStackView.hidden = !show
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == nameTextField {
            
            if range.length == 1 {
                return true
            }
            
            if textField.text?.characters.count < 12 {
                if string == " " {
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
            
        }
        
        return true
    }
    
    private func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    private func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if nameTextField.editing {
            logoImageView.hidden = true
            view.frame.origin.y = getKeyboardHeight(notification) * -1
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if nameTextField.editing {
            logoImageView.hidden = false
            view.frame.origin.y = 0
        }
    }
    
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    private func dismissKeyboard() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismissKeyboard()
    }
    
    private func createUser() {
        FIRAuth.auth()?.createUserWithEmail(userEmail, password: userPassword, completion: { (user, error) in
            performUIUpdatesOnMain {
                if error != nil {
                    self.showErrorAlert("Couldn't Create User", msg: "Please make sure your password is 6 or more characters and try again.", createUser: false)
                } else {
                    if user != nil {
                        self.showOnBoardScreen(true)
                        self.setUI(true)
                    } else {
                        self.showErrorAlert("Unable To Retrieve Data", msg: "Please try again.", createUser: false)
                    }
                }
            }
        })
    }
    
}
