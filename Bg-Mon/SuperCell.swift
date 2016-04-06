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
}
class CorrectionCell: UITableViewCell {
	@IBOutlet weak var insulin: UILabel?
	@IBOutlet weak var bloodGlucose: UILabel?
}
class GlucoseCell: UITableViewCell {
	@IBOutlet weak var bloodGlucose: UILabel?
	@IBOutlet weak var insulin: UILabel?
}