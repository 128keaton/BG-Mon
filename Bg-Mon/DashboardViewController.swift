//
//  DashboardViewController.swift
//
//
//  Created by Keaton Burleson on 4/4/16.
//
//

import Foundation
import UIKit
import Charts
import HealthKit
import BTNavigationDropdownMenu
import MessageUI
import Photos
import EZAlertController

let healthKitStore: HKHealthStore = HKHealthStore()

class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ChartViewDelegate, MFMailComposeViewControllerDelegate {

	private var objects = [HKQuantityType!]()
	var preferredUnits = [NSObject: AnyObject]()
	var healthStore = HKHealthStore()

    var menuView: BTNavigationDropdownMenu?
    var nav: UINavigationController?
    
    @IBOutlet var hourSelector: UISegmentedControl?
	var sampleType: HKQuantityType!
	var preferredUnit: HKUnit!

	@IBOutlet var tableView: UITableView?

	@IBOutlet var lineChart: LineChartView?
	@IBOutlet weak var insulinChart: CombinedChartView?

    var addViewController: AddMeal?
    
    
	private var results = [HKQuantitySample]()
	var sampleInsulin = [Double]()
	let effect = UIBlurEffect(style: .Dark)
	let resizingMask = UIViewAutoresizing.FlexibleWidth
    let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")

	var mealsArray: NSMutableArray?
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.configureGraphs()
        
        
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
        menuView?.cellBackgroundColor = UIColor.blackColor()
        menuView?.cellTextLabelColor = UIColor.whiteColor()
        self.tableView!.backgroundColor = UIColor.blackColor()
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
            self.defaults!.setObject(configType?.rawValue, forKey: "configType")
            self.defaults!.synchronize()
            
            self.navigationController!.presentViewController(addViewControllerNavigation, animated: true, completion: nil)
            
            
            
