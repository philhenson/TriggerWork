//
//  LoginViewController.swift
//  TriggerWork
//
//  Created by Phil Henson on 3/5/16.
//  Copyright © 2016 Lost Nation R & D. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SVProgressHUD

class LoginViewController: UIViewController {
  
  var ref: FIRDatabaseReference!
  
  @IBOutlet weak var passwordTextField: UITextField!
  
  // MARK: View Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    ref = FIRDatabase.database().reference()
    
    // Initialize SVProgressHUD style
    SVProgressHUD.setDefaultStyle(.Dark)
    SVProgressHUD.setDefaultMaskType(.Black)
  }
  
  @IBAction func loginButtonPressed(sender: AnyObject) {
    let login = FBSDKLoginManager()
    login.logInWithReadPermissions(["public_profile", "email"], fromViewController: self) { (result, error) in
      if let error = error {
        print("Login error: \(error.localizedDescription)")
        return
      } else if (result.isCancelled) {
        print("Login cancelled")
      } else {
        print("Login successful")
        dispatch_async(dispatch_get_main_queue()) {
          SVProgressHUD.show()
        }
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user, error) in
          dispatch_async(dispatch_get_main_queue()) {
            SVProgressHUD.dismiss()
          }
          if let error = error {
            print("Firebase sign-in error: \(error.localizedDescription)")
            return
          } else {
            self.performSegueWithIdentifier("LoginSegue", sender: self)
          }
        })
      }
    }
  }
  // MARK: UI Settings
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
}

extension LoginViewController: UITextFieldDelegate {
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    passwordTextField.resignFirstResponder()
    return true
  }
}