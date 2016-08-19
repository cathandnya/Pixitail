//
//  CHSharedAlertView.swift
//
//  Created by nya on 2014/06/10.
//  Copyright (c) 2014年 CatHand.org. All rights reserved.
//

import UIKit


class CHSharedAlertView {
	var isPresent = false
	
	class var sharedInstance: CHSharedAlertView {
		get {
			struct Static {
				static var instance : CHSharedAlertView? = nil
				static var token : dispatch_once_t = 0
			}
			
			dispatch_once(&Static.token) {
				Static.instance = CHSharedAlertView()
			}
			
			return Static.instance!
		}
	}
	
	class func show(title: String?, message: String?, fromViewController: UIViewController?) {
		let obj = CHSharedAlertView.sharedInstance
		if !obj.isPresent {
			if let vc = fromViewController {
				let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
				alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction) in
					obj.isPresent = false;
					}))
				vc.presentViewController(alert, animated: true, completion: nil)
				obj.isPresent = true;
			}
		}
	}
	
	class func show(title: String?, error: NSError?, fromViewController: UIViewController?) {
		show(title, message: error?.localizedDescription, fromViewController: fromViewController)
	}
}
