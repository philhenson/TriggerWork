//
//  MainTabBarController.swift
//  TriggerWork
//
//  Created by Phil Henson on 7/31/16.
//  Copyright © 2016 Lost Nation R&D. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Customize tab bar colors
    self.tabBar.barTintColor = Colors.defaultBlackColor()
    self.tabBar.tintColor = Colors.defaultGreenColor()
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  
}
