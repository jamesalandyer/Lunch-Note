//
//  EditVC.swift
//  Lunch Note
//
//  Created by James Dyer on 6/8/16.
//  Copyright © 2016 James Dyer. All rights reserved.
//

import UIKit
import Firebase

class EditVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    //Outlets
    @IBOutlet weak var deleteAccountButton: CustomButton!
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var profileImageView: CustomImageView!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var emailAddressTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var saveButton: CustomButton!
    @IBOutlet weak var currentEmailAddressTextField: UITextField!
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var continueButton: CustomButton!
    @IBOutlet weak var cancelButton: CustomButton!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var deleteConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameConstraint: NSLayoutConstraint!
    @IBOutlet weak var newEmailConstraint: NSLayoutConstraint!
    @IBOutlet weak var newPasswordConstraint: NSLayoutConstraint!
    @IBOutlet weak var saveConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentEmailConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentPasswordConstraint: NSLayoutConstraint!
    @IBOutlet weak var continueConstraint: NSLayoutConstraint!
    
    //Properties
    private let imagePicker = UIImagePickerController()
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    var uploadTask: FIRStorageUploadTask!
    
    private var currentUserNotes: [String]!
    
    private var newEmailAddress: String!
    private var newPassword: String!
    private var loggedIn = false
    
    private var animEngineEdit: AnimationEngine!
    private var animEngineLogin: AnimationEngine!
    private var animEngineCancel: AnimationEngine!
    
    //MARK: - Stack
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setting Delegates
        imagePicker.delegate = self
        displayNameTextField.delegate = self
        emailAddressTextField.delegate = self
        passwordTextField.delegate = self
        currentEmailAddressTextField.delegate = self
        currentPasswordTextField.delegate = self
        
        animEngineEdit = AnimationEngine(constraints: [deleteConstraint, profileImageConstraint, nameConstraint, newEmailConstraint, newPasswordConstraint, saveConstraint])
        animEngineCancel = AnimationEngine(constraints: [cancelConstraint])
        animEngineLogin = AnimationEngine(constraints: [logoConstraint, currentEmailConstraint, currentPasswordConstraint, continueConstraint])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        saveButton.enabled = false
        saveButton.alpha = 0.5
        
        subscribeToKeyboardNotifications()
        getUserImage()
        getUserData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        animEngineEdit.animateOnScreen()
        animEngineCancel.animateOnScreen()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromKeyboardNotifications()
    }
    
    //MARK: - Actions
    
    @IBAction func addPhotoButtonPressed(sender: AnyObject) {
        setUI(false)
        
        if FirebaseClient.sharedInstance.currentUserImage != DEFAULT_PICTURE {
            showAlert("Delete Photo", msg: "Are you sure you want to delete this photo?", action: true)
        } else {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .SavedPhotosAlbum
            
            presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func deleteAccountButtonPressed(sender: AnyObject) {
        setUI(false)
        if loggedIn {
            showAlert("Delete Account", msg: "Are you sure you want to delete this account? This can't be undone.", action: false, account: true)
        } else {
            showUserLogin(true)
            setUI(true)
        }
    }
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
        setUI(false)
        
        var emailPassed = true
        var passwordPassed = true
        
        if let newDisplayName = displayNameTextField.text where newDisplayName != "" {
            updateUserProfile(FirebaseClient.sharedInstance.currentUserImage, displayName: newDisplayName)
            FirebaseClient.sharedInstance.userReference.child("displayName").setValue(newDisplayName.uppercaseString)
        }
        
        if emailAddressTextField.text != "" {
            if let email = emailAddressTextField.text where isValidEmail(email) {
                newEmailAddress = email
            } else {
                emailPassed = false
                
            }
        }
        
        if passwordTextField.text != "" {
            if let password = passwordTextField.text where password.characters.count >= 6 {
                newPassword = password
            } else {
                passwordPassed = false
                
            }
        }
        
        if !emailPassed && !passwordPassed {
            showAlert("Invalid Email Address & Password", msg: "Please enter a valid email address and password.", action: false)
        } else if !emailPassed {
            showAlert("Invalid Email Address", msg: "Please enter a valid email address.", action: false)
        } else if !passwordPassed {
            showAlert("Invalid Password", msg: "Your password must be 6 characters or longer.", action: false)
        } else if newEmailAddress != nil || newPassword != nil {
            setUI(true)
            showUserLogin(true)
        }
    }
    
    @IBAction func continueButtonPressed(sender: AnyObject) {
        setUI(false)
        
        guard let email = currentEmailAddressTextField.text where email != "" && isValidEmail(email) else {
            showAlert("Invalid Email Address", msg: "Please enter a valid email address.", action: false)
            return
        }
        
        guard let password = currentPasswordTextField.text where password.characters.count >= 6 else {
            showAlert("Invalid Password", msg: "Please enter a valid password.", action: false)
            return
        }
        
        FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (user, error) in
            
            if let err = error {
                performUIUpdatesOnMain {
                    if err.code == 17011 {
                        self.showAlert("Account Doesn't Exist", msg: "Please check your login.", action: false)
                    } else if err.code == 17009 {
                        self.showAlert("Invalid Password", msg: "Please check your password.", action: false)
                    } else if err.code == 17020 {
                        self.showAlert("Request Timed Out", msg: "Please check your connection.", action: false)
                    } else {
                        self.showAlert("Error", msg: "Please try again.", action: false)
                    }
                }
            } else {
                performUIUpdatesOnMain {
                    self.showUserLogin(false)
                    if user != nil {
                        self.loggedIn = true
                        
                        if let newEmail = self.newEmailAddress {
                            //If user entered an email, save it
                            self.setUserEmail(newEmail, completionHandler: { (success) in
                                if success {
                                    //New email was saved
                                    if let newPassword = self.newPassword {
                                        //If the user also entered a password, save it
                                        self.setUserPassword(newPassword, completionHandler: { (success) in
                                            if success {
                                                //Password saved
                                                self.dismissViewControllerAnimated(true, completion: nil)
                                            } else {
                                                //Password didn't save
                                                self.showAlert("Unable To Update Password", msg: "There was an error updating your password.", action: false)
                                            }
                                        })
                                    } else {
                                        //User did not enter a new password
                                        self.dismissViewControllerAnimated(true, completion: nil)
                                    }
                                } else {
                                    //Email didn't save
                                    self.showAlert("Unable To Update Email Address", msg: "There was an error updating your email address.", action: false)
                                    //If password was entered, both weren't saved
                                    if self.newPassword != nil {
                                        self.showAlert("Email & Password Not Updated", msg: "Email & password failed to update. Please try again.", action: false)
                                    }
                                }
                            })
                            
                        } else if let newPassword = self.newPassword {
                            //The user only entered a new password, save it
                            self.setUserPassword(newPassword, completionHandler: { (success) in
                                if success {
                                    //Password saved
                                    self.dismissViewControllerAnimated(true, completion: nil)
                                } else {
                                    //Password didn't save
                                    self.showAlert("Unable To Update Password", msg: "There was an error updating your password.", action: false)
                                }
                                
                            })
                            
                        } else {
                            //User didn't enter email or password, used for delete account verification
                            self.showUserLogin(false)
                            self.setUI(true)
                        }
                        
                    } else {
                        self.showAlert("Unable To Retrieve Data", msg: "Please try logging in again.", action: false)
                    }
                }
            }
            
        })
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - Adjusting UI
    
    /**
     Sets the UI to be enabled and full color or disabled and faded.
     
     - Parameter enable: A Bool of whether to enable UI.
     */
    private func setUI(enable: Bool) {
        dismissKeyboard()
        
        emailAddressTextField.enabled = enable
        passwordTextField.enabled = enable
        cancelButton.enabled = enable
        displayNameTextField.enabled = enable
        addPhotoButton.enabled = enable
        currentEmailAddressTextField.enabled = enable
        currentPasswordTextField.enabled = enable
        continueButton.enabled = enable
        deleteAccountButton.enabled = enable
        
        let alpha: CGFloat = enable ? 1.0 : 0.5
        
        emailAddressTextField.alpha = alpha
        passwordTextField.alpha = alpha
        cancelButton.alpha = alpha
        displayNameTextField.alpha = alpha
        profileImageView.alpha = alpha
        currentEmailAddressTextField.alpha = alpha
        currentPasswordTextField.alpha = alpha
        continueButton.alpha = alpha
        deleteAccountButton.alpha = alpha
        logoImageView.alpha = alpha
        
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        
        enable ? loadingIndicator.removeFromSuperview() : view.addSubview(loadingIndicator)
    }
    
    /**
     Hides the edit profile and screen and shows a screen to login or reverses it.
     
     - Parameter show: A Bool of whether to show the user login.
     */
    private func showUserLogin(show: Bool) {
        if show {
            animEngineEdit.animateOffScreen()
            animEngineLogin.animateOnScreen()
        } else {
            animEngineEdit.animateBackOnScreen()
            animEngineLogin.animateBackOffScreen()
        }
    }
    
    /**
     Shows an alert on the screen.
     
     - Parameter title: The header of the alert.
     - Parameter msg: The message of the alert.
     - Parameter action: A Bool of whether to add the delete photo button to the alert.
     - Parameter account: (Default: False) A Bool of whether to add the delete account button to the alert.
     */
    private func showAlert(title: String, msg: String, action: Bool, account: Bool = false) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let dismissTitle = action || account ? "Cancel" : "Ok"
        let dismiss = UIAlertAction(title: dismissTitle, style: .Default, handler: { (action) in
            self.setUI(true)
        })
        if action {
            let delete = UIAlertAction(title: "Delete", style: .Destructive, handler: { (action) in
                self.updateUserProfile(nil, displayName: nil)
                
                let ref = FirebaseClient.sharedInstance.storageReference
                ref.deleteWithCompletion { (error) -> Void in
                    self.setUI(true)
                }
            })
            alert.addAction(delete)
        }
        if account {
            let delete = UIAlertAction(title: "Delete", style: .Destructive, handler: { (action) in
                let user = FIRAuth.auth()?.currentUser
                let userUid = user?.uid
                
                if let currentNotes = self.currentUserNotes {
                    for note in currentNotes {
                        FirebaseClient.Constants.Database.REF_NOTES.child(note).removeValue()
                    }
                }
                FirebaseClient.Constants.Database.REF_USERS.child(userUid!).removeValue()
                
                user?.deleteWithCompletion { error in
                    if error != nil {
                        self.showAlert("Unable To Delete Account", msg: "There was an error deleting your account.", action: false)
                        self.setUI(true)
                    } else {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            })
            alert.addAction(delete)
        }
        
        alert.addAction(dismiss)
        if !action && !account {
            setUI(true)
        }
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: - Retrieve Data
    
    /**
     Retieves the users current notes.
    */
    private func getUserData() {
        FirebaseClient.sharedInstance.notesReference.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let dataDict = snapshot.value as? Dictionary<String, AnyObject> {
                self.currentUserNotes = Array(dataDict.keys)
            }
        })
    }
    
    /**
     Retieves the users current profile photo.
     */
    private func getUserImage() {
        if FirebaseClient.sharedInstance.currentUserImage != DEFAULT_PICTURE {
            //Check cache
            if let cachedImage = FirebaseClient.Constants.LocalImages.imageCache.objectForKey(FirebaseClient.sharedInstance.currentUser!) as? UIImage {
                profileImageView.image = cachedImage
                let delete = UIImage(named: "delete_photo.png")
                addPhotoButton.setImage(delete, forState: .Normal)
            } else {
                //If not in cache, download it
                let imageReference = FIRStorage.storage().referenceForURL(FirebaseClient.sharedInstance.currentUserImage)
                FirebaseClient.sharedInstance.downloadImage(FirebaseClient.sharedInstance.currentUser!, url: imageReference, completionHandler: { (result) in
                    if let image = result {
                        self.profileImageView.image = image
                        let delete = UIImage(named: "delete_photo.png")
                        self.addPhotoButton.setImage(delete, forState: .Normal)
                    }
                })
            }
        } else {
            profileImageView.image = UIImage(named: "defaultpicture_large.png")
            let add = UIImage(named: "add_photo.png")
            addPhotoButton.setImage(add, forState: .Normal)
        }
    }
    
    //MARK: - Update Data
    
    /**
     Sets a new user email for login.
     
     - Parameter email: A string of the new email the user wants to set.
     - Parameter completionHandler: Handles what to do once the request is done.
     - Parameter success: A Bool of whether the request was successful.
     */
    private func setUserEmail(email: String, completionHandler: (success: Bool) -> Void) {
        let user = FIRAuth.auth()?.currentUser
        
        user?.updateEmail(email) { error in
            if error != nil {
                completionHandler(success: false)
            } else {
                completionHandler(success: true)
            }
        }
    }
    
    /**
     Sets a new user password for login.
     
     - Parameter password: A string of the new password the user wants to set.
     - Parameter completionHandler: Handles what to do once the request is done.
     - Parameter success: A Bool of whether the request was successful.
     */
    private func setUserPassword(password: String, completionHandler: (success: Bool) -> Void) {
        let user = FIRAuth.auth()?.currentUser
        
        user?.updatePassword(password) { error in
            if error != nil {
                completionHandler(success: false)
            } else {
                completionHandler(success: true)
            }
        }
    }
    
    /**
     Updates the current users profile which is their display name and profile image.
     
     - Parameter imageURL: (Optional) The new image url to the profile photo.
     - Parameter displayName: (Optional) The new display name for the user.
    */
    private func updateUserProfile(imageURL: String?, displayName: String?) {
        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let changeRequest = user.profileChangeRequest()
            
            changeRequest.displayName = displayName ?? FirebaseClient.sharedInstance.currentDisplayName!
            let url = imageURL ?? DEFAULT_PICTURE
            let changeURL = url != FirebaseClient.sharedInstance.currentUserImage
            changeRequest.photoURL = NSURL(string: url)
            
            changeRequest.commitChangesWithCompletion { error in
                if error != nil {
                    self.showAlert("Unable To Update", msg: "Please try again.", action: false)
                } else {
                    //If the profile photo url was actually changed
                    if changeURL {
                        self.updateUserPosts(url)
                        self.getUserImage()
                    }
                    //If there is nothing else to do
                    if self.emailAddressTextField.text == "" && self.passwordTextField.text == "" && self.displayNameTextField.text != "" {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            }
        }
    }
    
    /**
     Updates the authorImage field of all of the users posts to reflect the new image.
     
     - Parameter imageUrl: The string of the new image url.
    */
    private func updateUserPosts(imageUrl: String) {
        for note in currentUserNotes {
            FirebaseClient.Constants.Database.REF_NOTES.child(note).child("authorImage").setValue(imageUrl)
        }
    }
    
    //MARK: - ImagePicker
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        dismissViewControllerAnimated(true, completion: nil)
        //Get the image and compress it into a JPEG
        let imageData: NSData = UIImageJPEGRepresentation(image, 0.2)!
        let imageSize: Int = imageData.length / 1024
        
        //Make sure that the image isn't to large
        if imageSize < 2048 {
            let ref = FirebaseClient.sharedInstance.storageReference
            
            uploadTask = ref.putData(imageData, metadata: nil) { metadata, error in
                if (error != nil) {
                    self.showAlert("Upload Failed", msg: "Please try again.", action: false)
                } else {
                    if let downloadURL = metadata!.downloadURL() {
                        let downloadString = downloadURL.absoluteString
                        FirebaseClient.Constants.LocalImages.imageCache.removeObjectForKey(FirebaseClient.sharedInstance.currentUser!)
                        self.updateUserProfile(downloadString, displayName: nil)
                        self.setUI(true)
                    }
                    
                }
            }
        } else {
            showAlert("Unable To Upload", msg: "Your image size is too large.", action: false)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
        setUI(true)
    }
    
    //MARK: - TextField
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //Only show the save button if the user has entered anything
        if displayNameTextField.text != "" || emailAddressTextField.text != "" || passwordTextField.text != "" {
            saveButton.enabled = true
            saveButton.alpha = 1.0
        } else {
            saveButton.enabled = false
            saveButton.alpha = 0.5
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        //Rules for making a display name
        if textField == displayNameTextField {
            
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
        deleteAccountButton.hidden = true
        view.frame.origin.y = getKeyboardHeight(notification) * -0.25
    }
    
    /**
     Adjusts the screen when the keyboard hides and shows the top button.
     
     - Parameter notification: The notification being passed through.
     */
    func keyboardWillHide(notification: NSNotification) {
        deleteAccountButton.hidden = false
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
    
    /**
     Dismisses all of the keyboards.
    */
    private func dismissKeyboard() {
        emailAddressTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        displayNameTextField.resignFirstResponder()
        currentEmailAddressTextField.resignFirstResponder()
        currentPasswordTextField.resignFirstResponder()
    }
    
    //MARK: - Touches
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismissKeyboard()
    }

}
