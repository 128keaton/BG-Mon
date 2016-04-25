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
    var mealsViewController: UIViewController?
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        if objectAlreadyExist("profile-pic") {
            profileImage?.image = UIImage.init(data: fetchImage("profile-pic"))
        }
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(MenuViewController.updateView), name: "updateView", object: nil)
        
        
        let image = profileImage?.image
		image!.getColors({ (colors) in
			self.profileView?.backgroundColor = colors.backgroundColor
			self.profileLabel?.textColor = colors.primaryColor
			self.profileImage?.layer.cornerRadius = (self.profileImage?.bounds.width)! / 2
			self.profileImage?.layer.borderWidth = 2
			self.profileImage?.layer.borderColor = colors.detailColor.CGColor
			self.profileImage?.clipsToBounds = true
		})
        
       
        if objectAlreadyExist("profile-name") {
            profileLabel?.text = fetchUsername("profile-name") as String
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profileViewController = storyboard.instantiateViewControllerWithIdentifier("Profile") 
        self.profileViewController = profileViewController as UIViewController
        
        let dashboardViewController = storyboard.instantiateViewControllerWithIdentifier("Dash")
        self.dashboardViewController = dashboardViewController as UIViewController
        
        let mealsViewController = storyboard.instantiateViewControllerWithIdentifier("Food")
        self.mealsViewController = mealsViewController as UIViewController
        
     
        
    }

   @objc func updateView(){
        print("updating View")
        if objectAlreadyExist("profile-pic") {
            profileImage?.image = UIImage.init(data: fetchImage("profile-pic"))
        }
        let image = profileImage?.image
        image!.getColors({ (colors) in
            self.profileView?.backgroundColor = colors.backgroundColor
            self.profileLabel?.textColor = colors.primaryColor
            self.profileImage?.layer.borderColor = colors.detailColor.CGColor
        })

        if objectAlreadyExist("profile-name") {
            profileLabel?.text = fetchUsername("profile-name") as String
        }

        
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0:
            slideMenuController()?.changeMainViewController(dashboardViewController!, close: true)
        case 1:
            slideMenuController()?.changeMainViewController(mealsViewController!, close: true)
        case 2:
            slideMenuController()?.changeMainViewController(profileViewController!, close: true)
        default:
            print("pressed")
        }
    }
    func objectAlreadyExist(key: String) -> Bool {
        return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
    }
    func fetchImage(key: String) -> NSData{
        return NSUserDefaults.standardUserDefaults().dataForKey(key)!
    }
    func fetchUsername(key: String) -> NSString{
        return NSUserDefaults.standardUserDefaults().objectForKey(key)! as! NSString
    }
    
    
 
    
}