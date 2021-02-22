//
//  AppDelegate.swift
//  MacOSThemeDetector
//
//  Created by Gleicon Moraes on 07/02/21.
//

import Cocoa
import SwiftUI
import os.log
import Alamofire

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let viewCycle = OSLog(subsystem: subsystem, category: "viewcycle")
}

func logInfo(_ items: Any...) {
    let msg: [String] = items.compactMap { String(describing: $0) }
    os_log("MacOSThemeDetector: %@", log: OSLog.viewCycle, type: .info, msg.joined(separator: " "))
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarItem: NSStatusItem!
    var isDark: Bool!

    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var firstMenuItem: NSMenuItem?
    @IBOutlet weak var scriptStatusMenuItem: NSMenuItem!
    
    let prefs = Preferences()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.isDark = false
        self.switchThemeStatusBasedOnUserPref()
        
        // Setup the event notifier
        DistributedNotificationCenter.default.addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: nil) {
                (notification) in self.monitorTheme()
            }
 
    }
    
      
    override func awakeFromNib() {
        super.awakeFromNib()
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "IconMoon")
        }
        
        if let menu = self.menu {
            statusBarItem?.menu = menu
        }
        
        if let item = self.firstMenuItem {
            item.image = NSImage(named: "IconMoon")
            item.title = "Dark theme"
        }
        
        if let scriptStatus = self.scriptStatusMenuItem {
            //item.view = self.menuInfoView.view
           // scriptStatus.image = NSImage(named: "IconMoon")
            scriptStatus.title = "Error running script"
        }
        
    }
    
    func switchThemeStatusBasedOnUserPref() {
        self.isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        var cmdLine: String
        
        
        cmdLine = ""
        if self.isDark {
            if let button = self.statusBarItem.button {
                button.image = NSImage(named: "IconMoon")
            }
            
            if let item = self.firstMenuItem {
                item.image = NSImage(named: "IconMoon")
                item.title = "Dark theme"
            }
            cmdLine = prefs.programPath.replacingOccurrences(of: "$THEME", with: "DARK")

        } else {
            if let button = self.statusBarItem.button {
                button.image = NSImage(named: "IconSun")
            }
        
            if let item = self.firstMenuItem {
                item.image = NSImage(named: "IconSun")
                item.title = "Light theme"
            }
            cmdLine = prefs.programPath.replacingOccurrences(of: "$THEME", with: "LIGHT")

        }
        if prefs.verboseLogging {
            print("Executing: ", cmdLine)
        }
        _ = executeProgramWithParameters(commandLine: cmdLine)
        _ = runWebHook(isDark)

    }
    
    func runWebHook(_ isDark: Bool) -> Bool {
        
        let valURL = prefs.urlWebHook.absoluteString
        let parameters: Parameters
        
        if isDark {
            parameters = ["body": "Dark"]
        } else {
            parameters = ["body": "Light"]
        }
        
        let request = AF.request(valURL, method: .post, parameters: parameters)
        
        request.responseString { (data) in
            print(data.result)
            switch data.result {
            case .success:
                if self.prefs.verboseLogging {
                    print("Return: ", data.value!)
                }
            case let .failure(error):
                if self.prefs.verboseLogging {
                    print("Error making request: \(error)")
                }
            }
        }
        return true
    }
    
    func monitorTheme() {
        self.switchThemeStatusBasedOnUserPref()
    }
    
    func executeProgramWithParameters(commandLine: String) -> Bool {
        let fileManager = FileManager()
        let command = Process()
        
        let cmdArray = commandLine.components(separatedBy: " ")
        
       
        
        let program = cmdArray[0]
        
        if fileManager.isExecutableFile(atPath: program) != true {
            if self.prefs.verboseLogging {
                print("Non-executable file:", commandLine)
            }
            return false
        }
        
        let args: [String] = Array(cmdArray.dropFirst())
        command.executableURL = URL(fileURLWithPath: program)
        command.arguments = args
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        command.standardOutput = outputPipe
        command.standardError = errorPipe
        
        try? command.run()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)
        
        if self.prefs.verboseLogging {
            print (output)
            print(error)
        }
        
        if !command.isRunning {
            let status = command.terminationStatus
            if status == 0 {
                if self.prefs.verboseLogging {
                    print("Task succeeded.")
                }
            } else {
                if self.prefs.verboseLogging {
                    print("Task failed.")
                }
            }
        }
        
        if self.prefs.programTimeout > 0 {
            let secs = Double(prefs.programTimeout)
            DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
                command.terminate()
                let status = command.terminationStatus
                if status == 0 {
                    if self.prefs.verboseLogging {
                        print("Task succeeded.")
                    }
                } else {
                    if self.prefs.verboseLogging {
                        print("Task failed.")
                    }
                }
            }
        }
        return true
    }

}

