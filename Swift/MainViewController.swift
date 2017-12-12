//
//  MainViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 04/10/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerID

class MainViewController: UIViewController, VerIDSessionDelegate {
    
    // MARK: - Interface builder views

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var authenticateButton: UIButton!
    
    // MARK: -
    
    /// Settings to use for user registration
    var registrationSettings = VerIDRegistrationSessionSettings(userId: VerIDUser.defaultUserId, livenessDetection: .regular, showGuide: true, showResult: true)
    
    // MARK: - Override from UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUserDisplay()
    }
    
    // MARK: -
    
    /// Find out whether the user registered their face. If the user is registered display their profile photo and enable the Authenticate button.
    func updateUserDisplay() {
        // Do not block the main queue
        DispatchQueue.global().async {
            do {
                if try VerID.shared.isUserRegistered(VerIDUser.defaultUserId) == true {
                    // The user is registered
                    // Load the user's profile picture
                    let image = VerID.shared.userProfilePicture(VerIDUser.defaultUserId)
                    // Update the registration session settings to append the faces to the current user when registering more faces
                    self.registrationSettings.appendIfUserExists = true
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        self.textView.isHidden = true
                        self.imageView.isHidden = false
                        self.registerButton.setTitle("Register more faces", for: .normal)
                        // Enable the Authenticate button
                        self.authenticateButton.isEnabled = true
                        // Add a Reset button to enable deleting the registered user
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(self.reset(_:)))
                    }
                } else {
                    // Update the registration settings to create a new user when registering faces
                    self.registrationSettings.appendIfUserExists = false
                    DispatchQueue.main.async {
                        self.imageView.isHidden = true
                        self.textView.isHidden = false
                        self.registerButton.setTitle("Register", for: .normal)
                        // Disable the authentication button. The user must be registered to authenticate.
                        self.authenticateButton.isEnabled = false
                        self.navigationItem.rightBarButtonItem = nil
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    // Show the error view controller and let the user reload Ver-ID.
                    guard let errorViewController = self.storyboard?.instantiateViewController(withIdentifier: "error") else {
                        return
                    }
                    self.navigationController?.setViewControllers([errorViewController], animated: false)
                }
            }
        }
    }
    
    // MARK: - Button actions
    
    /// Reset the registration
    ///
    /// This will delete the registered user
    /// - Parameter sender: Sender of the action
    @IBAction func reset(_ sender: Any) {
        VerID.shared.deregisterUser(VerIDUser.defaultUserId) { (err) in
            self.updateUserDisplay()
        }
    }
    
    /// Register faces
    ///
    /// Add more faces if the user is already registered
    /// - Parameter sender: Sender of the action
    @IBAction func register(_ sender: Any) {
        let session = VerIDRegistrationSession(settings: self.registrationSettings)
        session.delegate = self
        session.start()
    }
    
    /// Authenticate the registered user
    ///
    /// - Parameter sender: Sender of the action
    @IBAction func authenticate(_ sender: Any) {
        let requiredPoseCount = UserDefaults.standard.integer(forKey: "livenessDetectionPoses")
        let settings = VerIDAuthenticationSessionSettings(userId: VerIDUser.defaultUserId, livenessDetection: .regular)
        settings.showResult = true
        settings.showGuide = true
        settings.numberOfResultsToCollect = requiredPoseCount + 1
        let session = VerIDAuthenticationSession(settings: settings)
        session.delegate = self
        session.start()
    }
    
    // MARK: - VerIDSessionDelegate
    
    
    /// Called when a Ver-ID session finishes
    ///
    /// Inspect the session result to find out more about the outcome of the session and to get the collected images
    /// - Parameters:
    ///   - session: The session that finished
    ///   - result: The session result
    func session(_ session: VerIDSession, didFinishWithResult result: VerIDSessionResult) {
        self.updateUserDisplay()
    }

}
