//
//  AveragesViewController.swift
//  Logglu
//
//  Created by Keaton Burleson on 5/10/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import GaugeKit
class AveragesViewController: UIViewController {

	@IBOutlet var bgLabel: UILabel?
	@IBOutlet var carbLabel: UILabel?
	@IBOutlet var bgGauge: Gauge?
	@IBOutlet var carbGauge: Gauge?
	@IBOutlet var unitGauge: Gauge?
	@IBOutlet var unitLabel: UILabel?

	var sampleInsulin = [Double]()

	let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")

	var mealsArray: NSMutableArray?

	override func viewDidLoad() {
		super.viewDidLoad()
		if objectAlreadyExist("meals") {
			mealsArray = (defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
		} else {
			mealsArray = NSMutableArray()
		}
		for object in mealsArray! {
			if object["insulin"] is String {
				let meal = object["insulin"] as! String

				sampleInsulin.append(Double(meal)!)
			} else {
				let meal = object["insulin"] as! Double

				sampleInsulin.append(meal)
			}
		}
	}

	func objectAlreadyExist(key: String) -> Bool {
		return defaults!.objectForKey(key) != nil
	}

	override func viewDidAppear(animated: Bool) {

		var BGVals: [CGFloat] = []
		var CarbVals: [CGFloat] = []
		var UnitVals: [CGFloat] = []
		var forInt = 0
		if (7 > mealsArray?.count) {
			forInt = (mealsArray?.count)!
		} else {
			forInt = 7
		}

		for i in 0 ..< forInt {

			if (mealsArray![i]["bloodGlucose"] is String) {
				BGVals.append(CGFloat((mealsArray![i]["bloodGlucose"] as! NSString).doubleValue))
			} else {
				BGVals.append(CGFloat(mealsArray![i]["bloodGlucose"] as! Double))
			}
			if (mealsArray![i]["carbs"] is String) {
				CarbVals.append(CGFloat((mealsArray![i]["carbs"] as! NSString).doubleValue))
			} else {
				CarbVals.append(CGFloat(mealsArray![i]["carbs"] as! Double))
			}

			if (mealsArray![i]["insulin"] is String) {
				UnitVals.append(CGFloat((mealsArray![i]["insulin"] as! NSString).doubleValue))
			} else {
				UnitVals.append(CGFloat(mealsArray![i]["insulin"] as! Double))
			}
		}

		let bgAvg = BGVals.reduce(0, combine: +) / CGFloat(BGVals.count)
		let carbAvg = CarbVals.reduce(0, combine: +) / CGFloat(CarbVals.count)
		let unitAvg = UnitVals.reduce(0, combine: +) / CGFloat(UnitVals.count)

		if forInt == 0 {
			bgGauge?.rate = 0
			carbGauge?.rate = 0
			unitGauge?.rate = 0
			unitLabel?.text = "No data"
			bgLabel?.text = "No data"
			carbLabel?.text = "No data"
		} else {
			bgGauge?.rate = ceil(bgAvg)
			unitGauge?.rate = ceil(unitAvg)
			carbGauge?.rate = ceil(carbAvg)
			bgLabel?.text = "\(ceil(bgAvg)) mg/Dl"
			carbLabel?.text = "\(ceil(carbAvg)) g"
			unitLabel?.text = "\(ceil(unitAvg)) units"
		}

		super.viewDidAppear(true)
	}
}