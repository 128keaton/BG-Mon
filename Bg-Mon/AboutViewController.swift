//
//  AboutViewController.swift
//  Logglu
//
//  Created by Keaton Burleson on 4/26/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
class AboutViewController: UIViewController {
    @IBOutlet var coverView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(AboutViewController.dismiss))
        coverView?.addGestureRecognizer(tap)
        coverView?.userInteractionEnabled = true
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.view.bounds
        gradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        coverView!.layer.insertSublayer(gradient, atIndex: 0)
        
    }
    func dismiss(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}