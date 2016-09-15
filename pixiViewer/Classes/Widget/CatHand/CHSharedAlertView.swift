//
//  CHSharedAlertView.swift
//
//  Created by nya on 2014/06/10.
//  Copyright (c) 2014年 CatHand.org. All rights reserved.
//

import UIKit


class CHSharedAlertView {

    var isPresent = false
	
	static var sharedInstance = CHSharedAlertView()
	
	class func show(_ title: String?, message: String?, fromViewController: UIViewController?) {
		let obj = CHSharedAlertView.sharedInstance
		if !obj.isPresent {
			if let vc = fromViewController {
				let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
				alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default, handler: {(action: UIAlertAction) in
					obj.isPresent = false;
					}))
				vc.present(alert, animated: true, completion: nil)
				obj.isPresent = true;
			}
		}
	}
	
	class func show(_ title: String?, error: NSError?, fromViewController: UIViewController?) {
		show(title, message: error?.localizedDescription, fromViewController: fromViewController)
	}
}
