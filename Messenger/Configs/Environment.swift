//
//  Environments.swift
//  Messenger
//
//  Created by sudayn on 4/28/21.
//

import Foundation

class Environment {
    
    public static var baseUrl: String {
        return Bundle.main.infoDictionary?["BASE_URL"] as? String ?? ""
    }
}
