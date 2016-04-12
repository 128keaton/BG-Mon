//
//  DashboardViewController.swift
//
//
//  Created by Keaton Burleson on 4/4/16.
//
//

import Foundation
import UIKit
import BEMSimpleLineGraph
import HealthKit
let healthKitStore: HKHealthStore = HKHealthStore()

class DashboardViewController: UIViewController, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource, UITableViewDataSource, UITableViewDelegate {

	private var objects = [HKQuantityType!]()
	var preferredUnits = [NSObject: AnyObject]()
	var healthStore = HKHealthStore()

	var sampleType: HKQuantityType!
	var preferredUnit: HKUnit!

	@IBOutlet var tableView: UITableView?

	@IBOutlet var lineChart: BEMSimpleLineGraphView?
	@IBOutlet var insulinChart: BEMSimpleLineGraphView?

	private var results = [HKQuantitySample]()
	var sampleInsulin = [CGFloat]()
	let effect = UIBlurEffect(style: .Dark)
	let resizingMask = UIViewAutoresizing.FlexibleWidth

	var mealsArray: NSMutableArray?
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	override func viewDidLoad() {
		super.viewDidLoad()

		lineChart?.delegate = self
		lineChart?.dataSource = self
		lineChart?.enableBezierCurve = true
		lineChart?.autoScaleYAxis = true
		lineChart?.colorLine = UIColor.greenColor()

		insulinChart?.backgroundColor = UIColor.clearColor()
		insulinChart?.delegate = self
		insulinChart?.dataSource = self
		insulinChart?.enableBezierCurve = true
		insulinChart?.autoScaleYAxis = true
		insulinChart?.colorLine = UIColor.orangeColor()

        if results.count == 0 && sampleInsulin.count == 0 {
            insulinChart?.noDataLabelColor = UIColor.clearColor()
          
        }
		insulinChart?.alwaysDisplayDots = true
		insulinChart?.enableTouchReport = true
		insulinChart?.enablePopUpReport = true
		insulinChart?.positionYAxisRight = true
		lineChart?.alwaysDisplayDots = true
		lineChart?.enableTouchReport = true
		lineChart?.enablePopUpReport = true
		lineChart?.enableYAxisLabel = true
		lineChart?.colorYaxisLabel = UIColor.whiteColor()
		lineChart?.autoScaleYAxis = true

		insulinChart?.animationGraphStyle = .Expand
		insulinChart?.enableYAxisLabel = true
		insulinChart?.colorYaxisLabel = UIColor.whiteColor()
		insulinChart?.colorXaxisLabel = UIColor.whiteColor()

		insulinChart?.enableReferenceAxisFrame = true
		lineChart?.enableReferenceYAxisLines = true
		insulinChart?.enableReferenceXAxisLines = true
		insulinChart?.colorReferenceLines = UIColor.whiteColor()
		let backgroundView = UIView.init(frame: self.view.frame)

		lineChart?.backgroundColor = UIColor.clearColor()
		lineChart?.alphaTop = 0
		lineChart?.alphaBottom = 0

		backgroundView.autoresizingMask = resizingMask
		backgroundView.addSubview(self.buildImageView())
		backgroundView.addSubview(self.buildBlurView())
		lineChart?.addSubview(backgroundView)
		lineChart?.sendSubviewToBack(backgroundView)
		tableView!.backgroundView = backgroundView
		tableView!.separatorEffect = UIVibrancyEffect(forBlurEffect: effect)

		if objectAlreadyExist("meals") {
			mealsArray = (NSUserDefaults.standardUserDefaults().objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
		} else {
			mealsArray = NSMutableArray()
		}
		for object in mealsArray! {
			let meal = object["insulin"] as! NSString

			let doubleValue = CGFloat(meal.doubleValue)
			sampleInsulin.append(doubleValue)
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
    
	func lineGraph(graph: BEMSimpleLineGraphView, labelOnXAxisForIndex index: Int) -> String? {
		if (graph == insulinChart) {
			let formatter = NSDateFormatter()
			formatter.dateFormat = "hh:mm"
			if (mealsArray != nil && index < mealsArray?.count) {
				let dateString = formatter.stringFromDate(self.mealsArray![index]["date"] as! NSDate)

				return dateString
			} else {
				return ""
			}
		} else {
			return ""
		}
	}
	func yAxisSuffixOnLineGraph(graph: BEMSimpleLineGraphView) -> String {
		if graph == insulinChart {
			return " units  "
		} else {
			return " mg/dL"
		}
	}

	func objectAlreadyExist(key: String) -> Bool {
		return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
	}

	func incrementIndexForXAxisOnLineGraph(graph: BEMSimpleLineGraphView) -> Int {
		return 10
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
	func lineGraph(graph: BEMSimpleLineGraphView, didTouchGraphWithClosestIndex index: Int) {
		self.tableView?.selectRowAtIndexPath(NSIndexPath.init(forRow: index, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.Top)
	}
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.tableView?.deselectRowAtIndexPath(indexPath, animated: true)
	}
	@IBAction func openMenu() {
		openLeft()
	}

	func popUpSuffixForlineGraph(graph: BEMSimpleLineGraphView) -> String {
		if graph == insulinChart {
			return " units"
		} else {
			return " mg/Dl"
		}
	}

	func noDataLabelTextForLineGraph(graph: BEMSimpleLineGraphView) -> String {
		if graph == insulinChart {
			return "No insulin data"
		} else {
			return "No blood glucose data"
		}
	}

	func lineGraph(graph: BEMSimpleLineGraphView, alwaysDisplayPopUpAtIndex index: CGFloat) -> Bool {
		return true
	}

	func determinePoint(bloodGlucoseLevel: Double) -> CGFloat {
		return CGFloat(bloodGlucoseLevel)
	}
	func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
		if graph != insulinChart {
			return results.count
		} else {
			return sampleInsulin.count
		}
	}
	func lineGraph(graph: BEMSimpleLineGraphView, valueForPointAtIndex index: Int) -> CGFloat {
		if graph != insulinChart {

			let sample = self.results[index];

			let doubleValue = sample.quantity.doubleValueForUnit(self.preferredUnit)
			return determinePoint(doubleValue)
		} else {
			print("Sample: \(sampleInsulin[index])")
			return sampleInsulin[index]
		}
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
				let xcodeSTOPBREAKING = self.mealsArray![indexPath.row]["date"] as! NSDate
				let REALLYITSGETTINGOLD = self.mealsArray![indexPath.row]["carbs"] as! String
				cell.time?.text = formatter.stringFromDate(xcodeSTOPBREAKING)
				cell.carbs!.text = "\(REALLYITSGETTINGOLD)\ngrams"
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
            
            cell.bloodGlucose?.center = cell.center
            cell.bloodGlucoseLabel?.center = CGPointMake((cell.bloodGlucoseLabel?.center.x)!, cell.center.y)
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
					self.insulinChart?.reloadGraph()
					self.lineChart?.reloadGraph()
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