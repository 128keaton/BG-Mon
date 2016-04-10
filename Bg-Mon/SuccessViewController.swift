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
    
    let effect = UIBlurEffect(style: .Dark)
    let resizingMask = UIViewAutoresizing.FlexibleWidth
    
    var glucoseObject: [String]?
    var shouldShowMeal: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.view.backgroundColor = UIColor.clearColor()
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = resizingMask
        self.view.addSubview(blurView)
        self.view.sendSubviewToBack(blurView)
       

        
        if glucoseObject != nil {
            successLabel?.text = "\(glucoseObject![0]) units"
            if(shouldShowMeal == false){
                postLabel?.hidden = true
            }
            
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