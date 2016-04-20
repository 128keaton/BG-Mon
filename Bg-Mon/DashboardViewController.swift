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
        
		if objectAlreadyExist("meals") {
			mealsArray = (NSUserDefaults.standardUserDefaults().objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
		} else {
			mealsArray = NSMutableArray()
		}
		for object in mealsArray! {
			let meal = object["insulin"] as! String

            print("Insulin \(object["insulin"])")
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
    func configureGraphs(){
        
       
        
        let timeVals = ["8:00", "12:00", "4:00"];
        var insulinVals: [BarChartDataEntry] = []
        var bgVals: [ChartDataEntry] = [ChartDataEntry]()
        for i in 0..<self.sampleInsulin.count{
            insulinVals.append(BarChartDataEntry(value: self.sampleInsulin[i], xIndex: i))
        }
        for i in 0..<self.results.count{
            let sample = self.results[i];
            
            let doubleValue = sample.quantity.doubleValueForUnit(self.preferredUnit)
            bgVals.append(ChartDataEntry(value: doubleValue, xIndex: i))
            
        }
        
        let chartDataSet = LineChartDataSet(yVals: bgVals, label: "Blood Glucose")
        chartDataSet.setColor(self.view.tintColor, alpha: 1.0);
        chartDataSet.axisDependency = .Left
        
        chartDataSet.fill = ChartFill(color: UIColor.blackColor())
        let barChartDataSet = BarChartDataSet(yVals: insulinVals, label: "Insulin Units")
        barChartDataSet.valueTextColor = UIColor.whiteColor()
        barChartDataSet.barSpace = 0.25
        let data: CombinedChartData = CombinedChartData(xVals: timeVals)
        data.barData = BarChartData(xVals: timeVals, dataSets: [barChartDataSet])
        data.lineData = LineChartData(xVals: timeVals, dataSets: [chartDataSet])
        data.setValueTextColor(UIColor.whiteColor())
        insulinChart?.gridBackgroundColor = UIColor.clearColor()
        insulinChart?.scaleXEnabled = false
        
        insulinChart?.scaleYEnabled = false

        insulinChart?.data = data
        insulinChart?.xAxis.labelTextColor = UIColor.whiteColor()
    
        self.view.reloadInputViews()
        
        
    }

	func objectAlreadyExist(key: String) -> Bool {
		return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
	}


	override func viewDidAppear(animated: Bool) {
		self.authorizeHealthKit(nil)
		self.tableView!.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Automatic)

		let query = HKObserverQuery(sampleType: self.sampleType, predicate: nil) { (query, completionHandler, error) -> Void in
			NSLog("Observer fired for .... %@", query.sampleType!.identifier);
			if (error == nil) {
				self.refreshData()
			}
		}

		self.healthStore.executeQuery(query)

		super.viewDidAppear(true)
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.tableView?.deselectRowAtIndexPath(indexPath, animated: true)
	}
	@IBAction func openMenu() {
		openLeft()
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

	func buildImageView() -> UIImageView {
		let imageView = UIImageView(image: UIImage(named: "bananas.jpg"))
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

					self.tableView!.reloadData()
                    self.configureGraphs()
	
				})
			}
			NSLog("Results %@", self.results)
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