            configType = nil
            self.addViewController = nil
        }

        insulinChart!.delegate = self;
        
        insulinChart!.descriptionText = "";
        insulinChart!.noDataTextDescription = "Data will be loaded soon."
        
        insulinChart!.drawBarShadowEnabled = false
        insulinChart!.drawValueAboveBarEnabled = true
        insulinChart?.scaleXEnabled = true
        insulinChart?.scaleYEnabled = true
        insulinChart!.maxVisibleValueCount = 60
        insulinChart!.pinchZoomEnabled = false
        insulinChart!.drawGridBackgroundEnabled = true
        insulinChart!.drawBordersEnabled = false
        insulinChart?.gridBackgroundColor = UIColor.clearColor()
        insulinChart!.maxVisibleValueCount = 15
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = resizingMask
        backgroundView.addSubview(self.buildImageView())
        backgroundView.addSubview(self.buildBlurView())
        
        self.view.addSubview(backgroundView)
        
        tableView!.backgroundView = backgroundView
        tableView!.separatorEffect = UIVibrancyEffect(forBlurEffect: effect)
        
		if objectAlreadyExist("meals") {
			mealsArray = (defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
		} else {
			mealsArray = NSMutableArray()
		}
		for object in mealsArray! {
            if object["insulin"] is String {
                let meal = object["insulin"] as! String
                
                sampleInsulin.append(Double(meal)!)
            }else{
                let meal = object["insulin"] as! Double
                
                sampleInsulin.append(meal)
            }
           
		}

		sampleType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)

		let healthKitTypes = Set<HKQuantityType>(arrayLiteral: sampleType)

		healthStore.preferredUnitsForQuantityTypes(healthKitTypes, completion: { (preferredUnits, error) -> Void in
			if (error == nil) {
				NSLog("...preferred units %@", preferredUnits)
				self.preferredUnits = preferredUnits
				self.preferredUnit = preferredUnits[self.sampleType]
			}
		})

		let query = HKObserverQuery(sampleType: self.sampleType, predicate: nil) { (query, completionHandler, error) -> Void in
			NSLog("Observer fired for .... %@", query.sampleType!.identifier);
			if (error == nil) {
				self.refreshData()
			}
		}

		self.healthStore.executeQuery(query)
	}
    @IBAction func configureForSegment(){
        
            self.refreshData()
    
    }
    @IBAction func addMeal() {
        menuView?.show()
    }
    
    func configureGraphs(){
        let serialQueue: dispatch_queue_t = dispatch_queue_create("com.128keaton.refreshQueue", nil)
        
        dispatch_sync(serialQueue, { () -> Void in
       
        
      
    
        var insulinVals: [BarChartDataEntry] = []
        var bgVals: [ChartDataEntry] = [ChartDataEntry]()

        for i in 0..<self.sampleInsulin.count{
      
            let stopIT = self.mealsArray![i];
            let now = stopIT["date"] as! NSDate
          

            let then = self.getThen()
            
            if (now.isBetweeen(date: then, andDate: NSDate())){
                if(self.sampleInsulin[i] < 400){
                        insulinVals.append(BarChartDataEntry(value: self.sampleInsulin[i], xIndex: i))
                }else{
                        insulinVals.append(BarChartDataEntry(value: self.sampleInsulin[i], xIndex: i))
                }
                

                let sample = self.results[i];
                let sampleType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)
                let prefUnit = self.preferredUnits[sampleType!]
                let doubleValue = sample.quantity.doubleValueForUnit(prefUnit as! HKUnit)
                bgVals.append(ChartDataEntry(value: doubleValue, xIndex: i))
            }
           
        }
     
        let timeVals = self.getYAxisCount(self.sampleInsulin.count)
        let chartDataSet = LineChartDataSet(yVals: bgVals, label: "Blood Glucose")
        chartDataSet.setColor(self.view.tintColor, alpha: 1.0);
        chartDataSet.axisDependency = .Left
        chartDataSet.mode = LineChartDataSet.Mode.CubicBezier
        chartDataSet.fill = ChartFill(color: UIColor.clearColor())
        let barChartDataSet = BarChartDataSet(yVals: insulinVals, label: "Insulin Units")
        barChartDataSet.valueTextColor = UIColor.whiteColor()
        barChartDataSet.setColor(UIColor.greenColor(), alpha: 1.0)
   
        let data: CombinedChartData = CombinedChartData(xVals: timeVals)
        data.barData = BarChartData(xVals: timeVals, dataSets: [barChartDataSet])
        data.lineData = LineChartData(xVals: timeVals, dataSets: [chartDataSet])
        data.setValueTextColor(UIColor.whiteColor())
        self.insulinChart?.gridBackgroundColor = UIColor.blackColor()
        self.insulinChart?.backgroundColor = UIColor.blackColor()
        
        self.insulinChart?.legend.textColor = UIColor.whiteColor()
        
        self.insulinChart!.xAxis.labelPosition = .Bottom
        self.insulinChart!.animate(xAxisDuration: 0.5, yAxisDuration: 1.0)

  
        self.insulinChart?.data = data
        self.insulinChart?.xAxis.labelTextColor = UIColor.whiteColor()
    
        self.view.reloadInputViews()
             })
        
    
    }
    func getThen() -> NSDate{
        switch Int((hourSelector?.selectedSegmentIndex)!) {
        case 0:
            return NSDate().dateByAddingTimeInterval(-21600)
         
        case 1:
            return NSDate().dateByAddingTimeInterval(-43200)
          
        case 2:
            return NSDate().dateByAddingTimeInterval(-86400)
         
        default:
            return NSDate().dateByAddingTimeInterval(-21600)
        }
    }
    func getYAxisCount(count: Int) -> [String]{

        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .NoStyle
        var hours: [String] = []
        for i in 0..<count {
            hours.append(formatter.stringFromDate(NSDate().dateByAddingTimeInterval(-60*Double(i))))
        }
       // insulinChart?.scaleY = CGFloat(count)
        return hours
        
        
    }
    
	func objectAlreadyExist(key: String) -> Bool {
		return defaults!.objectForKey(key) != nil
	}


	override func viewDidAppear(animated: Bool) {
		let serialQueue: dispatch_queue_t = dispatch_queue_create("com.128keaton.refreshQueue", nil)

		dispatch_sync(serialQueue, { () -> Void in
			self.authorizeHealthKit(nil)
			self.tableView!.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Automatic)

			let query = HKObserverQuery(sampleType: self.sampleType, predicate: nil) { (query, completionHandler, error) -> Void in
				NSLog("Observer fired for .... %@", query.sampleType!.identifier);
				if (error == nil) {
					self.refreshData()
				}
				self.insulinChart?.notifyDataSetChanged()
			}

			self.healthStore.executeQuery(query)
		})
		super.viewDidAppear(true)
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        insulinChart?.highlightValue(ChartHighlight.init(xIndex: indexPath.row, dataSetIndex: 0))
		self.tableView?.deselectRowAtIndexPath(indexPath, animated: true)
	}
	@IBAction func openMenu() {
		openLeft()
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
    

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return results.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

		if (indexPath.row < mealsArray?.count) {
            let cell = self.tableView?.dequeueReusableCellWithIdentifier("cell") as! MealCell
            let sample = self.results[indexPath.row];
            
            if indexPath.row < self.sampleInsulin.count {
                let integer = Int(self.sampleInsulin[indexPath.row])
                cell.insulin?.text = "\(integer)\nunits"
                let formatter = NSDateFormatter()
                formatter.dateStyle = .ShortStyle
                formatter.timeStyle = .ShortStyle
                if (indexPath.row < self.mealsArray?.count && self.mealsArray != nil) {
                    let stopIT = self.mealsArray![indexPath.row];
                    let xcodeSTOPBREAKING = stopIT["date"] as! NSDate
                    let REALLYITSGETTINGOLD = stopIT["carbs"]
                    if(REALLYITSGETTINGOLD is String){
                        cell.carbs!.text = "\(REALLYITSGETTINGOLD as! String)\ncarbs"
                    }else{
                        cell.carbs!.text = "\(REALLYITSGETTINGOLD as! Double)\ncarbs"
                    }
                    cell.time?.text = formatter.stringFromDate(xcodeSTOPBREAKING)
                    
                }
            } else {
                cell.insulin?.text = "No data"
            }
            cell.bloodGlucose?.layer.cornerRadius = 5
            cell.bloodGlucose?.clipsToBounds = true
            cell.bloodGlucose?.backgroundColor = self.view.tintColor
            cell.bloodGlucose?.textColor = UIColor.whiteColor()
            
            let doubleValue = sample.quantity.doubleValueForUnit(self.preferredUnit)
            
            cell.bloodGlucose!.text = "\(doubleValue)\nmg/dL"

            
            
            cell.carbs?.textColor = UIColor.blackColor()
            cell.carbs?.layer.cornerRadius = 5
            cell.carbs?.clipsToBounds = true
            cell.carbs?.backgroundColor = UIColor.whiteColor()
            
            cell.insulin?.layer.cornerRadius = 5
            
            cell.insulin?.clipsToBounds = true
            cell.insulin?.backgroundColor = UIColor.greenColor()
            
            cell.time?.textColor = UIColor.whiteColor()
            cell.time?.clipsToBounds = true
            cell.time?.layer.cornerRadius = 5
            cell.backgroundColor = UIColor.clearColor()
            cell.contentView.backgroundColor = UIColor.clearColor()
            
			let type = mealsArray![indexPath.row]["type"] as! String
			if (type == "Full Meal") {
				cell.mealType?.image = UIImage.init(named: "Meal.png")
			} else if (type == "Insulin Correction") {
				cell.mealType?.image = UIImage.init(named: "Adjustment.png")
			} else if (type == "Long Lasting") {
				cell.mealType?.image = UIImage.init(named: "24H.png")
			}
            cell.insulinLabel?.hidden = false
            cell.carbLabel?.hidden = false
            cell.carbs?.hidden = false
            cell.insulin?.hidden = false
            return cell
        }else{
            let cell = self.tableView?.dequeueReusableCellWithIdentifier("healthkit") as! HealthKitCell
            let sample = self.results[indexPath.row];
            
            let doubleValue = sample.quantity.doubleValueForUnit(self.preferredUnit)
            
            cell.bloodGlucose!.text = "\(doubleValue)\nmg/dL"
            cell.bloodGlucose?.layer.cornerRadius = 5
            cell.bloodGlucose?.clipsToBounds = true
            cell.bloodGlucose?.backgroundColor = self.view.tintColor
            cell.bloodGlucose?.textColor = UIColor.whiteColor()
            
            
            cell.time?.textColor = UIColor.whiteColor()
            cell.time?.clipsToBounds = true
            cell.time?.layer.cornerRadius = 5
            cell.backgroundColor = UIColor.clearColor()
            cell.contentView.backgroundColor = UIColor.clearColor()
            
            cell.mealType?.image = UIImage.init(named: "HealthKit_iOS_8_icon.png")
            let formatter = NSDateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            formatter.timeStyle = .ShortStyle
            formatter.dateStyle = .ShortStyle
            cell.time?.text = formatter.stringFromDate(self.results[indexPath.row].startDate)
            
            cell.bloodGlucose?.autoresizingMask = .FlexibleWidth
            cell.bloodGlucose?.center = cell.center
            return cell
        }

	}


    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        let row = entry.xIndex
       self.tableView?.selectRowAtIndexPath(NSIndexPath.init(forRow: row, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.Top)
    }
	private func refreshData() {
		NSLog("refreshData......")
		let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
		let query = HKSampleQuery(sampleType: self.sampleType, predicate: nil, limit: 0, sortDescriptors: [timeSortDescriptor]) { (query, objects, error) -> Void in
			if (error == nil) {
				self.results = objects as! [HKQuantitySample]
				var maxArray = Array<Double>()
				for sample in self.results {
					let doubleValue = sample.quantity.doubleValueForUnit(self.preferredUnit)
					maxArray.append(doubleValue)
				}

				if (maxArray.maxElement() != nil) {
					self.defaults!.setDouble(maxArray.maxElement()!, forKey: "highscore")
					self.defaults!.setDouble(maxArray.minElement()!, forKey: "lowscore")
                    let averageOfMgDL = maxArray.reduce(0, combine: +) / Double(maxArray.count)
                    self.defaults?.setDouble(averageOfMgDL, forKey: "average")
					self.defaults!.synchronize()
				}
               
				NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    if self.objectAlreadyExist("meals") {
                        self.mealsArray = (self.defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
                    } else {
                        
                        self.mealsArray = NSMutableArray()
                    }
                    self.sampleInsulin.removeAll()
                    for object in self.mealsArray! {
                       
                        
                        if object["insulin"] is String {
                            let meal = object["insulin"] as! String
                            
                            self.sampleInsulin.append(Double(meal)!)
                        }else{
                            let meal = object["insulin"] as! Double
                            
                            self.sampleInsulin.append(meal)
                        }
                        
       
                        
                    }
					self.tableView!.reloadData()
                    self.insulinChart?.notifyDataSetChanged()
                    self.configureGraphs()
	
				})
			}
		
		}

		self.healthStore.executeQuery(query)
	}



    @IBAction func export(){
        let alertController = UIAlertController.init(title: "Export", message: "What data would you like to email your doctor in?", preferredStyle: .ActionSheet)
        let export = UIAlertAction.init(title: "Database of all logs", style: .Default, handler: { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
            let writeString = NSMutableString.init(capacity: 0)
            let formatter = NSDateFormatter.init()
            formatter.dateStyle = .ShortStyle
            formatter.timeStyle = .ShortStyle
            for i in 0..<self.sampleInsulin.count{
                let object = self.results[i]
                let doubleValue = object.quantity.doubleValueForUnit(self.preferredUnit)
                writeString.appendString("\(doubleValue) mg/dL, \(formatter.stringFromDate(self.results[i].startDate)), \r\n")
                
            }
            self.sendEmail(NSData(), csv: writeString.dataUsingEncoding(NSUTF8StringEncoding)!, options: ["csv" : true, "snapshot" : false])

            
        })
        
        let snapshot = UIAlertAction.init(title: "Snapshot of Graph", style: .Default, handler: { (action) in
          
            
            self.sendEmail(UIImagePNGRepresentation((self.insulinChart?.getSnapshot())!)!, csv: NSData(), options: ["csv" : false, "snapshot" : true])
        
        })

        let cancel = UIAlertAction.init(title: "Cancel", style: .Cancel, handler: { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)

        })
        alertController.addAction(export)
        alertController.addAction(snapshot)
        alertController.addAction(cancel)
        self.presentViewController(alertController, animated: true, completion: nil)
        
        
    }
    
    func sendEmail(snapshot: NSData, csv: NSData, options: NSDictionary) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
      
            mail.setSubject("Insulin and Blood Glucose Graph \(NSDate())")
            if defaults!.objectForKey("dr-email") != nil &&  defaults!.objectForKey("dr-name") != nil{
                if(isValidEmail(defaults!.objectForKey("dr-email") as! String) == false){
                    EZAlertController.alert("Invalid email", message: "The email for your doctor is invalid", acceptMessage: "OK") { () -> () in
                        print("Accepted their fate")
                    }
                }
                      mail.setToRecipients([defaults!.objectForKey("dr-email") as! String])
                mail.setMessageBody("Dear \(defaults!.objectForKey("dr-name") as! String), <br> Enclosed is a copy of my blood sugar and insulin data. Hope this is good news!", isHTML: true)
            }
            if options["csv"] as! Bool != false {
                mail.addAttachmentData(csv, mimeType: "text/csv", fileName: "Data \(NSDate()).csv")
            }
            if options["snapshot"] as! Bool != false {
                mail.addAttachmentData(snapshot, mimeType: "image/png", fileName: "Data \(NSDate()).png")
            }
 
            presentViewController(mail, animated: true, completion: nil)
        } else {
            // show failure alert
        }
    }
    func isValidEmail(testStr:String) -> Bool {
        // println("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
	func authorizeHealthKit(completion: ((success: Bool, error: NSError!) -> Void)!)
	{
		let carbs = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)
		let bloodGlucose = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)

		let healthKitTypes = Set<HKQuantityType>(arrayLiteral: carbs!, bloodGlucose!)

		self.healthStore.requestAuthorizationToShareTypes(healthKitTypes as Set, readTypes: healthKitTypes as Set) { (success, error) -> Void in
			if (success) {
				NSLog("HealthKit authorization success...")

				self.healthStore.preferredUnitsForQuantityTypes(healthKitTypes as Set, completion: { (preferredUnits, error) -> Void in
					if (error == nil) {
						NSLog("...preferred units %@", preferredUnits)
						self.preferredUnits = preferredUnits
					}
				})
			}
		}

		self.objects = [carbs, bloodGlucose]
	}
}



