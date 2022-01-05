//
//  EntryViewController.swift
//  Messenger
//
//  Created by sudayn on 1/5/22.
//

import UIKit

class EntryViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onJoin(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoCallViewController") as! VideoCallViewController
        let username = usernameField.text ?? ""
        guard username != "" else {
            return
        }
        usernameField.resignFirstResponder()
        vc.username = username
        vc.type = .Join
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func onCreate(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoCallViewController") as! VideoCallViewController
        let username = usernameField.text ?? ""
        guard username != "" else {
            return
        }
        usernameField.resignFirstResponder()
        vc.username = username
        vc.type = .Create
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
}
