//
//  Extension + UIViewController.swift
//  Demo Add WaterMark
//
//  Created by Hammad Baig on 02/06/2023.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(okButton)
        present(alert, animated: true, completion: nil)
    }
    
}
