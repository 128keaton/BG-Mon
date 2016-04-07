//
//  SuccessViewController.swift
//  Bg-Mon
//
//  Created by Keaton Burleson on 4/6/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit


class SuccessViewController: UIViewController {
    @IBOutlet var successLabel: UILabel?
    @IBOutlet var preLabel: UILabel?
    @IBOutlet var postLabel: UILabel?
    
    var glucoseObject: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if glucoseObject != nil {
            successLabel?.text = glucoseObject![0]
            
        }else{
            successLabel?.text = "Success!"
            preLabel?.hidden = true
            postLabel?.hidden = true
        }
    }
    
    
}