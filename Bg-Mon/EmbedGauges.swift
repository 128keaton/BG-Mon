//
//  EmbedGauges.swift
//  Logglu
//
//  Created by Keaton Burleson on 5/11/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import GaugeKit
class EmbedGauges: UITableViewController {
    @IBOutlet var bgLabel: UILabel?
    @IBOutlet var carbLabel: UILabel?
    @IBOutlet var bgGauge: Gauge?
    @IBOutlet var carbGauge: Gauge?
    @IBOutlet var unitGauge: Gauge?
    @IBOutlet var unitLabel: UILabel?
    
    @IBOutlet var doseLabel: UILabel?
    @IBOutlet var doseGauge: Gauge?
}

