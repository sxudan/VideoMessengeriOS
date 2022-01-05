//
//  IncomingCallViewController.swift
//  SimpleWebRTC
//
//  Created by sudayn on 6/2/21.
//  Copyright © 2021 n0. All rights reserved.
//

import UIKit

protocol IncomingCallDelegate {
    func onAccept()
    func onDecline()
}

class IncomingCallViewController: UIViewController {

    var delegate: IncomingCallDelegate?
    var ringtone: Ringtone!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ringtone = Ringtone()
        ringtone.play()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onDecline(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.delegate?.onDecline()
        })
    }
    
    @IBAction func onAccept(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.delegate?.onAccept()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ringtone.stop()
    }
    
}
