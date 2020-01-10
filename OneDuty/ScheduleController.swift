//
//  ScheduleController.swift
//  One Duty
//
//  Created by Yeshiwas, Dagmawi on 7/17/19.
//  Copyright © 2019 Yeshiwas, Dagmawi. All rights reserved.
//

import Cocoa
import Foundation

extension String {
    var alphanumeric: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted).joined().lowercased()
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

class ScheduleController: NSViewController {
    
    var scheduleList: [[String : Any]] = []
    var onCallList: [[String : Any]] = []
    var curSchedule: [String : Any] = [:]
    var scheduleType = "<INSERT PRIMARY SCHEDULE TYPE>"

    @IBOutlet weak var onCallName: NSTextField!
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var onCallPhone: NSTextField!
    @IBOutlet weak var onCallEmail: NSTextField!
    @IBOutlet weak var teamName: NSTextField!
    @IBOutlet weak var searchText: NSSearchField!
    @IBOutlet weak var helpButtonTool: NSButton!
    @IBOutlet weak var spinLoader: NSProgressIndicator!
    @IBOutlet weak var touchName: NSTextField!
    @IBOutlet weak var primaryRadio: NSButton!
    @IBOutlet weak var peakRadio: NSButton!
    @IBOutlet weak var secondaryRadio: NSButton!
    @IBOutlet weak var defaultButtonText: NSButton!
    
    @IBAction func radioGroup(_ sender: NSButton) {
        datePicker.dateValue = Date()  // set current date
        if self.peakRadio.state == NSControl.StateValue.on {
            self.scheduleType = "<INSERT BACKUP SCHEDULE TYPE>"
        }
        if self.primaryRadio.state == NSControl.StateValue.on {
            self.scheduleType = "<INSERT PRIMARY SCHEDULE TYPE>"
        }
        if self.secondaryRadio.state == NSControl.StateValue.on {
            self.scheduleType = "<INSERT SECONDARY SCHEDULE TYPE>"
        }
        self.Enter(sender: searchText.stringValue)
    }
    
