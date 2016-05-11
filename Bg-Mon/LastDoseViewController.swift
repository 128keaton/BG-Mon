//
//  LastDoseViewController.swift
//  Logglu
//
//  Created by Keaton Burleson on 5/11/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import GaugeKit
class LastDoseViewController: UIViewController {
	@IBOutlet var unitLabel: UILabel?
	@IBOutlet var unitGauge: Gauge?

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

		var UnitVals: [CGFloat] = []
		if mealsArray?.count != 0 {

			let meal = mealsArray?.lastObject
			if (meal!["insulin"] is String) {
				UnitVals.append(CGFloat((meal!["insulin"] as! NSString).doubleValue))
			} else {
				UnitVals.append(CGFloat(meal!["insulin"] as! Double))
			}
			unitGauge?.rate = ceil(UnitVals.first!)

			unitLabel?.text = "\(ceil(UnitVals.first!)) units"
		} else {
			unitGauge?.rate = 0
			unitLabel?.text = "No data"
		}
//lazyness at its finest

		super.viewDidAppear(true)
	}
}
