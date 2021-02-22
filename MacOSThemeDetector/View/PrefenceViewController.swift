//
//  PerefenceViewController.swift
//  MacOSThemeDetector
//
//  Created by Gleicon Moraes on 14/02/21.
//

import Cocoa
import Alamofire

class PrefenceViewController: NSViewController {
    
    var prefs = Preferences()
    var verboseLoggingBool = false
    

    
    @IBOutlet weak var scriptPath: NSTextFieldCell!
    @IBOutlet weak var verboseLogging: NSButton!
    @IBOutlet weak var programTimeout: NSTextField!
    @IBOutlet weak var webHookURL: NSTextFieldCell!
    @IBOutlet weak var webHookTesterOutput: NSTextView!
    
    @IBAction func verboseLoggingCheck(_ sender: NSButtonCell) {
        if sender.intValue == 0 {
            self.verboseLoggingBool = false
            return
        }
        verboseLoggingBool = true
    }
    
    @IBAction func webHookURLTestButton(_ sender: Any) {
        let validatedWebhookURL = NSURL(string: webHookURL.stringValue)
        if validatedWebhookURL?.scheme == nil {
            webHookTesterOutput.string = "Invalid URL"
            return
        }
        let valURL = validatedWebhookURL?.absoluteString ?? ""
        let request = AF.request(valURL, method: .post, parameters: ["body": "ThemeTest"])
        
        request.responseString { (data) in
            switch data.result {
            case .success:
                self.webHookTesterOutput.string = data.value!
            case let .failure(error):
                self.webHookTesterOutput.string = "Error making request: \(error)"
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayCurrentPreferences()
    }
    
    override func viewDidAppear() {
        view.window?.level = .floating
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
    }
    
    @IBAction func fileButtonClicked(_ sender: Any) {
        let fileDialog = NSOpenPanel()
        fileDialog.showsResizeIndicator = true
        fileDialog.allowsMultipleSelection = false

        if fileDialog.runModal() == NSApplication.ModalResponse.OK {
            let result = fileDialog.url
            scriptPath.stringValue = result!.relativePath
        }
        return
    }
    
    @IBAction func doneButtonClicked(_ sender: Any) {
        self.savePreferences()
        self.view.window?.close()
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        self.view.window?.close()
    }
    
    
    func displayCurrentPreferences() {
        scriptPath.stringValue = prefs.programPath
        if prefs.verboseLogging == true {
            self.verboseLogging.intValue = 1
        } else {
            self.verboseLogging.intValue = 0

        }
        self.programTimeout.intValue = Int32(prefs.programTimeout)
        self.webHookURL.stringValue =  prefs.urlWebHook.absoluteString

    }
    
    func savePreferences() {
        prefs.programPath = scriptPath.stringValue
        prefs.verboseLogging = self.verboseLoggingBool
        prefs.programTimeout = Int(self.programTimeout.intValue)
        prefs.urlWebHook = URL(string: self.webHookURL.stringValue)!
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PrefsChanged"), object: nil)
    }
    
}
