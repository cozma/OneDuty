//
//  HelpController.swift
//  One Duty
//
//  Created by Yeshiwas, Dagmawi on 9/9/19.
//  Copyright © 2019 Yeshiwas, Dagmawi. All rights reserved.
//

import Cocoa
import Foundation

class HelpController: NSViewController {
    @IBOutlet weak var slackButton: NSButton!
    
    @IBAction func slackURL(_ sender: NSButton) {
        NSWorkspace.shared.open(URL(string: "https://cardtech-capitalone.slack.com/archives/CN81X7VJB")!)
    }
    
    override func viewDidLoad() {
        self.slackButton.highlight(false)
        print("HELP LOADED...")
    }
}

extension HelpController {
    // MARK: Storyboard instantiation
    static func freshController() -> HelpController {
        //1.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        //2.
        let identifier = NSStoryboard.SceneIdentifier("HelpController")
        //3.
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? HelpController else {
            fatalError("Why cant I find HelpController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}

