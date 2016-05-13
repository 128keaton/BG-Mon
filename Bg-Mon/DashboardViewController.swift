//
//  DashboardViewController.swift
//
//
//  Created by Keaton Burleson on 4/4/16.
//
//

import Foundation
import UIKit
import HealthKit
import BTNavigationDropdownMenu
import MessageUI
import Photos
import EZAlertController
import WatchConnectivity
import PagingMenuController
import GaugeKit
import SwiftCharts
import MBProgressHUD
import MMMaterialDesignSpinner
let healthKitStore: HKHealthStore = HKHealthStore()

class DashboardViewController: UIViewController, MFMailComposeViewControllerDelegate {

	private var objects = [HKQuantityType!]()
	var preferredUnits = [NSObject: AnyObject]()
	var healthStore = HKHealthStore()

    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    var menuView: BTNavigationDropdownMenu!
    var nav: UINavigationController?
    
    @IBOutlet var hourSelector: UISegmentedControl?
	var sampleType: HKQuantityType!
	var preferredUnit: HKUnit!
    
    @IBOutlet var bgLabel: UILabel?
    @IBOutlet var carbLabel: UILabel?
    @IBOutlet var bgGauge: Gauge?
    @IBOutlet var carbGauge: Gauge?
    @IBOutlet var unitGauge: Gauge?
    @IBOutlet var unitLabel: UILabel?
    
    @IBOutlet var doseLabel: UILabel?
    @IBOutlet var doseGauge: Gauge?
    
    @IBOutlet var chartPlaceholder: UIView?
    var chart: Chart?

    @IBOutlet var scrollyMcScrollface: UIScrollView?

    @IBOutlet var gaugeStack: UIStackView?

    var addViewController: AddMeal?
    
     var iPhoneChartSettings: ChartSettings {
        let chartSettings = ChartSettings()
        chartSettings.leading = 0
        chartSettings.top = 0
        chartSettings.trailing = 0
        chartSettings.bottom = 0
        chartSettings.labelsToAxisSpacingX = 5
        chartSettings.labelsToAxisSpacingY = 5
        chartSettings.axisTitleLabelsToLabelsSpacing = 4
        chartSettings.axisStrokeWidth = 0.2
        chartSettings.spacingBetweenAxesX = 8
        chartSettings.spacingBetweenAxesY = 8
        return chartSettings
    }
    
    
	private var results = [HKQuantitySample]()
	var sampleInsulin = [Double]()
	let effect = UIBlurEffect(style: .Light)
	let resizingMask = UIViewAutoresizing.FlexibleWidth
    let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")