extension NSDate
{
    func isBetween(date: NSDate, blackDate: NSDate)-> Bool{
        if (NSDate().laterDate(date) == NSDate()) && (NSDate().laterDate(blackDate) == blackDate)  {
            return true
        }
        return false
    }
    
    func isBetweeen(date date1: NSDate, andDate date2: NSDate) -> Bool {
        return date1.compare(self) == self.compare(date2)
    }

    /**
     This adds a new method dateAt to NSDate.
     
     It returns a new date at the specified hours and minutes of the receiver
     
     :param: hours: The hours value
     :param: minutes: The new minutes
     
     :returns: a new NSDate with the same year/month/day as the receiver, but with the specified hours/minutes values
     */
    func dateAt(hours: Int, minutes: Int) -> NSDate
    {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        //get the month/day/year componentsfor today's date.
        
        print("Now = \(self)")
        
        let date_components = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month,NSCalendarUnit.Day], fromDate: self)
        
        //Create an NSDate for 8:00 AM today.
        date_components.hour = hours
        date_components.minute = minutes
        date_components.second = 0
        
        let newDate = calendar.dateFromComponents(date_components)!
        return newDate
    }
}
//-------------------------------------------------------------
//Tell the system that NSDates can be compared with ==, >, >=, <, and <= operators
extension NSDate: Comparable {}

//-------------------------------------------------------------
//Define the global operators for the
//Equatable and Comparable protocols for comparing NSDates

public func ==(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 == rhs.timeIntervalSince1970
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
}
public func >(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 > rhs.timeIntervalSince1970
}
public func <=(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 <= rhs.timeIntervalSince1970
}
public func >=(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.timeIntervalSince1970 >= rhs.timeIntervalSince1970
}
//-------------------------------------------------------------


