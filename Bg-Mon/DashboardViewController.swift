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
import WatchConnectivity
import PagingMenuController
import GaugeKit
import MBProgressHUD
import MMMaterialDesignSpinner
let healthKitStore: HKHealthStore = HKHealthStore()

class DashboardViewController: UIViewController, ChartViewDelegate, MFMailComposeViewControllerDelegate {

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
    
    var embedGauges: EmbedGauges?


    @IBOutlet var scrollyMcScrollface: UIScrollView?


	@IBOutlet var lineChart: LineChartView?
	@IBOutlet weak var insulinChart: CombinedChartView?

    var addViewController: AddMeal?
    
    
	private var results = [HKQuantitySample]()
	var sampleInsulin = [Double]()
	let effect = UIBlurEffect(style: .Light)
	let resizingMask = UIViewAutoresizing.FlexibleWidth
    let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")

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

        insulinChart!.delegate = self;
        
        insulinChart!.descriptionText = "";
        insulinChart!.noDataTextDescription = "Data will be loaded soon."
        insulinChart?.backgroundColor = UIColor.clearColor()
        
        insulinChart!.drawBarShadowEnabled = false
        insulinChart!.drawValueAboveBarEnabled = true
        insulinChart?.userInteractionEnabled = false
        insulinChart!.drawGridBackgroundEnabled = false
        insulinChart!.drawBordersEnabled = true
        insulinChart?.gridBackgroundColor = UIColor.clearColor()
        insulinChart?.borderColor = self.view.tintColor
        insulinChart?.leftAxis.drawGridLinesEnabled = false
        insulinChart?.rightAxis.drawGridLinesEnabled = false
        insulinChart?.xAxis.drawGridLinesEnabled = false
        insulinChart?.drawGridBackgroundEnabled = false
        insulinChart?.xAxis.labelPosition = .BottomInside
        insulinChart?.leftAxis.labelPosition = .InsideChart
        insulinChart?.rightAxis.labelPosition = .InsideChart
        insulinChart?.leftAxis.spaceTop = 0.8
        insulinChart?.drawOrder = [CombinedChartView.DrawOrder.Line.rawValue, CombinedChartView.DrawOrder.Bar.rawValue]
        insulinChart?.drawValueAboveBarEnabled
        insulinChart?.xAxis.labelPosition = .BothSided
    
       
        
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
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if  segue.identifier == "embed" {
            embedGauges = segue.destinationViewController as? EmbedGauges
        }
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
                

                let meal = self.mealsArray![i] as! NSMutableDictionary
    
                bgVals.append(ChartDataEntry(value: Double(meal["bloodGlucose"] as! String)!, xIndex: i))
            }
           
        }
     
        let timeVals = self.getYAxisCount(self.sampleInsulin.count)
        let chartDataSet = LineChartDataSet(yVals: bgVals, label: "Blood Glucose")
        chartDataSet.setColor(self.view.tintColor, alpha: 1.0);
        chartDataSet.axisDependency = .Left
        chartDataSet.mode = LineChartDataSet.Mode.CubicBezier
        chartDataSet.drawFilledEnabled = false
        chartDataSet.fillAlpha = 1.0
        chartDataSet.circleColors = [self.view.tintColor]
        chartDataSet.circleHoleColor = self.view.tintColor
        chartDataSet.fill = ChartFill(color: self.view.tintColor)
    
        let barChartDataSet = BarChartDataSet(yVals: insulinVals, label: "Insulin Units")
        barChartDataSet.valueTextColor = UIColor.blackColor()
        barChartDataSet.setColor(UIColor.greenColor(), alpha: 1.0)
        barChartDataSet.barSpace =  0.35
      
        let data: CombinedChartData = CombinedChartData(xVals: timeVals)
        data.lineData = LineChartData(xVals: timeVals, dataSets: [chartDataSet])
        data.barData = BarChartData(xVals: timeVals, dataSets: [barChartDataSet])
        
    
        data.setValueTextColor(UIColor.blackColor())
    
            if self.sampleInsulin.count == 0{
                self.insulinChart!.rightAxis.labelTextColor = UIColor.clearColor()
                self.insulinChart!.leftAxis.labelTextColor = UIColor.clearColor()
            }
            if bgVals.count != 0{
                self.insulinChart?.setVisibleXRange(minXRange: CGFloat(bgVals.count), maxXRange: CGFloat(bgVals.count))
            }else{
                self.insulinChart?.xAxis.enabled = false
                self.insulinChart?.noDataText = "No data"
                self.insulinChart?.infoTextColor = self.view.tintColor
                self.insulinChart?.data = nil
                self.insulinChart?.setNeedsDisplay()
            }


        self.insulinChart!.xAxis.labelPosition = .Top
        self.insulinChart!.animate(xAxisDuration: 0.5, yAxisDuration: 1.0)
        self.insulinChart?.scaleXEnabled = true
      
        self.insulinChart?.data = data
        self.insulinChart?.xAxis.labelTextColor = UIColor.blackColor()
        self.insulinChart?.notifyDataSetChanged()
    
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
		//	self.tableView!.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: .Automatic)

			let query = HKObserverQuery(sampleType: self.sampleType, predicate: nil) { (query, completionHandler, error) -> Void in
				NSLog("Observer fired for .... %@", query.sampleType!.identifier);
				if (error == nil) {
					self.refreshData()
				}
				self.insulinChart?.notifyDataSetChanged()
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
            embedGauges?.doseGauge?.rate = ceil(DoseVals.first!)
            
            embedGauges?.doseLabel?.text = "last dose: \(ceil(DoseVals.first!)) units"
        } else {
            embedGauges?.doseGauge?.rate = 0
            embedGauges?.doseLabel?.text = "No data"
        }
        
        
        scrollyMcScrollface?.contentSize = CGSizeMake(self.view.frame.width, scrollyMcScrollface!.contentSize.height)
        
        let bgAvg = BGVals.reduce(0, combine: +) / CGFloat(BGVals.count)
        let carbAvg = CarbVals.reduce(0, combine: +) / CGFloat(CarbVals.count)
        let unitAvg = UnitVals.reduce(0, combine: +) / CGFloat(UnitVals.count)
        
        if forInt == 0 {
            embedGauges?.bgGauge?.rate = 0
            embedGauges?.carbGauge?.rate = 0
            embedGauges?.unitGauge?.rate = 0
            embedGauges?.unitLabel?.text = "No data"
            embedGauges?.bgLabel?.text = "No data"
            embedGauges?.carbLabel?.text = "No data"
        } else {
            embedGauges?.bgGauge?.rate = ceil(bgAvg)
            embedGauges?.unitGauge?.rate = ceil(unitAvg)
            embedGauges?.carbGauge?.rate = ceil(carbAvg)
            embedGauges?.bgLabel?.text = "\(ceil(bgAvg)) mg/dL"
            embedGauges?.carbLabel?.text = "\(ceil(carbAvg)) g"
            embedGauges?.unitLabel?.text = "\(ceil(unitAvg)) units"
        }
        

        

		
		super.viewDidAppear(true)
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        insulinChart?.highlightValue(ChartHighlight.init(xIndex: indexPath.row, dataSetIndex: 0))
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
    

    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        
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

