//
//  AppDelegate.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 20/01/2016.
//  Copyright © 2016 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerID

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Instance variables

    var window: UIWindow?
    var isObservingDefaults: Bool = false
    /// Observes the `isLoaded` property of the `VerID.shared` singleton
    var veridLoadObservation: NSKeyValueObservation?
    var observingContext: Int?
    
    // MARK: - Application delegate methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Load Ver-ID
        // API secret is read from the app's Info.plist
        VerID.shared.load()
        // Observe `isLoaded` property of the `VerID` singleton instance
        self.veridLoadObservation = VerID.shared.observe(\VerID.isLoaded, options: [.initial,.old]) { (verid,change) in
            DispatchQueue.main.async {
                guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
                    return
                }
                let initialViewController: UIViewController
                if verid.isLoaded {
                    // Ver-ID successfully finished loading.
                    // Register and observe user defaults.
                    UserDefaults.standard.register(defaults: ["securityLevel":String(format: "%d", VerID.shared.securityLevel.rawValue), "livenessDetectionPoses": "1"])
                    UserDefaults.standard.synchronize()
                    UserDefaults.standard.addObserver(self, forKeyPath: "securityLevel", options: .new, context: &self.observingContext)
                    self.isObservingDefaults = true
                    // Instantiate the main view controller.
                    initialViewController = storyboard.instantiateViewController(withIdentifier: "start")
                } else if verid.loadError != nil {
                    // Ver-ID failed to load. Instantiate the error view controller.
                    initialViewController = storyboard.instantiateViewController(withIdentifier: "error")
                } else {
                    return
                }
                // Replace the root in the navigation view controller.
                navigationController.setViewControllers([initialViewController], animated: false)
            }
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Unload Ver-ID
        VerID.shared.unload()
        // Remove user defaults observer
        if self.isObservingDefaults {
            UserDefaults.standard.removeObserver(self, forKeyPath: "securityLevel")
            self.isObservingDefaults = false
        }
        self.veridLoadObservation = nil
    }

    // MARK: - Key-value observing
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.observingContext {
            if keyPath == "securityLevel", let level = VerIDSecurityLevel(rawValue: UserDefaults.standard.integer(forKey: keyPath!)) {
                VerID.shared.securityLevel = level
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

