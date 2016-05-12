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
    
    
    @IBOutlet var bottomCell: UITableViewCell?
    @IBOutlet var topCell: UITableViewCell?
    override func viewDidLoad() {
        super.viewDidLoad()
        topCell?.frame = CGRectMake(0, 0, self.view.frame.width, 110)
        bottomCell?.frame = CGRectMake(0, 0, self.view.frame.width, 119)
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 110
        }else{
            return 119
        }
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
}

