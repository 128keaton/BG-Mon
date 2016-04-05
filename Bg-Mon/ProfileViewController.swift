//
//  ProfileViewController.swift
//  Bg-Mon
//
//  Created by Keaton Burleson on 4/4/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
class ProfileViewController: UITableViewController {
	@IBOutlet var highscore: UILabel?
	@IBOutlet var lowscore: UILabel?

	@IBOutlet var profileImage: UIImageView?

	override func viewDidLoad() {
		super.viewDidLoad()

		highscore?.text = "\(NSUserDefaults.standardUserDefaults().doubleForKey("highscore")) mg/dL"

		lowscore?.text = "\(NSUserDefaults.standardUserDefaults().doubleForKey("lowscore")) mg/dL"

		profileImage?.layer.cornerRadius = (profileImage?.bounds.width)! / 2
		profileImage?.layer.borderWidth = 2
		profileImage?.layer.borderColor = profileImage?.tintColor.CGColor
		profileImage?.clipsToBounds = true
	}
	@IBAction func openMenu() {
		openLeft()
	}
    func updateProfileImage(image: UIImage){
        
    }
}
