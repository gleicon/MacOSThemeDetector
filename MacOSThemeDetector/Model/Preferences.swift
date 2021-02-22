//
//  Preferences.swift
//  MacOSThemeDetector
//
//  Created by Gleicon Moraes on 14/02/21.
//

import Foundation

struct Preferences {

    var programPath: String {
        get {
            guard let savedProgramPathName = UserDefaults.standard.string(forKey: "programPath") else { return "" }
            return savedProgramPathName
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "programPath")
        }
    }
    
    var programTimeout: Int {
        get {
            let programTimeout = UserDefaults.standard.integer(forKey: "programTimeout")
            return programTimeout
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "programTimeout")
        }
    }
    
    var urlWebHook: URL {
        get {
            let urlWebHook = UserDefaults.standard.url(forKey: "urlWebHook")
            if urlWebHook == nil {
                return URL(string: "http://localhost:80")!
            }
            return urlWebHook!
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "urlWebHook")
        }
    }
    
    var verboseLogging: Bool {
        get {
            let verboseLogging = UserDefaults.standard.bool(forKey: "verboseLogging")
            return verboseLogging
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "verboseLogging")
        }
    }

}
