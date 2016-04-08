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
import HealthKit
class MealsViewController: UITableViewController, UITextFieldDelegate {

	var menuView: BTNavigationDropdownMenu?
	var mealArray: NSMutableArray?
	var nav: UINavigationController?

    let effect = UIBlurEffect(style: .Dark)
    let resizingMask = UIViewAutoresizing.FlexibleWidth
	var addViewController: AddMeal?

	@IBOutlet var glucoseField: UITextField?
	@IBOutlet var insulinField: UITextField?
	@IBOutlet var carbsField: UITextField?

    override func awakeFromNib() {
        if objectAlreadyExist("meals") {
            mealArray = NSUserDefaults.standardUserDefaults().objectForKey("meals")?.mutableCopy() as? NSMutableArray
        }
        super.awakeFromNib()
    }
	override func viewDidLoad() {
		super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MealsViewController.manuallyUpdateTableView), name: "newCell", object: nil)
        
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
		menuView?.cellBackgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
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
        let backgroundView = UIView.init(frame: self.view.frame)

        

        backgroundView.autoresizingMask = resizingMask
        backgroundView.addSubview(self.buildImageView())
        backgroundView.addSubview(self.buildBlurView())
        tableView.backgroundView = backgroundView
        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: effect)

		
	}
    func manuallyUpdateTableView(){
        self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Middle)
    }
    func buildImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: "pattern.jpg"))
        imageView.frame = view.bounds
        imageView.autoresizingMask = resizingMask
        return imageView
    }
    
    func buildBlurView() -> UIVisualEffectView {
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = resizingMask
        return blurView
    }
    
    override func viewDidAppear(animated: Bool) {
        if objectAlreadyExist("meals") {
            mealArray = NSUserDefaults.standardUserDefaults().objectForKey("meals")?.mutableCopy() as? NSMutableArray
        }
        if mealArray?.count != 0 && mealArray != nil {
            if(mealArray?.count == 1){
                if(self.tableView.numberOfRowsInSection(0) != mealArray?.count){
                    self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Top)
                }
            }
         self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Automatic)
        }
      
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if mealArray?.count == 0 || mealArray == nil {
            let label = UILabel.init(frame: self.view.frame)
            label.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
            label.text = "No data"
            label.tag = 6
            self.tableView.separatorStyle = .None
            label.textAlignment = .Center
            self.tableView.backgroundView?.addSubview(label)
            return 1
        }
        for view in (self.tableView.backgroundView?.subviews)! {
            if view.tag == 6 {
                view.removeFromSuperview()
            }
        }
        self.tableView.separatorStyle = .SingleLine
        return 1
    }

	func objectAlreadyExist(key: String) -> Bool {
		return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
	}

    
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
	
        if(mealArray == nil){
            return 0
        }else{
			return (mealArray?.count)!
        }
 

		
	}
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }


    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.mealArray?.removeObjectAtIndex(indexPath.row)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        NSUserDefaults.standardUserDefaults().setObject(self.mealArray, forKey: "meals")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
	@IBAction func openMenu() {
		openLeft()
	}

    
	@IBAction func addMeal() {
		menuView?.show()
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! MealCell
		cell.bloodGlucose?.text = "\(mealArray![indexPath.row]["bloodGlucose"] as! String) mg/dL"
		cell.carbs?.text = "\(mealArray![indexPath.row]["carbs"] as! String) carbs"
		cell.insulin?.text = "\(mealArray![indexPath.row]["insulin"] as! String) units"
        cell.type?.text = mealArray![indexPath.row]["type"] as? String
		cell.backgroundColor = UIColor.clearColor()
        cell.time?.text = self.getTime(indexPath)
        cell.time?.backgroundColor = self.view.tintColor
        cell.time?.textColor = UIColor.whiteColor()
        cell.time?.clipsToBounds = true
        cell.time?.layer.cornerRadius = 5
		return cell
	}
    
    func getTime(indexPath: NSIndexPath) -> String{
        let dictionary = mealArray![indexPath.row] as! NSMutableDictionary
        if let exists = dictionary["date"]{
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.LongStyle
            formatter.timeStyle = .MediumStyle
            return formatter.stringFromDate(exists as! NSDate)
        }else{
            return "No time recorded"
        }
    }
    
}


