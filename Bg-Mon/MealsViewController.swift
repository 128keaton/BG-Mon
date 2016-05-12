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
import HealthKit
class MealsViewController: UITableViewController, UITextFieldDelegate {

	var menuView: BTNavigationDropdownMenu!
	var mealArray: NSMutableArray?
	var nav: UINavigationController?

    let effect = UIBlurEffect(style: .Dark)
    let resizingMask = UIViewAutoresizing.FlexibleWidth
	var addViewController: AddMeal?
    let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")
	@IBOutlet var glucoseField: UITextField?
	@IBOutlet var insulinField: UITextField?
	@IBOutlet var carbsField: UITextField?

  
    override func awakeFromNib() {
        if objectAlreadyExist("meals") {
            mealArray = defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray
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

        menuView = BTNavigationDropdownMenu.init(navigationController: self.navigationController, title: "", items: items)
		menuView?.cellSeparatorColor = UIColor.clearColor()
		menuView?.cellTextLabelAlignment = NSTextAlignment.Center
		menuView?.cellBackgroundColor = UIColor.blackColor()
		menuView?.cellTextLabelColor = UIColor.whiteColor()
        
        menuView.checkMarkImage = nil
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
            self.defaults!.setObject(configType?.rawValue, forKey: "configType")
            self.defaults!.synchronize()

			self.navigationController!.presentViewController(addViewControllerNavigation, animated: true, completion: nil)
           
     
            
			configType = nil
			self.addViewController = nil
		}
     
	}
    func manuallyUpdateTableView(){
        self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Middle)
    }

    
    override func viewDidAppear(animated: Bool) {
        if objectAlreadyExist("meals") {
            mealArray = defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray
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
            label.textColor = UIColor.whiteColor()
            label.text = "No meals"
            label.tag = 6
            self.tableView.separatorStyle = .None
            label.textAlignment = .Center
            self.tableView.backgroundView = label
            return 1
        }
  
        self.tableView.separatorStyle = .SingleLine
        self.tableView.backgroundView = nil
        return 1
    }

	func objectAlreadyExist(key: String) -> Bool {
		return defaults!.objectForKey(key) != nil
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
        defaults!.setObject(self.mealArray, forKey: "meals")
        defaults!.synchronize()
    }

    
	@IBAction func addMeal() {
		menuView?.show()
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! MealCell
        let type = mealArray![indexPath.row]["type"] as! String
        //TODO - clean this monstrosity up
        if(mealArray![indexPath.row]["bloodGlucose"] is String){
            cell.bloodGlucose?.text = "\(mealArray![indexPath.row]["bloodGlucose"] as! String)"
        }else{
            cell.bloodGlucose?.text = "\(mealArray![indexPath.row]["bloodGlucose"] as! Double)"
        }
        if(mealArray![indexPath.row]["carbs"] is String){
            cell.carbs?.text = "\(mealArray![indexPath.row]["carbs"] as! String)"
        }else{
            cell.carbs?.text = "\(mealArray![indexPath.row]["carbs"] as! Double)"
        }
        if(mealArray![indexPath.row]["insulin"] is String){
            cell.insulin?.text = "\(mealArray![indexPath.row]["insulin"] as! String)"
        }else{
            cell.insulin?.text = "\(mealArray![indexPath.row]["insulin"] as! Double)"
        }
        
        cell.type?.text = mealArray![indexPath.row]["type"] as? String
		cell.backgroundColor = UIColor.whiteColor()
        cell.date?.text = self.getDate(indexPath)
        cell.timeLabel?.text = self.getTime(indexPath)
        cell.gradientView?.direction = .Horizontal
        cell.gradientView?.colors = [UIColor(red: 0.4549, green: 0.9294, blue: 0.4627, alpha: 1.0), UIColor(red: 0.4627, green: 0.9176, blue: 0.4471, alpha: 1.0), UIColor(red: 0.4549, green: 0.9294, blue: 0.4627, alpha: 1.0)]
       
        var target: Double?
        var currentGlucose: Double?
        if(mealArray![indexPath.row]["bloodGlucose"] is String){
           currentGlucose = (mealArray![indexPath.row]["bloodGlucose"] as! NSString).doubleValue
        }else{
            currentGlucose = mealArray![indexPath.row]["bloodGlucose"] as? Double
        }
        
        if objectAlreadyExist("target") {
            target = defaults!.objectForKey("target")?.doubleValue
            if currentGlucose! > target! + 1 {
                //Warning Yellow
                cell.gradientView?.colors = [UIColor(red: 0.9569, green: 0.949, blue: 0.4667, alpha: 1.0), UIColor(red: 0.9176, green: 0.8902, blue: 0.5059, alpha: 1.0), UIColor(red: 0.9569, green: 0.949, blue: 0.4667, alpha: 1.0)]
            }else if currentGlucose <= 70{
                //Reginald Red
                cell.gradientView?.colors = [UIColor(red: 0.9373, green: 0.2314, blue: 0.2314, alpha: 1.0), UIColor(red: 0.898, green: 0.3765, blue: 0.4549, alpha: 1.0), UIColor(red: 0.9373, green: 0.2314, blue: 0.2314, alpha: 1.0)]
            }
        }
        
        if(type == "Full Meal"){
            cell.type?.text = "Meal"
        }else if(type == "Insulin Correction"){
            cell.type?.text = "Correction"
        }else if(type == "Long Lasting"){
            cell.type?.text = "Long Lasting"
        }
		return cell
	}
    

    
    func getDate(indexPath: NSIndexPath) -> String{
        let dictionary = mealArray![indexPath.row] as! NSMutableDictionary
        if let exists = dictionary["date"]{
            let formatter = NSDateFormatter()
            formatter.dateFormat = "dd"
            
            return "\(formatter.stringFromDate(exists as! NSDate))\(daySuffix(exists as! NSDate))"
        }else{
            return "No time recorded"
        }
    }
    
    func getTime(indexPath: NSIndexPath) -> String{
        let dictionary = mealArray![indexPath.row] as! NSMutableDictionary
        if let exists = dictionary["date"]{
            let formatter = NSDateFormatter()
            formatter.dateFormat = "hh"
            let finalTime = formatter.stringFromDate(exists as! NSDate).stringByReplacingOccurrencesOfString("0", withString: "")
            return "\(finalTime) o' clock"
        }else{
            return "No time recorded"
        }
    }

    
    
    func daySuffix(date: NSDate) -> String {
        let calendar = NSCalendar.currentCalendar()
        let dayOfMonth = calendar.component(.Day, fromDate: date)
        switch dayOfMonth {
        case 1: fallthrough
        case 21: fallthrough
        case 31: return "st"
        case 2: fallthrough
        case 22: return "nd"
        case 3: fallthrough
        case 23: return "rd"
        default: return "th"
        }
    }
    
}



