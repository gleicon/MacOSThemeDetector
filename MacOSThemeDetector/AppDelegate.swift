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



@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarItem: NSStatusItem!
    var isDark: Bool!

    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var firstMenuItem: NSMenuItem?
    @IBOutlet weak var scriptStatusMenuItem: NSMenuItem!
    @IBOutlet weak var webhookStatusMenuItem: NSMenuItem!
    
    let prefs = Preferences()

    func logInfoIfVerbose(_ items: Any...) {
        if self.prefs.verboseLogging {
            let msg: [String] = items.compactMap { String(describing: $0) }
            os_log("MacOSThemeDetector: %@", log: OSLog.viewCycle, type: .info, msg.joined(separator: " "))
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.isDark = false
        self.switchThemeStatusBasedOnUserPref()
        
        // Setup the event notifier
        DistributedNotificationCenter.default.addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: nil) {
                (notification) in self.switchThemeStatusBasedOnUserPref()
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
        
        self.logInfoIfVerbose("Executing: ", cmdLine)
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
            self.logInfoIfVerbose(data.result)
            switch data.result {
            case .success:
                self.logInfoIfVerbose("Return: ", data.value!)
                self.webhookStatusMenuItem.title = "Webhook called succesfully"
            case let .failure(error):
                self.logInfoIfVerbose("Error making request: \(error)")
                self.webhookStatusMenuItem.title = "Webhook request error"
            }
        }
        return true
    }
    
    func executeProgramWithParameters(commandLine: String) -> Bool {
        let fileManager = FileManager()
        let command = Process()
        
        let cmdArray = commandLine.components(separatedBy: " ")
        
        if cmdArray.count < 1 {
            return false
        }
        
        let program = cmdArray[0]
        
        if fileManager.isExecutableFile(atPath: program) != true {
            self.logInfoIfVerbose("Non-executable file:", commandLine)
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
        
        self.logInfoIfVerbose(output)
        self.logInfoIfVerbose(error)
        
        if !command.isRunning {
            let status = command.terminationStatus
            if status == 0 {
                self.logInfoIfVerbose("Task succeeded.")
                self.scriptStatusMenuItem.title = "Script run succesfully"
            } else {
                self.logInfoIfVerbose("Task failed \(status).")
                self.scriptStatusMenuItem.title = "Script failed with status \(status)"
            }
        }
        
        if self.prefs.programTimeout > 0 {
            let secs = Double(prefs.programTimeout)
            DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
                command.terminate()
                let status = command.terminationStatus
                if status == 0 {
                    self.logInfoIfVerbose("Task succeeded.")
                } else {
                    self.logInfoIfVerbose("Task failed: \(status)")
                }
            }
        }
        return true
    }

}

