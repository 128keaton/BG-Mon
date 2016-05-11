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

class ProfileViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
	@IBOutlet var highscore: UILabel?
	@IBOutlet var lowscore: UILabel?
    
    @IBOutlet var sensitivity: UITextField?
    @IBOutlet var targetBG: UITextField?
    @IBOutlet var carbRatio: UITextField?
    
    @IBOutlet var doctorName: UITextField?

    @IBOutlet var doctorEmail: UITextField?
    
	@IBOutlet var name: UITextField?

    @IBOutlet var discardButton: UIBarButtonItem?
    
	var hud: MBProgressHUD?
    

	@IBOutlet var profileImage: UIImageView?

	let imagePicker = UIImagePickerController()
    let defaults = NSUserDefaults(suiteName: "group.com.128keaton.test-strip")
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
        name?.delegate = self
        targetBG?.delegate = self
        sensitivity?.delegate = self
        carbRatio?.delegate = self
        doctorName?.delegate = self
        
        name?.nextField = targetBG
        targetBG?.nextField = sensitivity
        sensitivity?.nextField = carbRatio
        carbRatio?.nextField = doctorName
        doctorName?.nextField = doctorEmail
        

		let tapGesture = UIGestureRecognizer.init(target: self, action: #selector(ProfileViewController.chooseImage))

		imagePicker.delegate = self
		profileImage?.addGestureRecognizer(tapGesture)
		highscore?.text = "\(defaults!.doubleForKey("highscore")) mg/dL"

		lowscore?.text = "\(defaults!.doubleForKey("lowscore")) mg/dL"

		profileImage?.layer.cornerRadius = (profileImage?.bounds.width)! / 2
		profileImage?.layer.borderWidth = 2
		profileImage?.layer.borderColor = profileImage?.tintColor.CGColor
		profileImage?.clipsToBounds = true
	}
  
	func objectAlreadyExist(key: String) -> Bool {
		return defaults!.objectForKey(key) != nil
	}
	func fetchImage(key: String) -> NSData {
		return defaults!.dataForKey(key)!
	}
	func saveImage(key: String, data: UIImage) {
		defaults!.setObject(UIImageJPEGRepresentation(data, 100), forKey: "profile-pic")
		defaults!.synchronize()
	}
	func saveName(key: String, name: String) {
		defaults!.setObject(name, forKey: "profile-name")
		defaults!.synchronize()
	}

	func fetchUsername(key: String) -> NSString {
		return defaults!.objectForKey(key)! as! NSString
	}

	func notifyNextOfKin() {

		let nc = NSNotificationCenter.defaultCenter()

		nc.postNotificationName("updateView", object: nil)
		if (hud != nil) {
			hud!.hide(true)
		}
	}
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.nextField?.becomeFirstResponder()
        return true
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
            defaults!.setObject(sensitivity?.text, forKey: "sensitivity")
        }
        if carbRatio?.text != "" {
              defaults!.setObject(carbRatio?.text, forKey: "ratio")
        }
        if targetBG?.text != "" {
              defaults!.setObject(targetBG?.text, forKey: "target")
        }
        
        if doctorEmail?.text != "" {
            defaults!.setObject(doctorEmail?.text, forKey: "dr-email")
        }
        if doctorName?.text != "" {
            defaults!.setObject(doctorName?.text, forKey: "dr-name")
        }
        for view in self.view.subviews {
            if view is UITextField{
                let field = view as! UITextField
                field.resignFirstResponder()
            }
        }
        self.view.endEditing(true)
        discardButton?.enabled = true
        defaults!.synchronize()
		hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
		let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
		dispatch_async(dispatch_get_global_queue(priority, 0)) {
			dispatch_async(dispatch_get_main_queue()) {
				self.notifyNextOfKin()
				self.saveName("profile-name", name: (self.name?.text)!)
			}
		}
	}
    @IBAction func discardChanges(){
        self.view.endEditing(true)
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
     
            if self.objectAlreadyExist("profile-pic") {
                self.profileImage?.image = UIImage.init(data: self.fetchImage("profile-pic"))
            }
            
            if self.objectAlreadyExist("profile-name") {
                self.name!.text = self.fetchUsername("profile-name") as String
            }else{
                self.name!.text = ""
            }
            if self.objectAlreadyExist("target") {
                self.targetBG?.text = self.fetchUsername("target") as String
            }else{
                self.targetBG?.text = ""
            }
            if self.objectAlreadyExist("ratio") {
                self.carbRatio?.text = self.fetchUsername("ratio") as String
            }else{
                self.carbRatio?.text = ""
            }
            if self.objectAlreadyExist("sensitivity") {
                self.sensitivity?.text = self.fetchUsername("sensitivity") as String
            }else{
                self.sensitivity?.text = ""
            }
            if self.objectAlreadyExist("dr-email") {
                self.doctorEmail!.text = self.fetchUsername("dr-email") as String
            }else{
                self.doctorEmail!.text = ""
            }
            if self.objectAlreadyExist("dr-name") {
                self.doctorName!.text = self.fetchUsername("dr-name") as String
            }else{
                self.doctorName?.text = ""
            }
            }, completion: nil)
        
        discardButton?.enabled = false
        
        
    }

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		switch indexPath.row {
		case 0:
            if indexPath.section == 0{
               self.performSelector(#selector(self.chooseImage)) 
            }
			
			self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
		default:
			self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
		}
	}
    func textFieldDidBeginEditing(textField: UITextField) {
        discardButton?.enabled = true
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
private var kAssociationKeyNextField: UInt8 = 0

extension UITextField {
    var nextField: UITextField? {
        get {
            return objc_getAssociatedObject(self, &kAssociationKeyNextField) as? UITextField
        }
        set(newField) {
            objc_setAssociatedObject(self, &kAssociationKeyNextField, newField, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

