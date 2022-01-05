//
//  UIViewExtension.swift
//  Messenger
//
//  Created by sudayn on 4/28/21.
//

import UIKit

extension UIView {
    
    @IBInspectable
    var radius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        
        set {
            self.layer.cornerRadius = newValue
            self.layer.masksToBounds = true
        }
    }
}
