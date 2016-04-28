//
//  TodayViewController.swift
//  Test Strip Today
//
//  Created by Keaton Burleson on 4/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import UIKit
import NotificationCenter
import QuartzCore
import Foundation
class TodayViewController: UITableViewController, NCWidgetProviding {
    
    @IBOutlet var high: UILabel?
    @IBOutlet var low: UILabel?
    @IBOutlet var average: UILabel?
     let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, 320);
        for view in self.tableView.subviews {
            view.backgroundColor = UIColor.clearColor()
        }
        if ((defaults?.doubleForKey("highscore")) != nil) {
            high?.text = "\(defaults!.doubleForKey("highscore")) mg/dL"
        }else{
            high?.text = "No data"
        }
        
        if ((defaults?.doubleForKey("lowscore")) != nil) {
            low?.text = "\(Int(round(defaults!.doubleForKey("lowscore")))) mg/dL"
        }else{
            low?.text = "No data"
        }
        if ((defaults?.doubleForKey("average")) != nil) {
            average?.text = "\(round(defaults!.doubleForKey("average"))) mg/dL"
        }else{
            average?.text = "No data"
        }
        
        high?.backgroundColor = UIColor.redColor()
        high?.layer.cornerRadius = 5
        high?.layer.masksToBounds = true
        
     
        low?.backgroundColor = UIColor(colorLiteralRed: 0.9843, green: 0.8235, blue: 0.0353, alpha: 1.0)
        low?.layer.cornerRadius = 5
        low?.layer.masksToBounds = true
        
        average?.backgroundColor = self.view.tintColor
        average?.layer.cornerRadius = 5
        average?.layer.masksToBounds = true
        
        
        // Do any additional setup after loading the view from its nib.
    }
    @IBAction func openHome(){
        self.extensionContext!.openURL(NSURL(string: "test-strip://")!, completionHandler: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
}
