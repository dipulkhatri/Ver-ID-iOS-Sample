//
//  ErrorViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 07/12/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerID

class ErrorViewController: UIViewController {

    /// Reload Ver-ID
    ///
    /// The `VerID.shared.isLoaded` property observer in the app delegate will update the view controller if the loading succeeds.
    /// - Parameter sender: Sender of the action
    @IBAction func reloadVerID(_ sender: Any?) {
        VerID.shared.load()
    }

}
