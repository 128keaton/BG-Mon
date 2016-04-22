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

let healthKitStore: HKHealthStore = HKHealthStore()

class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ChartViewDelegate {

	private var objects = [HKQuantityType!]()
	var preferredUnits = [NSObject: AnyObject]()
	var healthStore = HKHealthStore()

    @IBOutlet var hourSelector: UISegmentedControl?
	var sampleType: HKQuantityType!
	var preferredUnit: HKUnit!

	@IBOutlet var tableView: UITableView?

	@IBOutlet var lineChart: LineChartView?
	@IBOutlet weak var insulinChart: CombinedChartView?

    
	private var results = [HKQuantitySample]()
	var sampleInsulin = [Double]()
	let effect = UIBlurEffect(style: .Dark)
	let resizingMask = UIViewAutoresizing.FlexibleWidth
    

	var mealsArray: NSMutableArray?
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.configureGraphs()

        
        insulinChart!.delegate = self;
        
        insulinChart!.descriptionText = "";
        insulinChart!.noDataTextDescription = "Data will be loaded soon."
        
        insulinChart!.drawBarShadowEnabled = false
        insulinChart!.drawValueAboveBarEnabled = true

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
			mealsArray = (NSUserDefaults.standardUserDefaults().objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
		} else {
			mealsArray = NSMutableArray()
		}
		for object in mealsArray! {
			let meal = object["insulin"] as! String

                sampleInsulin.append(Double(meal)!)
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
                insulinVals.append(BarChartDataEntry(value: self.sampleInsulin[i], xIndex: i))
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
        chartDataSet.drawCubicEnabled = true
        chartDataSet.fill = ChartFill(color: UIColor.clearColor())
        let barChartDataSet = BarChartDataSet(yVals: insulinVals, label: "Insulin Units")
        barChartDataSet.valueTextColor = UIColor.whiteColor()
        barChartDataSet.setColor(UIColor.greenColor(), alpha: 1.0)
   
        let data: CombinedChartData = CombinedChartData(xVals: timeVals)
        data.barData = BarChartData(xVals: timeVals, dataSets: [barChartDataSet])
        data.lineData = LineChartData(xVals: timeVals, dataSets: [chartDataSet])
        data.setValueTextColor(UIColor.whiteColor())
        self.insulinChart?.gridBackgroundColor = UIColor.clearColor()
        self.insulinChart?.scaleXEnabled = false
        
        self.insulinChart!.xAxis.labelPosition = .Bottom
        self.insulinChart?.scaleYEnabled = false
  
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
		return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
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
		let cell = self.tableView?.dequeueReusableCellWithIdentifier("cell") as! MealCell
		let sample = self.results[indexPath.row];

		let doubleValue = sample.quantity.doubleValueForUnit(self.preferredUnit)

		cell.bloodGlucose!.text = "\(doubleValue)\nmg/dL"
		if indexPath.row < self.sampleInsulin.count {
            let integer = Int(self.sampleInsulin[indexPath.row])
			cell.insulin?.text = "\(integer)\nunits"
			let formatter = NSDateFormatter()
			formatter.dateStyle = .ShortStyle
			formatter.timeStyle = .ShortStyle
			if (indexPath.row < self.mealsArray?.count && self.mealsArray != nil) {
                let stopIT = self.mealsArray![indexPath.row];
				let xcodeSTOPBREAKING = stopIT["date"] as! NSDate
				let REALLYITSGETTINGOLD = stopIT["carbs"] as! String
				cell.time?.text = formatter.stringFromDate(xcodeSTOPBREAKING)
				cell.carbs!.text = "\(REALLYITSGETTINGOLD)\ncarbs"
			}
		} else {
			cell.insulin?.text = "No data"
		}
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
		cell.backgroundColor = UIColor.clearColor()
		cell.contentView.backgroundColor = UIColor.clearColor()
		if (indexPath.row < mealsArray?.count) {
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
        }else{
            cell.mealType?.image = UIImage.init(named: "HealthKit_iOS_8_icon.png")
            cell.type?.text = "Fetched from Health"
            cell.carbs?.text = "No data"
            let formatter = NSDateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            formatter.timeStyle = .ShortStyle
            cell.time?.text = formatter.stringFromDate(self.results[indexPath.row].startDate)
            cell.insulinLabel?.hidden = true
            cell.carbLabel?.hidden = true
            cell.carbs?.hidden = true
            cell.insulin?.hidden = true
            
            cell.bloodGlucose?.autoresizingMask = .FlexibleWidth
            cell.bloodGlucose?.center = cell.center
         
        }

		return cell
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
					NSUserDefaults.standardUserDefaults().setDouble(maxArray.maxElement()!, forKey: "highscore")
					NSUserDefaults.standardUserDefaults().setDouble(maxArray.minElement()!, forKey: "lowscore")
					NSUserDefaults.standardUserDefaults().synchronize()
				}
      
				NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    if self.objectAlreadyExist("meals") {
                        self.mealsArray = (NSUserDefaults.standardUserDefaults().objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
                    } else {
                        self.mealsArray = NSMutableArray()
                    }
                    self.sampleInsulin.removeAll()
                    for object in self.mealsArray! {
                        let meal = object["insulin"] as! String
                        
       
                        self.sampleInsulin.append(Double(meal)!)
                    }
					self.tableView!.reloadData()
                    self.insulinChart?.notifyDataSetChanged()
                    self.configureGraphs()
	
				})
			}
		
		}

		self.healthStore.executeQuery(query)
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


