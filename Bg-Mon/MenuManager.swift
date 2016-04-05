//
//  MenuManagert.swift
//  Bg-Mon
//
//  Created by Keaton Burleson on 4/4/16.
//  Copyright © 2016 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import SlideMenuControllerSwift

class MenuManager: SlideMenuController {
    
    override func awakeFromNib() {
        if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("Dash") {
            self.mainViewController = controller
        }
        if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("Menu") {
            self.leftViewController = controller
        }
        super.awakeFromNib()
    }
    
}
