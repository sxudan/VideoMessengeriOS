//
//  ViewController.swift
//  Messenger
//
//  Created by sudayn on 4/28/21.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /// Hello TreeLeaf
    /// - You will be redirected to ConversationListViewController
    /// - Click any message your will be redirected to MessageListViewController
    override func viewDidAppear(_ animated: Bool) {
        let conversationListViewController = ConversationListViewController()
        self.navigationController?.setViewControllers([conversationListViewController], animated: true)
        conversationListViewController.set(title: "Chats", mode: .automatic)
    }
}

