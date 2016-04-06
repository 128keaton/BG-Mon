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
		NSUserDefaults.standardUserDefaults().setObject(UIImagePNGRepresentation(data), forKey: "profile-pic")
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
		let updateButton = UIAlertAction.init(title: "Change", style: UIAlertActionStyle.Default, handler: { (action) in
			self.imagePicker.allowsEditing = false
			self.imagePicker.sourceType = .PhotoLibrary

			self.presentViewController(self.imagePicker, animated: true, completion: nil)
		})
		let canelButton = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) in

			alertController.dismissViewControllerAnimated(true, completion: nil)
			}
		)
		alertController.addAction(canelButton)
		alertController.addAction(updateButton)
		alertController.addAction(deleteButton)
		self.presentViewController(alertController, animated: true, completion: nil)
	}

	@IBAction func saveAll() {
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
