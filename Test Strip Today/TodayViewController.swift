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
    
    var mealsArray: NSMutableArray?
    
     let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")
    override func viewDidLoad() {
        super.viewDidLoad()
        if objectAlreadyExist("meals")  {
            mealsArray = NSMutableArray()
            for i in 0..<4 {
                    mealsArray?.addObject((defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!![i])
            }
            self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, CGFloat(4 * 150));
        } else {
            self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, CGFloat(44));
            let backgroundView = UILabel(frame: self.view.frame)
            backgroundView.text = "No readings"
            backgroundView.textAlignment = .Center
            backgroundView.textColor = UIColor.whiteColor()
            self.tableView.backgroundView = backgroundView
            
        }
       
        
        
        
        // Do any additional setup after loading the view from its nib.
    }
    
    func objectAlreadyExist(key: String) -> Bool {
        return defaults!.objectForKey(key) != nil
    }
    override func viewDidAppear(animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCellWithIdentifier("cell") as! MealCell
        let type = mealsArray![indexPath.row]["type"] as! String
        //TODO - clean this monstrosity up
        if(mealsArray![indexPath.row]["bloodGlucose"] is String){
            cell.bloodGlucose?.text = "\(mealsArray![indexPath.row]["bloodGlucose"] as! String)\nmg/dL"
        }else{
            cell.bloodGlucose?.text = "\(mealsArray![indexPath.row]["bloodGlucose"] as! Double)\nmg/dL"
        }
        if(mealsArray![indexPath.row]["carbs"] is String){
            cell.carbs?.text = "\(mealsArray![indexPath.row]["carbs"] as! String)\ncarbs"
        }else{
            cell.carbs?.text = "\(mealsArray![indexPath.row]["carbs"] as! Double)\ncarbs"
        }
        if(mealsArray![indexPath.row]["insulin"] is String){
            cell.insulin?.text = "\(mealsArray![indexPath.row]["insulin"] as! String)\nunits"
        }else{
            cell.insulin?.text = "\(mealsArray![indexPath.row]["insulin"] as! Double)\nunits"
        }
        
        
        
        
        
        cell.type?.text = mealsArray![indexPath.row]["type"] as? String
        cell.backgroundColor = UIColor.blackColor()
        cell.time?.text = self.getTime(indexPath)
        
        cell.bloodGlucose?.layer.cornerRadius = 5
        cell.bloodGlucose?.clipsToBounds = true
        cell.bloodGlucose?.backgroundColor = UIColor.whiteColor()
        cell.bloodGlucose?.textColor = UIColor.blackColor()
        
        cell.carbs?.layer.cornerRadius = 5
        cell.carbs?.clipsToBounds = true
        cell.carbs?.backgroundColor = self.view.tintColor
        
        cell.insulin?.layer.cornerRadius = 5
        cell.insulin?.clipsToBounds = true
        cell.insulin?.backgroundColor = UIColor.greenColor()
        
        cell.time?.textColor = UIColor.whiteColor()
        cell.time?.clipsToBounds = true
        cell.time?.layer.cornerRadius = 5
        
        
        if(type == "Full Meal"){
            cell.mealType?.image = UIImage.init(named: "Meal.png")
        }else if(type == "Insulin Correction"){
            cell.mealType?.image = UIImage.init(named: "Adjustment.png")
        }else if(type == "Long Lasting"){
            cell.mealType?.image = UIImage.init(named: "24H.png")
        }
        return cell
    }
    func getTime(indexPath: NSIndexPath) -> String{
        let dictionary = mealsArray![indexPath.row] as! NSMutableDictionary
        if let exists = dictionary["date"]{
            let formatter = NSDateFormatter()
            formatter.dateStyle = .ShortStyle
            formatter.timeStyle = .ShortStyle
            return formatter.stringFromDate(exists as! NSDate)
        }else{
            return "No time recorded"
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
        
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if objectAlreadyExist("meals")  {
            return 4
        }else{
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.extensionContext!.openURL(NSURL(string: "test-strip://")!, completionHandler: nil)
        
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        if objectAlreadyExist("meals")  {
            mealsArray = NSMutableArray()
            for i in 0..<4 {
                mealsArray?.addObject((defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!![i])
            }
            self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, CGFloat(4 * 150));
        } else {
            self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, CGFloat(44));
            let backgroundView = UILabel(frame: self.view.frame)
            backgroundView.text = "No readings"
            backgroundView.textAlignment = .Center
            backgroundView.textColor = UIColor.whiteColor()
            self.tableView.backgroundView = backgroundView
            
        }
        
        
        

        completionHandler(NCUpdateResult.NewData)
    }
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
}
