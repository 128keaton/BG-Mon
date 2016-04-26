//
//  ProfileViewController.swift
//  Bg-Mon
//
//  Created by Keaton Burleson on 4/4/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
public extension UIImage {
	convenience init(color: UIColor, size: CGSize = CGSizeMake(1, 1)) {
		let rect = CGRectMake(0, 0, size.width, size.height)
		UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
		color.setFill()
		UIRectFill(rect)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		self.init(CGImage: image.CGImage!)
	}
}

class ProfileViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	@IBOutlet var highscore: UILabel?
	@IBOutlet var lowscore: UILabel?
    
    @IBOutlet var sensitivity: UITextField?
    @IBOutlet var targetBG: UITextField?
    @IBOutlet var carbRatio: UITextField?
    
    @IBOutlet var doctorName: UITextField?

    @IBOutlet var doctorEmail: UITextField?
    
	@IBOutlet var name: UITextField?

	var hud: MBProgressHUD?

	@IBOutlet var profileImage: UIImageView?

	let imagePicker = UIImagePickerController()

	override func viewDidLoad() {
		super.viewDidLoad()
		if objectAlreadyExist("profile-pic") {
			profileImage?.image = UIImage.init(data: fetchImage("profile-pic"))
		}

		if objectAlreadyExist("profile-name") {
			name!.text = fetchUsername("profile-name") as String
		}
        if objectAlreadyExist("target") {
            targetBG?.text = fetchUsername("target") as String
        }
        if objectAlreadyExist("ratio") {
            carbRatio?.text = fetchUsername("ratio") as String
        }
        if objectAlreadyExist("sensitivity") {
            sensitivity?.text = fetchUsername("sensitivity") as String
        }
        if objectAlreadyExist("dr-email") {
            doctorEmail!.text = fetchUsername("dr-email") as String
        }
        if objectAlreadyExist("dr-name") {
            doctorName!.text = fetchUsername("dr-name") as String
        }

		let tapGesture = UIGestureRecognizer.init(target: self, action: #selector(ProfileViewController.chooseImage))

		imagePicker.delegate = self
		profileImage?.addGestureRecognizer(tapGesture)
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
	func objectAlreadyExist(key: String) -> Bool {
		return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
	}
	func fetchImage(key: String) -> NSData {
		return NSUserDefaults.standardUserDefaults().dataForKey(key)!
	}
	func saveImage(key: String, data: UIImage) {
		NSUserDefaults.standardUserDefaults().setObject(UIImageJPEGRepresentation(data, 100), forKey: "profile-pic")
		NSUserDefaults.standardUserDefaults().synchronize()
	}
	func saveName(key: String, name: String) {
		NSUserDefaults.standardUserDefaults().setObject(name, forKey: "profile-name")
		NSUserDefaults.standardUserDefaults().synchronize()
	}

	func fetchUsername(key: String) -> NSString {
		return NSUserDefaults.standardUserDefaults().objectForKey(key)! as! NSString
	}

	func notifyNextOfKin() {

		let nc = NSNotificationCenter.defaultCenter()

		nc.postNotificationName("updateView", object: nil)
		if (hud != nil) {
			hud!.hide(true)
		}
	}
	func chooseImage() {
		let alertController = UIAlertController.init(title: "What do you want to do?", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
		let deleteButton = UIAlertAction.init(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (action) in
			self.updateProfileImage(UIImage.init(color: self.profileImage!.tintColor))
			self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
			let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
			dispatch_async(dispatch_get_global_queue(priority, 0)) {
				dispatch_async(dispatch_get_main_queue()) {
			} }
			self.notifyNextOfKin()
			self.saveImage("profile-pic", data: UIImage.init(color: self.profileImage!.tintColor))
		})
		let updateButton = UIAlertAction.init(title: "Choose from Library", style: UIAlertActionStyle.Default, handler: { (action) in
			self.imagePicker.allowsEditing = false
			self.imagePicker.sourceType = .PhotoLibrary

			self.presentViewController(self.imagePicker, animated: true, completion: nil)
		})
        let cameraButton = UIAlertAction.init(title: "Take New Photo", style: UIAlertActionStyle.Default, handler: { (action) in
    
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .Camera
            
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
        })
		let canelButton = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) in

			alertController.dismissViewControllerAnimated(true, completion: nil)
			}
		)
		alertController.addAction(canelButton)
        alertController.addAction(cameraButton)
		alertController.addAction(updateButton)
		alertController.addAction(deleteButton)
  
		self.presentViewController(alertController, animated: true, completion: nil)
	}

	@IBAction func saveAll() {
        if sensitivity?.text != "" {
            NSUserDefaults.standardUserDefaults().setObject(sensitivity?.text, forKey: "sensitivity")
        }
        if carbRatio?.text != "" {
              NSUserDefaults.standardUserDefaults().setObject(carbRatio?.text, forKey: "ratio")
        }
        if targetBG?.text != "" {
              NSUserDefaults.standardUserDefaults().setObject(targetBG?.text, forKey: "target")
        }
        
        if doctorEmail?.text != "" {
            NSUserDefaults.standardUserDefaults().setObject(doctorEmail?.text, forKey: "dr-email")
        }
        if doctorName?.text != "" {
            NSUserDefaults.standardUserDefaults().setObject(doctorName?.text, forKey: "dr-name")
        }
        for view in self.view.subviews {
            if view is UITextField{
                let field = view as! UITextField
                field.resignFirstResponder()
            }
        }
        self.view.endEditing(true)
        NSUserDefaults.standardUserDefaults().synchronize()
		hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
		let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
		dispatch_async(dispatch_get_global_queue(priority, 0)) {
			dispatch_async(dispatch_get_main_queue()) {
				self.notifyNextOfKin()
				self.saveName("profile-name", name: (self.name?.text)!)
			}
		}
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		switch indexPath.row {
		case 0:
			self.performSelector(#selector(self.chooseImage))
			self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
		default:
			self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
		}
	}
	func updateProfileImage(image: UIImage) {
		let transitionOptions: UIViewAnimationOptions = [.TransitionFlipFromTop, .ShowHideTransitionViews]

		UIView.transitionWithView(profileImage!, duration: 0.5, options: transitionOptions, animations: {
			}, completion: nil)

		UIView.transitionWithView(profileImage!, duration: 0.5, options: transitionOptions, animations: {
			self.profileImage?.image = image
			}, completion: nil)
		let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
		dispatch_async(dispatch_get_global_queue(priority, 0)) {
			dispatch_async(dispatch_get_main_queue()) {
				self.notifyNextOfKin()
		} }
		self.saveImage("profile-pic", data: image)
	}

	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: AnyObject]) {
		if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
			self.updateProfileImage(pickedImage)
		}

		dismissViewControllerAnimated(true, completion: nil)
	}
}
