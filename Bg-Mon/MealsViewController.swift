//
//  MealsViewController.swift
//  Bg-Mon
//
//  Created by Keaton Burleson on 4/5/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import BTNavigationDropdownMenu
import Notie
class MealsViewController: UITableViewController, UITextFieldDelegate {

	var menuView: BTNavigationDropdownMenu?
	var mealArray: [NSDictionary]?
	var nav: UINavigationController?

	var addViewController: AddMeal?

	@IBOutlet var glucoseField: UITextField?
	@IBOutlet var insulinField: UITextField?
	@IBOutlet var carbsField: UITextField?

	override func viewDidLoad() {
		super.viewDidLoad()

		let items = ["Add Meal", "Add Correction", "Add Slow Release"]
		if let navigationController = navigationController {
			nav = navigationController
		} else {
			nav = UIApplication.sharedApplication().keyWindow?.rootViewController?.parentViewController?.navigationController
		}
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let addViewControllerNavigation = storyboard.instantiateViewControllerWithIdentifier("AddMeal") as! UINavigationController
		self.addViewController = addViewControllerNavigation.viewControllers[0] as? AddMeal

		menuView = BTNavigationDropdownMenu.init(navigationController: self.navigationController, title: "Hello", items: items, maxWidth: 100)
		menuView?.cellSeparatorColor = UIColor.clearColor()
		menuView?.cellTextLabelAlignment = NSTextAlignment.Center
		menuView?.cellBackgroundColor = UIColor.clearColor()
		menuView?.cellTextLabelColor = UIColor.whiteColor()
		menuView?.checkMarkImage = nil
		menuView?.cellHeight = 100
		menuView?.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in

			var configType: AddMeal.AddType?

			switch indexPath {
			case 0:
				configType = AddMeal.AddType.Meal
				print(configType)
			case 1:
				configType = AddMeal.AddType.Correction
				print(configType)

			case 2:
				configType = AddMeal.AddType.LongLasting
                
				print(configType)
			default:
				print("Did select item at index: \(indexPath)")
			}
            NSUserDefaults.standardUserDefaults().setObject(configType?.rawValue, forKey: "configType")
            NSUserDefaults.standardUserDefaults().synchronize()

			self.navigationController!.presentViewController(addViewControllerNavigation, animated: true, completion: nil)
           
     
            
			configType = nil
			self.addViewController = nil
		}

		if objectAlreadyExist("meals") {
			mealArray = NSUserDefaults.standardUserDefaults().objectForKey("meals") as? [NSDictionary]
		}
	}

	func objectAlreadyExist(key: String) -> Bool {
		return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if mealArray == nil {
			tableView.separatorStyle = UITableViewCellSeparatorStyle.None
			let label = UILabel.init(frame: self.view.frame)
			label.text = "No data :("
			label.textAlignment = .Center
			label.textColor = self.view.tintColor
			tableView.addSubview(label)
			return 0
		} else {
			return (mealArray?.count)!
		}
	}

	@IBAction func openMenu() {
		openLeft()
	}

	@IBAction func addMeal() {
		menuView?.show()
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! MealCell
		cell.bloodGlucose?.text = mealArray![indexPath.row]["bloodGlucose"] as? String
		cell.carbs?.text = mealArray![indexPath.row]["carbs"] as? String
		cell.insulin?.text = mealArray![indexPath.row]["bloodGlucose"] as? String

		return cell
	}
}

class AddMeal: UITableViewController {

	@IBOutlet var carbCell: CarbCell?
	@IBOutlet var bloodGlucoseCell: GlucoseCell?
	@IBOutlet var correctionCell: CorrectionCell?
	@IBOutlet var longLastingCell: LongLasting?

   
    enum AddType: String {

		case LongLasting = "Long Lasting"
        case Meal = "Full Meal"
        case Correction = "Insulin Correction"
	}
	 var configurationType: String?
	override func viewDidLoad() {
		super.viewDidLoad()
        self.tableView.beginUpdates()
        self.configurationType  = NSUserDefaults.standardUserDefaults().objectForKey("configType") as? String
        self.tableView.endUpdates()
        self.tableView.reloadData()
        self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .None)
	}
    override func viewDidAppear(animated: Bool) {
        
        if self.tableView(tableView, titleForHeaderInSection: 0) != NSUserDefaults.standardUserDefaults().objectForKey("configType") as? String{
            self.tableView.beginUpdates()
            self.configurationType  = NSUserDefaults.standardUserDefaults().objectForKey("configType") as? String
            self.tableView.endUpdates()
            self.tableView.reloadData()
            self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Automatic)
        }
  
    }

	 func calculateInsulin() -> Double{
		var target: Double?
		var ratio: Double?
		var sensitivity: Double?
        self.bloodGlucoseCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0)) as? GlucoseCell
		let glucose = Double((self.bloodGlucoseCell?.bloodGlucose!.text)!)

		var dosage: Double?

		if objectAlreadyExist("target") {
			target = NSUserDefaults.standardUserDefaults().objectForKey("target")?.doubleValue
		}
		if objectAlreadyExist("ratio") {
			ratio = NSUserDefaults.standardUserDefaults().objectForKey("ratio")?.doubleValue
		}
		if objectAlreadyExist("sensitivity") {
			sensitivity = NSUserDefaults.standardUserDefaults().objectForKey("sensitivity")?.doubleValue
		}
		// Calulating correction
		var correction = glucose! - target!
		correction = correction / sensitivity!
		if correction < 0 {
			correction = 0
		}
        self.carbCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 1, inSection: 0)) as? CarbCell
		var carbCalulation = Double((self.carbCell?.carbs!.text)!)
		carbCalulation = carbCalulation! / ratio!

		dosage = carbCalulation! + correction

        return dosage!
        
	}
	func objectAlreadyExist(key: String) -> Bool {
		return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
	}
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let viewController = segue.destinationViewController as! SuccessViewController
        
        viewController.glucoseObject = [self.calculateInsulin().description]
    }
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell?
		print("Cell Reading: \(self.configurationType)")
		if self.configurationType == "Full Meal" && indexPath.row == 0 {
			cell = self.tableView.dequeueReusableCellWithIdentifier("bloodGlucose")
		} else if self.configurationType == "Full Meal" && indexPath.row == 1 {
			cell = self.tableView.dequeueReusableCellWithIdentifier("carbs")
		} else if self.configurationType == "Insulin Correction" && indexPath.row == 0 {
			cell = self.tableView.dequeueReusableCellWithIdentifier("bloodGlucose")
		} else if self.configurationType == "Insulin Correction" && indexPath.row == 1 {
			cell = self.tableView.dequeueReusableCellWithIdentifier("insulin")
		} else if self.configurationType == "Long Lasting" && indexPath.row == 0 {
			cell = self.tableView.dequeueReusableCellWithIdentifier("bloodGlucose")
		} else if self.configurationType == "Long Lasting" && indexPath.row == 1 {
			cell = self.tableView.dequeueReusableCellWithIdentifier("longLasting")
		}
		if (cell == nil) {
			cell = UITableViewCell.init()
		}
		return cell!
	}

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.configurationType
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
	}

	@IBAction func dismissYoSelf() {
        
        self.dismissViewControllerAnimated(true, completion: { (action) in
            self.viewDidLoad()
        })
	}
}