//
//  MealController.swift
//  Logglu
//
//  Created by Keaton Burleson on 4/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import WatchKit
import HealthKit
import WatchConnectivity
class BloodGlucose: WKInterfaceController {
    @IBOutlet var bgPicker: WKInterfacePicker!

    var bloodGlucose: [Double]?
    var selectedBG: Int?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var pickerItems: [WKPickerItem] = []
    
        
        for i in 0..<300 {
            let pickerItem = WKPickerItem()
            pickerItem.title =  "\(i) mg/dL"
            pickerItems.append(pickerItem)
            bloodGlucose?.append(Double(i) )
        }

        bgPicker?.setItems(pickerItems)
        bgPicker?.focus()
        bgPicker.setSelectedItemIndex(120)
        
    }
    @IBAction func pickerAction(index: Int) {
       WKInterfaceDevice.currentDevice().playHaptic(.Click)
        selectedBG = index
    }
    
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    @IBAction func moveToCarbs(){
        if selectedBG == nil {
            selectedBG = 120
        }
        self.pushControllerWithName("Carbohydrates", context: ["segue": "hierarchical", "data": Double(selectedBG!)])
    }
}

class Carbohydrates: WKInterfaceController {
    @IBOutlet var carbPicker: WKInterfacePicker!
    var healthManagement = HealthKitUploader()
    
    internal var bloodGlucose: Double?
    
    var carbs: [Double]?
    
    var selectedCarb: Int?
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var carbItems: [WKPickerItem] = []
        bloodGlucose = context!["data"] as? Double
        for i in 0..<200 {
            let pickerItem = WKPickerItem()
            pickerItem.title =  "\(i) g"
            carbItems.append(pickerItem)
            carbs?.append(Double(i))
            
        }
        carbPicker.setItems(carbItems)
        carbPicker.setSelectedItemIndex(40)
        carbPicker.setSelectedItemIndex(65)
        // Configure interface objects here.
    }
    @IBAction func pickerAction(index: Int) {
        WKInterfaceDevice.currentDevice().playHaptic(.Click)
        selectedCarb = index
    }
    
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    @IBAction func moveAndCalculate(){
        if selectedCarb == nil {
            selectedCarb = 65
        }
        self.pushControllerWithName("Success", context: ["segue": "hierarchical", "data": healthManagement.calculateInsulin(bloodGlucose!, carbs: Double(selectedCarb!)), "carbs" : Double(selectedCarb!), "bloodGlucose" : Double(bloodGlucose!)])
    }


}
class Success: WKInterfaceController{
    internal var insulin: Double?
    @IBOutlet var dosageLabel: WKInterfaceLabel?
    var beetusDictionary: NSMutableDictionary?
    let healthManager = HealthKitUploader()
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        insulin = context!["data"] as? Double
        beetusDictionary = context?.mutableCopy() as? NSMutableDictionary
        if insulin != nil{
            dosageLabel?.setText("\( Int(round(insulin!))) Units")
        }
        // Configure interface objects here.
    }

    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    @IBAction func save(){
        healthManager.saveLocally(beetusDictionary?.objectForKey("carbs") as! Double, bloodGlucose: beetusDictionary?.objectForKey("bloodGlucose") as! Double, insulin: Double(insulin!))
        print("saving")
        self.popToRootController()
    }
    
}
class HealthKitUploader: NSObject {
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    private var healthStore = HKHealthStore()
    let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")
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
    func saveLocally(carbs: Double, bloodGlucose: Double, insulin: Double){
        
        let beetusDictionary = ["type" : "Full Meal", "bloodGlucose" : String(bloodGlucose), "carbs" : String(carbs), "insulin" : Int(round(insulin)), "date": NSDate()]

        if(WCSession.isSupported()){
            session = WCSession.defaultSession()
            session!.sendMessage(["data" : beetusDictionary, "type" : "transmit"], replyHandler:  { (response) -> Void in
                    print(response["message"])
        
                }, errorHandler:  { (error) -> Void in
                    
                    print(error)
            })
        }
        self.uploadToHealthKit(bloodGlucose, carbAmount: carbs)
    }
    
    func objectAlreadyExist(key: String) -> Bool {
        return defaults!.objectForKey(key) != nil
    }
    func calculateInsulin(glucose: Double, carbs: Double) -> Double{
        
        
        var target: Double? = 120
        var ratio: Double? = 8
        var sensitivity: Double? = 30
        
    
        
        if(WCSession.isSupported()){
            session = WCSession.defaultSession()
            session!.sendMessage(["type" : "diabeticInformation"], replyHandler:  { (response) -> Void in
               
                let informationDictionary: [String : String]?
                if response["data"] is [String:String]{
                    informationDictionary = response["data"] as? [String: String]
                    if let val = informationDictionary!["target"] {
                        target = Double(val)
                    }
                    if let val = informationDictionary!["ratio"] {
                        ratio = Double(val)
                    }
                    if let val = informationDictionary!["sensitivity"] {
                        sensitivity = Double(val)
                    }
                }else{
                    print(response["message"])
                }
                
             
                
                }, errorHandler:  { (error) -> Void in
                    
                    print(error)
            })
        }

        
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
        var correction = glucose - target!
        correction = correction / sensitivity!
        if correction < 0 {
            correction = 0
        }
        
        var carbCalulation = carbs
        carbCalulation = carbCalulation / ratio!
        
        dosage = carbCalulation + correction
        
        return dosage!
        
    }


}

extension HealthKitUploader: WCSessionDelegate {
    
}