class AddMeal: UITableViewController, UITextFieldDelegate {

	@IBOutlet var carbCell: CarbCell?
	@IBOutlet var bloodGlucoseCell: GlucoseCell?
	@IBOutlet var correctionCell: CorrectionCell?
	@IBOutlet var longLastingCell: LongLasting?
    var intValue: Int?
    let effect = UIBlurEffect(style: .Light)
    let resizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
    
    let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")
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
        self.configurationType  = defaults!.objectForKey("configType") as? String
        self.tableView.endUpdates()
        self.tableView.reloadData()
        self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .None)
        self.tableView.backgroundColor = self.view.tintColor

        
	}
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
       /* print("typing")
        let currentText = textField.text
        let mutableString = NSMutableString.init(string: currentText!)
       
        if textField == bloodGlucoseCell?.bloodGlucose{
            mutableString.replaceCharactersInRange(range, withString: string)
            mutableString.appendString(" mg/dL")
            textField.text = mutableString as String
            self.bloodGlucoseCell?.bloodGlucose?.text = mutableString as String
            return false
        }else if textField == carbCell?.carbs{
            mutableString.replaceCharactersInRange(range, withString: string)
            mutableString.appendString(" g")
            textField.text = mutableString as String
            self.carbCell?.carbs?.text = mutableString as String
            return false
        }else if textField == correctionCell?.insulin{
            mutableString.replaceCharactersInRange(range, withString: string)
            mutableString.appendString(" units")
            textField.text = mutableString as String
            self.correctionCell?.insulin?.text = mutableString as String
           return false
        }else if textField == longLastingCell?.insulin{
            mutableString.replaceCharactersInRange(range, withString: string)
            mutableString.appendString(" units")
            textField.text = mutableString as String
            self.longLastingCell?.insulin?.text = mutableString as String
           return false
        }
 */
        return true
    }
    override func viewDidAppear(animated: Bool) {
        
        if self.tableView(tableView, titleForHeaderInSection: 0) != defaults!.objectForKey("configType") as? String{
            self.tableView.beginUpdates()
            self.configurationType  = defaults!.objectForKey("configType") as? String
            self.tableView.endUpdates()
            self.tableView.reloadData()
            self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Automatic)
        }
        if self.configurationType == "Full Meal" {
            self.bloodGlucoseCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0)) as? GlucoseCell
            self.carbCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 1, inSection: 0)) as? CarbCell
            self.carbCell?.carbs?.delegate = self
            self.bloodGlucoseCell?.bloodGlucose?.delegate = self
        }else if self.configurationType == "Long Lasting"{
            self.bloodGlucoseCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0)) as? GlucoseCell
            self.longLastingCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 1, inSection: 0)) as? LongLasting
            self.bloodGlucoseCell?.bloodGlucose?.delegate = self
            self.longLastingCell?.insulin!.delegate = self
        }else if self.configurationType == "Insulin Correction"{
            self.bloodGlucoseCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0)) as? GlucoseCell
            self.correctionCell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: 1, inSection: 0)) as? CorrectionCell
            self.bloodGlucoseCell?.bloodGlucose?.delegate = self
            self.correctionCell?.insulin!.delegate = self
        }
  
    }
    func buildImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: "pattern2.png"))
        imageView.frame = view.bounds
        imageView.contentMode = .ScaleAspectFill
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
    
    func uploadToHealthKit(bloodGlucoseLevel: Double, carbAmount: Double){
        


        var prefUnit: HKUnit?
         var prefUnitCarbs: HKUnit?
        let sampleType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)
        let sampleTypeCarbs = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)

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
                        prefUnitCarbs = preferredUnits[sampleTypeCarbs!]
						let quantity = HKQuantity(unit: prefUnit!, doubleValue: bloodGlucoseLevel)

						let quantitySample = HKQuantitySample(type: sampleType!, quantity: quantity, startDate: NSDate(), endDate: NSDate())
                        
                        let quantityCarbs = HKQuantity(unit: prefUnitCarbs!, doubleValue: carbAmount)
                        
                        let quantitySampleCarbs = HKQuantitySample(type: sampleTypeCarbs!, quantity: quantityCarbs, startDate: NSDate(), endDate: NSDate())

						self.healthStore.saveObjects([quantitySample, quantitySampleCarbs]) { (success, error) -> Void in
							if (success) {
								NSLog("Saved blood glucose level")
							}
                            print("Blood glucose: \(bloodGlucoseLevel)")
						}
					}
				})
			}
		}

  
        
   
        
        
    }
    func saveAndDie(){
        var beetusDictionary: NSMutableDictionary?
        if self.configurationType == "Full Meal" {
     
    
            beetusDictionary = ["type" : self.configurationType!, "bloodGlucose" : (self.bloodGlucoseCell?.bloodGlucose?.text)!, "carbs" : (self.carbCell?.carbs?.text)!, "insulin" : (self.intValue?.description)!, "date": NSDate()]
        }else if self.configurationType == "Insulin Correction" {
            beetusDictionary = ["type" : self.configurationType!, "bloodGlucose" : (self.bloodGlucoseCell?.bloodGlucose?.text)!, "insulin" : (self.intValue?.description)!, "date": NSDate(), "carbs" : "0"]
        }else if self.configurationType == "Long Lasting"{
            beetusDictionary = ["type" : self.configurationType!, "bloodGlucose" : (self.bloodGlucoseCell?.bloodGlucose?.text)!, "insulin" : (self.longLastingCell?.insulin?.text)!, "date": NSDate(), "carbs" : "0"]
        }
        
        
        if(self.carbCell != nil && self.configurationType == "Full Meal" && self.bloodGlucoseCell != nil) {
           self.uploadToHealthKit(Double((self.bloodGlucoseCell?.bloodGlucose?.text)!)!, carbAmount: Double((self.carbCell?.carbs?.text)!)!)
        }else{
            self.uploadToHealthKit(Double((self.bloodGlucoseCell?.bloodGlucose?.text)!)!, carbAmount: Double((0)))
        }
        var mealsArray: NSMutableArray?
        
        if objectAlreadyExist("meals") {
            mealsArray = (defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
        }else{
            mealsArray = NSMutableArray()
        }

        mealsArray?.insertObject(beetusDictionary!, atIndex: 0)
        
        defaults!.setObject(mealsArray, forKey: "meals")
        defaults!.synchronize()
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
                self.saveAndDie()
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
            self.intValue = Int(round(self.calculateCorrection()))
            if (correctionCell?.insulin?.text != "") {
                self.performSegueWithIdentifier("save", sender: self)
                self.saveAndDie()
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
                self.saveAndDie()
            } else {
                let alert = UIAlertController.init(title: "Error", message: "One or more fields are unset", preferredStyle: UIAlertControllerStyle.Alert)
                let ok = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                })
                alert.addAction(ok)
                self.presentViewController(alert, animated: true, completion: nil)
            }

        }
        
        
    }
   
	 func calculateInsulin() -> Double{
      
     
		var target: Double? = 120
		var ratio: Double? = 8
		var sensitivity: Double? = 30

		let glucose = Double((self.bloodGlucoseCell?.bloodGlucose!.text)!)

		var dosage: Double?

		if objectAlreadyExist("target") {
			target = defaults!.objectForKey("target")?.doubleValue
		}
		if objectAlreadyExist("ratio") {
			ratio = defaults!.objectForKey("ratio")?.doubleValue
		}
		if objectAlreadyExist("sensitivity") {
			sensitivity = defaults!.objectForKey("sensitivity")?.doubleValue
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
    func calculateCorrection() -> Double{
        
        var target: Double? = 120
        var sensitivity: Double? = 30
        
        let glucose = Double((self.bloodGlucoseCell?.bloodGlucose!.text)!)
        
        
        
        if objectAlreadyExist("target") {
            target = defaults!.objectForKey("target")?.doubleValue
        }

        if objectAlreadyExist("sensitivity") {
            sensitivity = defaults!.objectForKey("sensitivity")?.doubleValue
        }
        // Calulating correction
        var correction = glucose! - target!
        correction = correction / sensitivity!
        if correction < 0 {
            correction = 0
        }
        correction = round(correction)
        return correction
        
    }
	func objectAlreadyExist(key: String) -> Bool {
		return defaults!.objectForKey(key) != nil
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		let viewController = segue.destinationViewController as! SuccessViewController
		if configurationType == "Full Meal" {

			viewController.glucoseObject = [(self.intValue?.description)!]
            viewController.shouldShowMeal = true
		} else if configurationType == "Insulin Correction" {

			viewController.glucoseObject = [(self.intValue?.description)!]
			viewController.shouldShowMeal = false
		} else {
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
		} else if self.configurationType == "Long Lasting" && indexPath.row == 0 && cell == nil {
			cell = self.tableView.dequeueReusableCellWithIdentifier("bloodGlucose")
		} else if self.configurationType == "Long Lasting" && indexPath.row == 1   && cell == nil{
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
        if(configurationType == "Insulin Correction"){
            return 1
        }else{
            return 2
        }
	}

	@IBAction func dismissYoSelf() {
        
        self.dismissViewControllerAnimated(true, completion: { (action) in
            self.viewDidLoad()
        })
	}
}