    var insulinData: [(title: String, value: Double)] = []
    var glucoseData: [(title: String, value: Double)] = []
    
    
 
    
	var mealsArray: NSMutableArray?
	override func awakeFromNib() {
		super.awakeFromNib()
       
	}

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.configureGraphs()
        
        
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.delegate = self
            session?.activateSession()
        }
        
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
        //self.tableView!.backgroundColor = UIColor.blackColor()
        menuView.checkMarkImage = nil
        menuView?.cellHeight = 100
        menuView.animationDuration = 0.1
        
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

    
        
        
        
    
        
    
        let swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(DashboardViewController.swipe))
        swipeLeft.direction = .Left

        
        
		if objectAlreadyExist("meals")  {
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
        let backgroundView = GradientView(frame: self.view.frame)
        backgroundView.colors = [UIColor(hue: 337/360, saturation: 69/100, brightness: 65/100, alpha: 1.0), UIColor(hue: 11/360, saturation: 73/100, brightness: 83/100, alpha: 1.0)]
        backgroundView.direction = .Horizontal
        self.view.backgroundColor = UIColor.clearColor()
        self.view.addSubview(backgroundView)
        self.view.sendSubviewToBack(backgroundView)

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
    
    func swipe(){
        var previousIndex = 0
        let hud: MBProgressHUD? = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud?.mode = .Text
        
        if objectAlreadyExist("index") {
            previousIndex = (defaults?.integerForKey("index"))!
        }
        switch previousIndex {
        case 0:
            hud?.labelText = "12 hour"
            previousIndex = 1
            break
        case 1:
            hud?.labelText = "24 hour"
            previousIndex = 2
            break
        case 2:
            hud?.labelText = "6 hour"
            previousIndex = 0
            break
        default:
            hud?.labelText = "6 hour"
            previousIndex = 0
            break
        }
        defaults?.setInteger(previousIndex, forKey: "index")
        defaults?.synchronize()
        self.configureGraphs()
        
    }
    
 
	func configureGraphs() {
		let serialQueue: dispatch_queue_t = dispatch_queue_create("com.128keaton.refreshQueue", nil)

		dispatch_sync(serialQueue, { () -> Void in

	

			for i in 0 ..< self.sampleInsulin.count {

				let stopIT = self.mealsArray![i];
				let now = stopIT["date"] as! NSDate

				let then = self.getThen()

				if (now.isBetweeen(date: then, andDate: NSDate())) {
					
                 
                    self.insulinData.append(("\(self.sampleInsulin[i])", self.sampleInsulin[i]))

					let meal = self.mealsArray![i] as! NSMutableDictionary
                    let glucose = meal["bloodGlucose"]
                    if(glucose is String){
                        self.glucoseData.append(("\(meal["bloodGlucose"])", Double(meal["bloodGlucose"] as! String)!))
                    }else{
                        self.glucoseData.append(("\(meal["bloodGlucose"])", Double(meal["bloodGlucose"] as! Double)))
                    }

								}
			}
            
            let bars: [ChartBarModel] = self.insulinData.enumerate().flatMap {index, tuple in
                [
                    ChartBarModel(constant: ChartAxisValueDouble(index), axisValue1: ChartAxisValueDouble(0), axisValue2: ChartAxisValueDouble(tuple.value), bgColor: UIColor.greenColor()),
                    
                ]
            }
            let labelSettings = ChartLabelSettings(font: UIFont.systemFontOfSize(20))
            
          
            
            let xModel = ChartAxisModel(axisValues: [EmptyAxisValue.init(0)], axisTitleLabel: ChartAxisLabel(text: "Axis title", settings: labelSettings))
            let yModel = ChartAxisModel(axisValues: [EmptyAxisValue.init(0)], axisTitleLabel: ChartAxisLabel(text: "Axis title", settings: labelSettings.defaultVertical()))
            let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: self.iPhoneChartSettings, chartFrame: self.chartPlaceholder!.frame, xModel: xModel, yModel: yModel)
            let chartFrame = self.chartPlaceholder?.frame
           
            let (xAxis, yAxis, innerFrame) = (coordsSpace.xAxis, coordsSpace.yAxis, coordsSpace.chartInnerFrame)
            
            let barsLayer = ChartBarsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, bars: bars, horizontal: false, barWidth: 25, animDuration: 0.5)
            
            // labels layer
            // create chartpoints for the top and bottom of the bars, where we will show the labels
            let labelChartPoints = bars.map {bar in
                ChartPoint(x: bar.constant, y: bar.axisValue2)
            }
            let formatter = NSNumberFormatter()
            formatter.maximumFractionDigits = 2
            let labelsLayer = ChartPointsViewsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: labelChartPoints, viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
                let label = HandlingLabel()
                let posOffset: CGFloat = 10
                
                let pos = chartPointModel.chartPoint.y.scalar > 0
                
                let yOffset = pos ? -posOffset : posOffset
                label.text = "\(formatter.stringFromNumber(chartPointModel.chartPoint.y.scalar)!)%"
                label.font = UIFont.systemFontOfSize(12)
                label.sizeToFit()
                label.center = CGPointMake(chartPointModel.screenLoc.x, pos ? innerFrame.origin.y : innerFrame.origin.y + innerFrame.size.height)
                label.alpha = 0
                
                label.movedToSuperViewHandler = {[weak label] in
                    UIView.animateWithDuration(0.3, animations: {
                        label?.alpha = 1
                        label?.center.y = chartPointModel.screenLoc.y + yOffset
                    })
                }
                return label
                
                }, displayDelay: 0.5) // show after bars animation
            
            // line layer
            let lineChartPoints = self.glucoseData.enumerate().map {index, tuple in ChartPoint(x: ChartAxisValueDouble(index), y: ChartAxisValueDouble(tuple.value))}
            let lineModel = ChartLineModel(chartPoints: lineChartPoints, lineColor: UIColor.blackColor(), lineWidth: 2, animDuration: 0.5, animDelay: 1)
            let lineLayer = ChartPointsLineLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, lineModels: [lineModel])
            
            let circleViewGenerator = {(chartPointModel: ChartPointLayerModel, layer: ChartPointsLayer, chart: Chart) -> UIView? in
                let color = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
                let circleView = ChartPointEllipseView(center: chartPointModel.screenLoc, diameter: 6)
                circleView.animDuration = 0.5
                circleView.fillColor = color
                return circleView
            }

            
            
            // show a gap between positive and negative bar
            let dummyZeroYChartPoint = ChartPoint(x: ChartAxisValueDouble(0), y: ChartAxisValueDouble(0))
            let yZeroGapLayer = ChartPointsViewsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: [dummyZeroYChartPoint], viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
                let height: CGFloat = 2
                let v = UIView(frame: CGRectMake(innerFrame.origin.x + 2, chartPointModel.screenLoc.y - height / 2, innerFrame.origin.x + innerFrame.size.height, height))
                v.backgroundColor = UIColor.whiteColor()
                return v
            })
            
            let theChart = Chart(
                frame: self.chartPlaceholder!.frame,
                layers: [
                    xAxis,
                    yAxis,
                    barsLayer,
                    labelsLayer,
                    yZeroGapLayer,
                    lineLayer,
             
                ]
            )
            self.view.addSubview(theChart.view)
            self.chart = theChart


			
		})
        //main thread
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
	}
    func getThen() -> NSDate {
  
        
		if objectAlreadyExist("index") {

			switch Int((defaults?.integerForKey("index"))!) {
			case 0:
        
                print("6 hour")
				return NSDate().dateByAddingTimeInterval(-21600)

			case 1:
             
                
                print("12 hour")
				return NSDate().dateByAddingTimeInterval(-43200)

			case 2:
            
                print("24 hour")
				return NSDate().dateByAddingTimeInterval(-86400)

			default:
				return NSDate().dateByAddingTimeInterval(-21600)
			}
		} else {

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
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.presentTransparentNavigationBar()
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.hideTransparentNavigationBar()
    }
    
	func objectAlreadyExist(key: String) -> Bool {
		return defaults!.objectForKey(key) != nil
	}

    

	override func viewDidAppear(animated: Bool) {
		let serialQueue: dispatch_queue_t = dispatch_queue_create("com.128keaton.refreshQueue", nil)

		dispatch_sync(serialQueue, { () -> Void in
			self.authorizeHealthKit(nil)
		//	self.tableView!.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Automatic)

			let query = HKObserverQuery(sampleType: self.sampleType, predicate: nil) { (query, completionHandler, error) -> Void in
				NSLog("Observer fired for .... %@", query.sampleType!.identifier);
				if (error == nil) {
					self.refreshData()
				}
			
			}

			self.healthStore.executeQuery(query)
		})
        
        
        
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
        
        var DoseVals: [CGFloat] = []
        if mealsArray?.count != 0 {
            
            let meal = mealsArray?.lastObject
            if (meal!["insulin"] is String) {
                DoseVals.append(CGFloat((meal!["insulin"] as! NSString).doubleValue))
            } else {
                DoseVals.append(CGFloat(meal!["insulin"] as! Double))
            }
            doseGauge?.rate = ceil(DoseVals.first!)
            
            doseLabel?.text = "last dose: \(ceil(DoseVals.first!)) units"
        } else {
            doseGauge?.rate = 0
            doseLabel?.text = "No data"
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
            bgLabel?.text = "\(ceil(bgAvg)) mg/dL"
            carbLabel?.text = "\(ceil(carbAvg)) g"
            unitLabel?.text = "\(ceil(unitAvg)) units"
        }
        

        

        
        scrollyMcScrollface?.contentSize = CGSizeMake(self.view.frame.width, 603)
		super.viewDidAppear(true)
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
	}



	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sampleInsulin.count
	}

       func getTime(indexPath: NSIndexPath) -> String{
        let dictionary = mealsArray![indexPath.row] as! NSMutableDictionary
        if let exists = dictionary["date"]{
            let formatter = NSDateFormatter()
            formatter.dateStyle = .ShortStyle
            formatter.timeStyle = .ShortStyle
            return formatter.stringFromDate(exists as! NSDate)
        }else{
            return "No time recorded"
        }
    }
    

    


	func refreshData() {
		NSLog("refreshData......")
		let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
		let query = HKSampleQuery(sampleType: self.sampleType, predicate: nil, limit: 0, sortDescriptors: [timeSortDescriptor]) { (query, objects, error) -> Void in
			if (error == nil) {
				self.results = objects as! [HKQuantitySample]
                
               
				NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    if self.objectAlreadyExist("meals") {
                        self.mealsArray = (self.defaults!.objectForKey("meals")?.mutableCopy() as? NSMutableArray?)!
                    } else {
                        
                        self.mealsArray = NSMutableArray()
                    }
                    var maxArray: [Double] = []
                    self.sampleInsulin.removeAll()
                    for object in self.mealsArray! {
                        
                   
                        
                        if object["insulin"] is String {
                            let meal = object["insulin"] as! String
                            
                            self.sampleInsulin.append(Double(meal)!)
                            maxArray.append(Double(meal)!)
                        }else{
                            let meal = object["insulin"] as! Double
                            
                            self.sampleInsulin.append(meal)
                            maxArray.append(meal)
                        }
                        
                        
       
                        
                    }
                    if (maxArray.maxElement() != nil) {
                        self.defaults!.setDouble(maxArray.maxElement()!, forKey: "highscore")
                        self.defaults!.setDouble(maxArray.minElement()!, forKey: "lowscore")
                        let averageOfMgDL = maxArray.reduce(0, combine: +) / Double(maxArray.count)
                        self.defaults?.setDouble(averageOfMgDL, forKey: "average")
                        self.defaults!.synchronize()
                    }
                    
					//self.tableView!.reloadData()
             //       self.tableView!.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
                  
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
                    guard let object = self.results.atIndex(i)
                        else {continue}
                
                    let doubleValue = object.quantity.doubleValueForUnit(self.preferredUnit)
                    writeString.appendString("\(doubleValue) mg/dL, \(formatter.stringFromDate(self.results[i].startDate)), \r\n")
                
                
            }
            let hud = MBProgressHUD.init(view: self.view)
            let spinner = MMMaterialDesignSpinner.init(frame: CGRectMake(0, 0, 40, 40))
            spinner.lineWidth = 1.5
            spinner.tintColor = self.view.tintColor
            spinner.startAnimating()
            hud.customView = spinner
            hud.show(true)
            self.sendEmail(NSData(), csv: writeString.dataUsingEncoding(NSUTF8StringEncoding)!, options: ["csv" : true, "snapshot" : false])

            
        })
        
        let snapshot = UIAlertAction.init(title: "Snapshot of Graph", style: .Default, handler: { (action) in
          
            let hud = MBProgressHUD.init(view: self.view)
            let spinner = MMMaterialDesignSpinner.init(frame: CGRectMake(0, 0, 40, 40))
            spinner.tintColor = self.view.tintColor
            spinner.lineWidth = 1.5
            spinner.startAnimating()
            hud.customView = spinner
            hud.show(true)
          //  self.sendEmail(UIImagePNGRepresentation((self.insulinChart?.getSnapshot())!)!, csv: NSData(), options: ["csv" : false, "snapshot" : true])
        
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

extension DashboardViewController: WCSessionDelegate {

	func fetchUsername(key: String) -> NSString {
		let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")
		return defaults!.objectForKey(key)! as! NSString
	}

	func session(session: WCSession, didReceiveMessage message: [String: AnyObject], replyHandler: ([String: AnyObject]) -> Void) {
		if message["type"] as! String == "request" {

			print("Sending from WatchKit")
		} else if message["type"] as! String == "diabeticInformation" {
			var informationArray: [String: String]?

			if objectAlreadyExist("target") {
				informationArray?.updateValue(fetchUsername("target") as String, forKey: "target")
			}
			if objectAlreadyExist("ratio") {
				informationArray?.updateValue(fetchUsername("ratio") as String, forKey: "sensitivity")
			}
			if objectAlreadyExist("sensitivity") {
				informationArray?.updateValue(fetchUsername("sensitivity") as String, forKey: "target")
			}
            if informationArray != nil {
                replyHandler(["data": informationArray!])
            }else{
                replyHandler(["data": "no data", "message" : "informationArray was nil"])
            }
			
		} else if message["type"] as! String == "transmit" {

            
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

			if objectAlreadyExist("meals") {
				let meals = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")!.objectForKey("meals")?.mutableCopy() as! NSMutableArray
				meals.insertObject(message["data"]as! NSMutableDictionary, atIndex: 0)
				replyHandler(["message": "successfully saved into existing array"])
				print("Existing Array")
				NSUserDefaults(suiteName: "group.com.128keaton.test-strip")?.setObject(meals, forKey: "meals")
				NSUserDefaults(suiteName: "group.com.128keaton.test-strip")?.synchronize()
                let messageData = message["data"] as! NSMutableDictionary
                self.uploadToHealthKit(Double(messageData["bloodGlucose"] as! String)!, carbAmount: Double(messageData["carbs"] as! String)!)
                self.refreshData()
				
			} else {
				let meals = NSMutableArray()
				meals.insertObject(message["data"]as! NSMutableDictionary, atIndex: 0)
				replyHandler(["message": "successfully saved into new array"])
				NSUserDefaults(suiteName: "group.com.128keaton.test-strip")?.setObject(meals, forKey: "meals")
				NSUserDefaults(suiteName: "group.com.128keaton.test-strip")?.synchronize()
                self.refreshData()
			}

			print("Saving from WatchKit")
		}
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

}

extension Array {
    func atIndex(index: Int) -> Element? {
        if index < 0 || index > self.count - 1 {
            return nil
        }
        return self[index]
    }
}


extension UIScrollView{
    func setContentViewSize(offset:CGFloat = 0.0) {
        // dont show scroll indicators
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        
        var maxHeight : CGFloat = 0
        for view in subviews {
            if view.hidden {
                continue
            }
            let newHeight = view.frame.origin.y + view.frame.height
            if newHeight > maxHeight {
                maxHeight = newHeight
            }
        }
        // set content size
        contentSize = CGSize(width: contentSize.width, height: maxHeight + offset)
        // show scroll indicators
        showsHorizontalScrollIndicator = true
        showsVerticalScrollIndicator = true
    }
}
extension UINavigationController {
    
    public func presentTransparentNavigationBar() {
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics:UIBarMetrics.Default)
        navigationBar.translucent = true
        navigationBar.shadowImage = UIImage()
        setNavigationBarHidden(false, animated:true)
    }
    
    public func hideTransparentNavigationBar() {
        setNavigationBarHidden(true, animated:false)
        navigationBar.setBackgroundImage(UINavigationBar.appearance().backgroundImageForBarMetrics(UIBarMetrics.Default), forBarMetrics:UIBarMetrics.Default)
        navigationBar.translucent = UINavigationBar.appearance().translucent
        navigationBar.shadowImage = UINavigationBar.appearance().shadowImage
    }
}

class EmptyAxisValue: ChartAxisValueDouble {
    override var labels: [ChartAxisLabel] {
        return []
    }
}

