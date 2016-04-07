//
//  SuperCell.swift
//  Bg-Mon
//
//  Created by Keaton Burleson on 4/5/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
class MealCell: UITableViewCell {
	@IBOutlet weak var bloodGlucose: UILabel?
	@IBOutlet weak var insulin: UILabel?
	@IBOutlet weak var carbs: UILabel?
    @IBOutlet weak var time: UILabel?
    @IBOutlet weak var type: UILabel?
    
}
class CorrectionCell: UITableViewCell {
	@IBOutlet weak var insulin: UITextField?

}
class GlucoseCell: UITableViewCell {
	@IBOutlet weak var bloodGlucose: UITextField?

}
class CarbCell: UITableViewCell {
    @IBOutlet weak var carbs: UITextField?
}
class DashboardCell: UITableViewCell{
    @IBOutlet weak var bloodGlucose: UILabel?
    @IBOutlet weak var insulin: UILabel?
    
}
class LongLasting: UITableViewCell{
    @IBOutlet weak var insulin: UITextField?
    
}