    @IBAction func defaultButton(_ sender: NSButton) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        if self.defaultButtonText.title == "Clear" {
            appDelegate.togglePopover(sender)
            self.defaultButtonText.title = "Set Default"
            self.onCallName.stringValue = ""
            self.onCallPhone.stringValue = ""
            self.onCallEmail.stringValue = ""
            self.teamName.stringValue = ""
            self.searchText.stringValue = ""
            datePicker.dateValue = Date()
            self.primaryRadio.state = NSControl.StateValue.on
        }
        if self.onCallName.stringValue != "" {
            appDelegate.statusItem.button?.image = NSImage(named:NSImage.Name(""))
            let splitStringArray = self.onCallName.stringValue.split(separator: " ").map({ (substring) in
                return String(substring)
            })
            appDelegate.statusItem.button?.title = self.teamName.stringValue + "| On Call: " + splitStringArray[0]
            self.defaultButtonText.title = "Clear"
            appDelegate.togglePopover(sender)
        } else {
            appDelegate.statusItem.button?.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            appDelegate.statusItem.button?.title = ""
        }
    }
    
    let helpPop = NSPopover()
    
    @IBAction func helpButton(_ sender: NSButton) {
        helpPop.contentViewController = HelpController.freshController()
        helpPop.behavior = NSPopover.Behavior.transient;
        self.helpButtonTool.action = #selector(toggleHelp(_:))
    }
    
    @objc func toggleHelp(_ sender: Any?) {
        if helpPop.isShown {
            closeHelp(sender: sender)
        } else {
            showHelp(sender: sender)
        }
    }
    
    func showHelp(sender: Any?) {
        if let button = self.helpButtonTool {
            helpPop.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closeHelp(sender: Any?) {
        helpPop.performClose(sender)
    }
    
    @IBAction func submitButton(_ sender: NSButton) {
        Enter(sender: searchText.stringValue)
    }
    
    @IBAction func teamIdEntry(_ sender: NSTextField) {
        Enter(sender: sender.stringValue)
    }
    
    
    @objc func Enter(sender: String) {
        self.spinLoader.startAnimation(sender)
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyyMMdd"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if sender != "" {
            
            let myGroup = DispatchGroup()
            
            myGroup.enter()
            self.getSchedules(query: sender.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .illegalCharacters))
            myGroup.leave()
            
            myGroup.notify(queue: DispatchQueue.main) {
                print("Getting On Call Main Thread...")
                if !self.scheduleList.isEmpty {
                    for schedule in self.scheduleList {
                        print("SCHEDULE TYPE BEFORE HIT: ", self.scheduleType)
                        if (schedule["summary"] as? String)!.contains(self.scheduleType) {
                            print("Matched Schedule Type")
                            self.curSchedule = schedule
                            self.teamName.font = NSFont.systemFont(ofSize: 14)
                            self.teamName.textColor = self.onCallName.textColor
                            for scheduleTeam in self.scheduleList {
                                let teamArray = scheduleTeam["teams"] as? [[String: Any]]
                                if !teamArray!.isEmpty {
                                    self.teamName.stringValue = (teamArray![0]["summary"] as? String)!
                                    break
                                }
                            }
                            self.getOnCall(scheduleId: schedule["id"] as? String ?? "AAAAAAA", today: RFC3339DateFormatter.string(from: Date().noon),tomorrow: RFC3339DateFormatter.string(from: Date.tomorrow))
                            sleep(UInt32(1))
                            print("ON CALL LIST: ", self.onCallList)
                            if self.onCallList.count > 0 {
                                self.GetContactInfo(userId: self.onCallList[0]["id"] as! String)
                            } else {
                                self.teamName.stringValue = schedule["summary"] as! String
                                self.onCallName.stringValue = "No User On Call for the Selected Date"
                                self.touchName.stringValue = "No User On Call for the Selected Date"
                            }
                            break
                        }
                    }
                }
            }
        }
        self.spinLoader.stopAnimation(sender)
    }
    
    
    @IBAction func phoneCopy(_ sender: NSButton) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(self.onCallPhone.stringValue, forType: NSPasteboard.PasteboardType.string)
        
    }
    
    @IBAction func emailCopy(_ sender: NSButton) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(self.onCallEmail.stringValue, forType: NSPasteboard.PasteboardType.string)
    }
    
    @IBAction func touchPhoneButton(_ sender: NSButton) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(self.onCallPhone.stringValue, forType: NSPasteboard.PasteboardType.string)
    }
    
    @IBAction func touchEmailButton(_ sender: NSButton) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(self.onCallEmail.stringValue, forType: NSPasteboard.PasteboardType.string)
    }
    
    
    @IBAction func exitButton(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func refresh() {
        print("REFRESHING...")
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        if (appDelegate.statusItem.button?.title != "") {
            Enter(sender: self.searchText.stringValue)
            if self.onCallName.stringValue != "" {
                appDelegate.statusItem.button?.image = NSImage(named:NSImage.Name(""))
                let splitStringArray = self.onCallName.stringValue.split(separator: " ").map({ (substring) in
                    return String(substring)
                })
                appDelegate.statusItem.button?.title = self.teamName.stringValue + "| On Call: " + splitStringArray[0]
            } else {
                appDelegate.statusItem.button?.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
                appDelegate.statusItem.button?.title = ""
            }
            if appDelegate.popover.isShown {
                appDelegate.togglePopover(Any?.self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let date = Date().addingTimeInterval(43200)
        let timer = Timer(fireAt: date, interval: 43200, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        
        self.datePicker.target = self
        self.datePicker.action = #selector(dateSelected)
        
        let action = NSEvent.EventTypeMask.mouseExited
        self.datePicker.sendAction(on: action)
        datePicker.dateValue = Date()  // set current date

        helpPop.contentViewController = HelpController.freshController()
        helpPop.behavior = NSPopover.Behavior.transient;
        self.helpButtonTool.action = #selector(toggleHelp(_:))
        
        self.primaryRadio.state = NSControl.StateValue.on
    }
    
    @objc func dateSelected(){
        self.spinLoader.startAnimation(Any?.self)
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyyMMdd"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if !self.scheduleList.isEmpty {
            self.getOnCall(scheduleId: self.curSchedule["id"] as? String ?? "AAAAAAA", today: RFC3339DateFormatter.string(from:self.datePicker.dateValue.noon),tomorrow: RFC3339DateFormatter.string(from:self.datePicker.dateValue.dayAfter))
            print("ON CALL LIST: ", self.onCallList)
            sleep(UInt32(1))
            if self.onCallList.count > 0 {
                self.GetContactInfo(userId: self.onCallList[0]["id"] as! String)
            } else {
                self.teamName.stringValue = self.curSchedule["summary"] as! String
                self.onCallName.stringValue = "No User On Call for the Selected Date"
                self.touchName.stringValue = "No User On Call for the Selected Date"
            }
        }
        self.spinLoader.stopAnimation(Any?.self)
    }
    
    func getSchedules(query: String) {
        var done = false
        print("QUERY: ", query)
        print("Getting Teams from Postman... ", Date())
        let headers = [
            "Accept": "application/vnd.pagerduty+json;version=2",
            "Authorization": "Token token=<INSERT PAGERDUTY TOKEN HERE>",
        ]
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.pagerduty.com/schedules?query=" + query)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error!)
            } else {
                let _ = response as? HTTPURLResponse
                guard let dataResponse = data,
                    error == nil else {
                        print(error?.localizedDescription ?? "Response Error")
                        return
                }
                do{
                    guard let jsonResponse = try JSONSerialization.jsonObject(with:
                        dataResponse, options: []) as? [String:AnyObject] else { return }
                    
                    if let schedules = jsonResponse["schedules"] as? [Any], !schedules.isEmpty {
                        guard let jsonArray = jsonResponse["schedules"] as? [[String: Any]] else {
                            print("ERROR MAKING JSON ARRAY")
                            return
                        }
                        
                        self.scheduleList = jsonArray
                    
                    } else {
                        DispatchQueue.main.async {
                            print("Schedule Not Found for Team")
                            self.onCallName.stringValue = ""
                            self.touchName.stringValue = ""
                            self.teamName.textColor = NSColor.red
                            self.teamName.font = NSFont.boldSystemFont(ofSize: 13)
                            self.teamName.stringValue = "Team not found. Please try again."
                            self.onCallPhone.stringValue = ""
                            self.onCallEmail.stringValue = ""
                            self.scheduleList = []
                            self.onCallList = []
                        }
                    }

                } catch let parsingError {
                    print("Error", parsingError)
                }
                
                done = true
            }
        })

        dataTask.resume()
        
        repeat {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        } while !done

    }
    
    func getOnCall(scheduleId: String,today: String,tomorrow: String) {
        print("Getting Who's On Call from Postman... ", Date())
        
        let headers = [
            "Accept": "application/vnd.pagerduty+json;version=2",
            "Authorization": "Token token=<INSERT PAGERDUTY TOKEN HERE>",
        ]
        print("SCHEDULE: ", scheduleId)
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.pagerduty.com/schedules/" + scheduleId + "/users?since=" + today + "&until=" + tomorrow)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in

            if (error != nil) {
                print(error!)
            } else {
                let _ = response as? HTTPURLResponse
                guard let dataResponse = data,
                    error == nil else {
                        print(error?.localizedDescription ?? "Response Error")
                        return
                }
                do{
                    guard let jsonResponse = try JSONSerialization.jsonObject(with:
                        dataResponse, options: []) as? [String:AnyObject] else { return }
                    
                    guard let jsonArray = jsonResponse["users"] as? [[String: Any]] else {
                        print("ERROR MAKING JSON ARRAY")
                        return
                    }
                    self.onCallList = jsonArray
                    if self.onCallList.count > 0 {
                        DispatchQueue.main.async {
                            self.onCallName.stringValue = jsonArray[0]["name"] as! String
                            self.touchName.stringValue = jsonArray[0]["name"] as! String
                        }
                        print("JSON RESPONSE LIST: ", self.onCallList[0]["name"] ?? "Schedule ID Not Found")
                    }
                } catch let parsingError {
                    print("Error", parsingError)
                }
            }
        })
        
        dataTask.resume()
    }
    
    func GetContactInfo(userId: String) {
        let headers = [
            "Accept": "application/vnd.pagerduty+json;version=2",
            "Authorization": "Token token=<INSERT PAGERDUTY TOKEN HERE>"
        ]
        
        print("USER ID: ", userId)
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.pagerduty.com/users/" + userId + "/contact_methods")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error!)
            } else {
                let _ = response as? HTTPURLResponse
                guard let dataResponse = data,
                    error == nil else {
                        print(error?.localizedDescription ?? "Response Error")
                        return
                }
                do{
                    guard let jsonResponse = try JSONSerialization.jsonObject(with:
                        dataResponse, options: []) as? [String:AnyObject] else { return }
                    
                    print("CONTACT RESPONSE: ", jsonResponse)
                    guard let jsonArray = jsonResponse["contact_methods"] as? [[String: Any]] else {
                        print("ERROR MAKING JSON ARRAY")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if !jsonArray.isEmpty {
                            self.onCallEmail.stringValue = jsonArray[0]["address"] as! String
                            if (jsonArray[1]["label"] as! String).lowercased() == "work" || (jsonArray[1]["label"] as! String).lowercased() == "mobile"{
                                self.onCallPhone.stringValue = jsonArray[1]["address"] as! String
                            } else if (jsonArray[2]["label"] as! String).lowercased() == "work" || (jsonArray[2]["label"] as! String).lowercased() == "mobile" {
                                self.onCallPhone.stringValue = jsonArray[2]["address"] as! String
                            } else {
                                self.onCallPhone.stringValue = "No Phone Number Found"
                            }
                        } else {
                            self.onCallEmail.stringValue = "No Email Found"
                            self.onCallPhone.stringValue = "No Phone Number Found"
                        }
                    }
                    
                } catch let parsingError {
                    print("Error", parsingError)
                }
                
            }
        })
        
        dataTask.resume()
        
    }
}

extension ScheduleController {
    static func freshController() -> ScheduleController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("ScheduleController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ScheduleController else {
            fatalError("Why cant I find ScheduleController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}
