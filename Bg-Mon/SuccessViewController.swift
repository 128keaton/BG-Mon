//
//  SuccessViewController.swift
//  Bg-Mon
//
//  Created by Keaton Burleson on 4/6/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class SuccessViewController: UIViewController {
    @IBOutlet var successLabel: UILabel?
    @IBOutlet var preLabel: UILabel?
    @IBOutlet var postLabel: UILabel?
    @IBOutlet var okButton: UIButton?
    
    var glucoseObject: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
        
        if glucoseObject != nil {
            successLabel?.text = "\(glucoseObject![0]) units"
            
        }else{
            successLabel?.text = "Success!"
            preLabel?.hidden = true
            postLabel?.hidden = true
        }
        self.navigationItem.leftBarButtonItem = nil
    }
    
    @IBAction func dismissYoSelf(){
        let presentingViewController = self.presentingViewController
        self.dismissViewControllerAnimated(false, completion: {
            presentingViewController!.dismissViewControllerAnimated(true, completion: {})
        })
    }
    
}