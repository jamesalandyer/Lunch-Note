//
//  LoginVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import FirebaseAuth
import pop

class LoginVC: UIViewController, UITextFieldDelegate {

    //Outlets
    @IBOutlet weak private var emailTextField: UITextField!
    @IBOutlet weak private var passwordTextField: UITextField!
    @IBOutlet weak private var submitButton: CustomButton!
    @IBOutlet weak private var forgotButton: CustomButton!
    @IBOutlet weak private var logoImageView: UIImageView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var addLunchboxLabel: UILabel!
    @IBOutlet weak var addLunchboxImageView: UIImageView!
    @IBOutlet weak private var nameTextField: UITextField!
    @IBOutlet weak private var nameButton: CustomButton!
    @IBOutlet weak var loginButton: CustomButton!
    @IBOutlet weak var logoConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginConstraint: NSLayoutConstraint!
    @IBOutlet weak var forgotConstraint: NSLayoutConstraint!
    @IBOutlet weak var welcomeConstraint: NSLayoutConstraint!
    @IBOutlet weak var introConstraint: NSLayoutConstraint!
    @IBOutlet weak var addLunchboxLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var addLunchboxImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameButtonConstraint: NSLayoutConstraint!
    
    //Properties
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    private var userEmail: String!
    private var userPassword: String!
    private var animEngineLogin: AnimationEngine!
    private var animEngineOnboard: AnimationEngine!
    private var animEngineLogo: AnimationEngine!
    
    //MARK: - Stack
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.delegate = self
        passwordTextField.delegate = self
        nameTextField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        subscribeToKeyboardNotifications()
        
        animEngineLogo = AnimationEngine(constraints: [logoConstraint])
        animEngineLogin = AnimationEngine(constraints: [emailConstraint, passwordConstraint, loginConstraint, forgotConstraint])
        animEngineOnboard = AnimationEngine(constraints: [welcomeConstraint, introConstraint, addLunchboxLabelConstraint, addLunchboxImageConstraint, nameConstraint, nameButtonConstraint])
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //If the user is logged in but doesn't have a display name, show onboard
        if FirebaseClient.sharedInstance.currentUser != nil {
            if FirebaseClient.sharedInstance.currentDisplayName == nil {
                showOnBoardScreen(true)
            } else {
                dismissViewControllerAnimated(true, completion: nil)
            }
        } else {
            animEngineLogin.animateOnScreen()
        }
        
        animEngineLogo.animateOnScreen()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromKeyboardNotifications()
    }
    
    //MARK: - Actions

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
                            self.showOnBoardScreen(false)
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
    
    /**
     Sets the UI to be enabled and full color or disabled and faded.
     
     - Parameter enable: A Bool of whether to enable UI.
     */
    private func setUI(enable: Bool) {
        dismissKeyboard()
        
        emailTextField.enabled = enable
        passwordTextField.enabled = enable
        loginButton.enabled = enable
        submitButton.enabled = enable
        forgotButton.enabled = enable
        nameTextField.enabled = enable
        nameButton.enabled = enable
        
        let alpha: CGFloat = enable ? 1.0 : 0.5
        
        emailTextField.alpha = alpha
        passwordTextField.alpha = alpha
        loginButton.alpha = alpha
        submitButton.alpha = alpha
        forgotButton.alpha = alpha
        logoImageView.alpha = alpha
        welcomeLabel.alpha = alpha
        introLabel.alpha = alpha
        addLunchboxLabel.alpha = alpha
        addLunchboxImageView.alpha = alpha
        nameTextField.alpha = alpha
        nameButton.alpha = alpha
        
        loadingIndicator.frame = CGRectMake(0, 0, 40, 40)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        
        enable ? loadingIndicator.removeFromSuperview() : view.addSubview(loadingIndicator)
    }
    
    /**
     Sets whether to show the onboard screen.
     
     - Parameter only: A Bool of whether to only show the onboard screen.
     */
    private func showOnBoardScreen(only: Bool) {
        if !only {
            animEngineLogin.animateOffScreen()
        }
        
        animEngineOnboard.animateOnScreen()
    }
    
    /**
     Shows an error alert on the screen.
     
     - Parameter title: The header of the alert.
     - Parameter msg: The message of the alert.
     - Parameter action: A Bool of whether to add the create user button to the alert.
     */
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
    
    //MARK: - Create User
    
    /**
     Creates a new user on firebase.
     */
    private func createUser() {
        FIRAuth.auth()?.createUserWithEmail(userEmail, password: userPassword, completion: { (user, error) in
            performUIUpdatesOnMain {
                if error != nil {
                    self.showErrorAlert("Couldn't Create User", msg: "Please make sure your password is 6 or more characters and try again.", createUser: false)
                } else {
                    if user != nil {
                        self.showOnBoardScreen(false)
                        self.setUI(true)
                    } else {
                        self.showErrorAlert("Unable To Retrieve Data", msg: "Please try again.", createUser: false)
                    }
                }
            }
        })
    }
    
    //MARK: - TextField
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        //Rules for setting display name
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
        if nameTextField.editing {
            logoImageView.hidden = true
            welcomeLabel.hidden = true
            view.frame.origin.y = getKeyboardHeight(notification) * -1
        }
    }
    
    /**
     Adjusts the screen when the keyboard hides and shows the top button.
     
     - Parameter notification: The notification being passed through.
     */
    func keyboardWillHide(notification: NSNotification) {
        if nameTextField.editing {
            logoImageView.hidden = false
            welcomeLabel.hidden = false
            view.frame.origin.y = 0
        }
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
    
    /**
     Dismisses all of the keyboards.
     */
    private func dismissKeyboard() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
    }
    
    //MARK: - Touches
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismissKeyboard()
    }
    
}
