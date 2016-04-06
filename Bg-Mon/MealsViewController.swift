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
class MealsViewController: UITableViewController {

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

		addViewController = storyboard.instantiateViewControllerWithIdentifier("AddMeal2") as? AddMeal
		let navigationForFood = storyboard.instantiateViewControllerWithIdentifier("AddMeal")

		menuView = BTNavigationDropdownMenu.init(navigationController: self.navigationController, title: "Hello", items: items, maxWidth: 100)
		menuView?.cellSeparatorColor = UIColor.clearColor()
		menuView?.cellTextLabelAlignment = NSTextAlignment.Center
		menuView?.cellBackgroundColor = UIColor.clearColor()
		menuView?.cellTextLabelColor = UIColor.whiteColor()
		menuView?.checkMarkImage = nil
		menuView?.cellHeight = 100
		menuView?.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in

			switch indexPath {
			case 0:
				self.addViewController?.configureView(AddMeal.AddType.Meal)

			case 1:
				self.addViewController?.configureView(AddMeal.AddType.Correction)

			case 2:
				self.addViewController?.configureView(AddMeal.AddType.LongLasting)

			default:
				print("Did select item at index: \(indexPath)")
			}
			self.presentViewController(navigationForFood, animated: true, completion: nil)
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
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
       
        addViewController?.correctionCell?.insulin?.text = add
        return true;
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

	@IBOutlet var carbCell:  CarbCell?
	@IBOutlet var bloodGlucoseCell: GlucoseCell?
	@IBOutlet var correctionCell: CorrectionCell?
	@IBOutlet var longLastingCell: UITableViewCell?

	enum AddType {
		case Meal
		case Correction
		case LongLasting
	}
	var configurationType: String?
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	func configureView(type: AddType) {
		switch type {
		case .Meal:
			configurationType = "Meal"
		case .Correction:
			configurationType = "Correction"
		case .LongLasting:
			configurationType = "Long Lasting"
		}
	}

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return configurationType
    }
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if configurationType == "Meal" {
			longLastingCell?.hidden = true
		} else if configurationType == "Correction" {
			carbCell?.hidden = true
			longLastingCell?.hidden = true
		} else if configurationType == "Long Lasting" {
			carbCell?.hidden = true
			longLastingCell?.hidden = true
		}
		return 3
        
	}
    @IBAction func dismissYoSelf(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}