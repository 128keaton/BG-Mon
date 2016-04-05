//
//  MenuViewController.swift
//  Bg-Mon
//
//  Created by Keaton Burleson on 4/4/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import UIImageColors
class MenuViewController: UITableViewController {
    @IBOutlet var profileView: UIView?
    @IBOutlet var profileImage: UIImageView?
    @IBOutlet var profileLabel: UILabel?
    
    var profileViewController: UIViewController?
    var dashboardViewController: UIViewController?
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let image = profileImage?.image
        let colors = image!.getColors()
        profileView?.backgroundColor = colors.backgroundColor
        profileLabel?.textColor = colors.primaryColor
        profileImage?.layer.cornerRadius = (profileImage?.bounds.width)! / 2
        profileImage?.layer.borderWidth = 2
        profileImage?.layer.borderColor = colors.detailColor.CGColor
        profileImage?.clipsToBounds = true
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profileViewController = storyboard.instantiateViewControllerWithIdentifier("Profile") 
        self.profileViewController = profileViewController as UIViewController
        
        let dashboardViewController = storyboard.instantiateViewControllerWithIdentifier("Dash")
        self.dashboardViewController = dashboardViewController as UIViewController
        
     
        
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0:
            slideMenuController()?.changeMainViewController(dashboardViewController!, close: true)
        case 1:
            slideMenuController()?.changeMainViewController(profileViewController!, close: true)
        default:
            print("pressed")
        }
    }
    
 
    
}