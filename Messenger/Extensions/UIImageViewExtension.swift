//
//  UIImageExtension.swift
//  Messenger
//
//  Created by sudayn on 4/28/21.
//

import UIKit

extension UIImageView {
    func loadImage(url: String) {
        let session = URLSession.shared
        guard let u = URL(string: url) else {
            return
        }
        let taks = session.dataTask(with: URLRequest(url: u), completionHandler: {(data, res, err) in
            guard err == nil, let data = data else {
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data)
                self.contentMode = .scaleAspectFit
            }
        })
        taks.resume()
    }
}
