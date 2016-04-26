//
//  MealController.swift
//  Logglu
//
//  Created by Keaton Burleson on 4/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import WatchKit
class Meal: WKInterfaceController {
    @IBOutlet var bgPicker: WKInterfacePicker!
    @IBOutlet var carbPicker: WKInterfacePicker!
    
    let items = NSMutableArray(capacity: 300)
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var pickerItems: [WKPickerItem] = []
        var carbItems: [WKPickerItem] = []
        
        for i in 0..<300 {
            let pickerItem = WKPickerItem()
            pickerItem.title =  "\(i) mg/dL"
            pickerItems.append(pickerItem)
            
        }
        for i in 0..<200 {
            let pickerItem = WKPickerItem()
            pickerItem.title =  "\(i) g"
            carbItems.append(pickerItem)
            
        }
        
        bgPicker?.setItems(pickerItems)
        bgPicker?.focus()
        bgPicker.setSelectedItemIndex(120)
        
        carbPicker.setItems(carbItems)
        carbPicker.setSelectedItemIndex(40)

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
    @IBAction func dismiss(){
        dismissController()
    }
}