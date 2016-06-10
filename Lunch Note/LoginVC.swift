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

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var submitButton: CustomButton!
    @IBOutlet weak var forgotButton: CustomButton!
    @IBOutlet weak var logoImageView: UIImageView!
    
    let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    private var userEmail: String!
    private var userPassword: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.delegate = self
        passwordTextField.delegate = self
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
                        DataService.sharedInstance.uid = userInfo.uid
                        if let photoURL = userInfo.photoURL {
                            DataService.sharedInstance.setPhotoURL(photoURL)
                        }
                        if let displayName = userInfo.displayName {
                            DataService.sharedInstance.displayName = displayName
                            self.dismissViewControllerAnimated(true, completion: nil)
                        } else {
                            //HIDE FOR ONBOARD
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
    
    private func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
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
        emailTextField.enabled = enable
        passwordTextField.enabled = enable
        submitButton.enabled = enable
        forgotButton.enabled = enable
        
        let alpha: CGFloat = enable ? 1.0 : 0.5
        
        emailTextField.alpha = alpha
        passwordTextField.alpha = alpha
        submitButton.alpha = alpha
        forgotButton.alpha = alpha
        logoImageView.alpha = alpha
        
        loadingIndicator.frame = CGRectMake(0, 0, 40, 40)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        
        enable ? loadingIndicator.removeFromSuperview() : view.addSubview(loadingIndicator)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func dismissKeyboard() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismissKeyboard()
    }
    
    private func createUser() {
        FIRAuth.auth()?.createUserWithEmail(userEmail, password: userPassword, completion: { (user, error) in
            performUIUpdatesOnMain {
                if error != nil {
                    self.showErrorAlert("Couldn't Create User", msg: "Please try again.", createUser: false)
                } else {
                    if let userInfo = user {
                        DataService.sharedInstance.uid = userInfo.uid
                        //HIDE FOR ONBOARD
                    } else {
                        self.showErrorAlert("Unable To Retrieve Data", msg: "Please try again.", createUser: false)
                    }
                }
            }
        })
    }
    
}
