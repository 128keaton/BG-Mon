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
	private var preferredUnits = [NSObject: AnyObject]()
	private var healthStore = HKHealthStore()

	var sampleType: HKQuantityType!
	var preferredUnit: HKUnit!

	
	@IBOutlet var tableView: UITableView?

	@IBOutlet var lineChart: BEMSimpleLineGraphView?
	@IBOutlet var insulinChart: BEMSimpleLineGraphView?

	private var results = [HKQuantitySample]()
	var sampleInsulin = [CGFloat]()

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
        
        insulinChart?.alwaysDisplayPopUpLabels = true
        lineChart?.alwaysDisplayPopUpLabels = true

        
        
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
	override func viewDidAppear(animated: Bool) {
		self.authorizeHealthKit(nil)
		super.viewDidAppear(true)
	}
    func lineGraph(graph: BEMSimpleLineGraphView, didTouchGraphWithClosestIndex index: Int) {
        self.tableView?.selectRowAtIndexPath(NSIndexPath.init(forRow: index, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.None)
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       self.tableView?.deselectRowAtIndexPath(indexPath, animated: true)
    }
    @IBAction func openMenu(){
        openLeft()
    }
    
    func popUpSuffixForlineGraph(graph: BEMSimpleLineGraphView) -> String {
        if graph == insulinChart {
            return " units"
        }else{
            return " mg/Dl"
        }
    }
	func maxValueForLineGraph(graph: BEMSimpleLineGraphView) -> CGFloat {
        if(graph != insulinChart){
		return 1000
        } else{
                return 25
            }
	}
    func lineGraph(graph: BEMSimpleLineGraphView, alwaysDisplayPopUpAtIndex index: CGFloat) -> Bool {
        return true
    }
	func minValueForLineGraph(graph: BEMSimpleLineGraphView) -> CGFloat {
        if(graph != insulinChart){
            return 0
        }else{
            return 1
        }
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
			return sampleInsulin[index]
		}
	}
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return results.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.tableView?.dequeueReusableCellWithIdentifier("cell") as! SuperCell
		let sample = self.results[indexPath.row];

		let doubleValue = sample.quantity.doubleValueForUnit(self.preferredUnit)

		cell.bloodGlucose!.text = "\(doubleValue) mg/dL"
        cell.insulin?.text = "\(self.sampleInsulin[indexPath.row]) units"
        
		return cell
	}
	private func refreshData() {
		NSLog("refreshData......")
		let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
		let query = HKSampleQuery(sampleType: self.sampleType, predicate: nil, limit: 0, sortDescriptors: [timeSortDescriptor]) { (query, objects, error) -> Void in
			if (error == nil) {
				self.results = objects as! [HKQuantitySample]
                var maxArray = Array<Double>()
                for sample in self.results{
                    let doubleValue = sample.quantity.doubleValueForUnit(self.preferredUnit)
                    maxArray.append(doubleValue)
                }
                for _ in self.results {
                    
                    self.sampleInsulin.append(CGFloat(arc4random_uniform(20) + 1))
                }
        
                
                NSUserDefaults.standardUserDefaults().setDouble(maxArray.maxElement()!, forKey: "highscore")
                NSUserDefaults.standardUserDefaults().setDouble(maxArray.minElement()!, forKey: "lowscore")
                NSUserDefaults.standardUserDefaults().synchronize()
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