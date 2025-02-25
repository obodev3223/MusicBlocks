//
//  UserProfile.swift
//  FrikiTuner
//
//  Created by Jose R. García on 23/2/25.
//

import Foundation

struct UserProfile: Codable {
    var username: String
    
    static let defaultUsername = "Pequeño músico"
    
    static func load() -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return UserProfile(username: defaultUsername)
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }
}