class AddMeal: UITableViewController {

	@IBOutlet var carbCell: CarbCell?
	@IBOutlet var bloodGlucoseCell: GlucoseCell?
	@IBOutlet var correctionCell: CorrectionCell?
	@IBOutlet var longLastingCell: LongLasting?
    var intValue: Int?
    let effect = UIBlurEffect(style: .Dark)
    let resizingMask = UIViewAutoresizing.FlexibleWidth
    
    
     private var healthStore = HKHealthStore()
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
        let backgroundView = UIView.init(frame: self.view.frame)
        
        
        
        backgroundView.autoresizingMask = resizingMask
        backgroundView.addSubview(self.buildImageView())
        backgroundView.addSubview(self.buildBlurView())
        tableView.backgroundView = backgroundView
        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: effect)
        
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
    func buildImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: "pattern2.png"))
        imageView.frame = view.bounds
        imageView.autoresizingMask = resizingMask
        return imageView
    }
    
    func buildBlurView() -> UIVisualEffectView {
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = resizingMask
        return blurView
    }
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.backgroundView?.backgroundColor = UIColor.clearColor()
        header.textLabel?.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
    }
    
    func uploadToHealthKit(bloodGlucoseLevel: Double, carbs: Double){
        


        var prefUnit: HKUnit?
        
        let sampleType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)
        

		let carbs = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)
		let bloodGlucose = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)

		let healthKitTypes = Set<HKQuantityType>(arrayLiteral: carbs!, bloodGlucose!)

        self.healthStore.requestAuthorizationToShareTypes(healthKitTypes as Set, readTypes: healthKitTypes as Set) { (success, error) -> Void in
			if (success) {
				NSLog("HealthKit authorization success...")

				self.healthStore.preferredUnitsForQuantityTypes(healthKitTypes as Set, completion: { (preferredUnits, error) -> Void in
					if (error == nil) {
						NSLog("...preferred unts %@", preferredUnits)
						prefUnit = preferredUnits[sampleType!]
						let quantity = HKQuantity(unit: prefUnit!, doubleValue: bloodGlucoseLevel)

						let quantitySample = HKQuantitySample(type: sampleType!, quantity: quantity, startDate: NSDate(), endDate: NSDate())

						self.healthStore.saveObjects([quantitySample]) { (success, error) -> Void in
							if (success) {
								NSLog("Saved blood glucose level")
							}
						}
					}
				})
			}
		}

  
        
   
        
        
    }
    func saveAndDie(){
        var beetusDictionary: NSMutableDictionary?
        if self.configurationType == "Full Meal" {
            let pissOff = intValue?.description
            print("Int: \(self.intValue)")
            beetusDictionary = ["type" : self.configurationType!, "bloodGlucose" : (self.bloodGlucoseCell?.bloodGlucose?.text)!, "carbs" : (self.carbCell?.carbs?.text)!, "insulin" : pissOff! , "date": NSDate()]
        }else if self.configurationType == "Insulin Correction" {
            beetusDictionary = ["type" : self.configurationType!, "bloodGlucose" : (self.bloodGlucoseCell?.bloodGlucose?.text)!, "insulin" : (self.correctionCell?.insulin?.text)!, "date": NSDate(), "carbs" : "0"]
        }else if self.configurationType == "Long Lasting"{
            beetusDictionary = ["type" : self.configurationType!, "bloodGlucose" : (self.bloodGlucoseCell?.bloodGlucose?.text)!, "insulin" : (self.longLastingCell?.insulin?.text)!, "date": NSDate(), "carbs" : "0"]
        }
        
        
        if(self.carbCell != nil && self.configurationType == "Full Meal") {
           self.uploadToHealthKit(Double((self.bloodGlucoseCell?.bloodGlucose?.text)!)!, carbs: Double((self.carbCell?.carbs?.text)!)!)
        }else{
            self.uploadToHealthKit(Double((self.bloodGlucoseCell?.bloodGlucose?.text)!)!, carbs: Double((0)))
        }
        var mealsArray: NSMutableArray?
        
        if objectAlreadyExist("meals") {
            mealsArray = (NSUserDefaults.standardUserDefaults().objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
        }else{
            mealsArray = NSMutableArray()
        }

        mealsArray?.insertObject(beetusDictionary!, atIndex: 0)
        
        NSUserDefaults.standardUserDefaults().setObject(mealsArray, forKey: "meals")
        NSUserDefaults.standardUserDefaults().synchronize()
        if (self.bloodGlucoseCell != nil) {
            self.bloodGlucoseCell?.bloodGlucose?.text = ""
        }
        if (self.carbCell != nil) {
            self.carbCell?.carbs?.text = ""
        }
        
        if((self.correctionCell) != nil){
            self.correctionCell?.insulin?.text = ""
        }
        if((self.longLastingCell) != nil){
            self.longLastingCell?.insulin?.text = ""
        }
        NSNotificationCenter.defaultCenter().postNotificationName("newCell", object: nil)
        
    }

    @IBAction func checkAndSubmit(){
        if self.configurationType == "Full Meal" {
         

			self.bloodGlucoseCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0)) as? GlucoseCell
			self.carbCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 1, inSection: 0)) as? CarbCell

			if (bloodGlucoseCell?.bloodGlucose?.text != "" && carbCell?.carbs?.text != "") {

				self.intValue = Int(round(self.calculateInsulin()))
                print("IntVALUE \(self.intValue)")
				self.performSegueWithIdentifier("save", sender: self)
			} else {
				let alert = UIAlertController.init(title: "Error", message: "One or more fields are unset", preferredStyle: UIAlertControllerStyle.Alert)
				let ok = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) in
					alert.dismissViewControllerAnimated(true, completion: nil)
				})
				alert.addAction(ok)
				self.presentViewController(alert, animated: true, completion: nil)
			}
		} else if self.configurationType == "Insulin Correction" {
            self.bloodGlucoseCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0)) as? GlucoseCell
            self.correctionCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 1, inSection: 0)) as? CorrectionCell
            if (bloodGlucoseCell?.bloodGlucose?.text != "" && correctionCell?.insulin?.text != "") {
                self.performSegueWithIdentifier("save", sender: self)
            } else {
                let alert = UIAlertController.init(title: "Error", message: "One or more fields are unset", preferredStyle: UIAlertControllerStyle.Alert)
                let ok = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                })
                alert.addAction(ok)
                self.presentViewController(alert, animated: true, completion: nil)
            }
           
		} else if self.configurationType == "Long Lasting"{
            self.bloodGlucoseCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0)) as? GlucoseCell
            self.longLastingCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 1, inSection: 0)) as? LongLasting
            if (bloodGlucoseCell?.bloodGlucose?.text != "" && longLastingCell?.insulin!.text != "") {
                self.performSegueWithIdentifier("save", sender: self)
            } else {
                let alert = UIAlertController.init(title: "Error", message: "One or more fields are unset", preferredStyle: UIAlertControllerStyle.Alert)
                let ok = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                })
                alert.addAction(ok)
                self.presentViewController(alert, animated: true, completion: nil)
            }

        }
        self.saveAndDie()
        
    }
	 func calculateInsulin() -> Double{
      
     
		var target: Double? = 120
		var ratio: Double? = 8
		var sensitivity: Double? = 30

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
        if configurationType == "Full Meal" {
            
             viewController.glucoseObject = [intValue!.description]
 
        }else{
            viewController.glucoseObject = nil
            
           
        }
      
        
       
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
        cell?.backgroundColor = UIColor.clearColor()
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