//
//  CHCachedImageView.swift
//
//  Created by nya on 2014/06/10.
//  Copyright (c) 2014年 CatHand.org. All rights reserved.
//

import UIKit


class CHCachedImageView : UIImageView {
	var errorHandler: ((error: NSError?) -> Void)? = nil
	var referer: String?
	
	var url: NSURL? {
		didSet {
			if let u = url {
				let str = CHImageCache.keyForURL(u)
				if key != str {
					self.image = nil
				}
				if self.image == nil {
					self.key = str
					
					if let data = CHImageCache.sharedInstance.data(str) {
						let img: UIImage? = UIImage(data: data)
						if let i = img {
							self.image = i
						} else {
							CHImageCache.sharedInstance.removeData(str)
							self.failed()
						}
					} else {
						// load
						let req = NSMutableURLRequest(URL: u)
						if let r = referer {
							req.addValue(r, forHTTPHeaderField: "Referer")
						}
						
						NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue()) {[weak self] (res: NSURLResponse?, data: NSData?, err: NSError?) -> Void in
							if let me = self {
								if (me.key == nil || me.key == str) {
									if let e = err {
										me.failed(e)
									} else {
										if let d: NSData = data {
											let img: UIImage? = UIImage(data: d)
											if let i = img {
												me.image = i
												CHImageCache.sharedInstance.setData(d, key: str)
											} else {
												me.failed()
											}
										} else {
											me.failed();
										}
									}
								}
							}
						}
					}
				}
			} else {
				self.key = nil
				self.image = nil
			}
		}
	}
	
	// private
	
	func failed(err: NSError? = nil) {
		self.key = nil
		self.image = nil
		
		if let handler = errorHandler {
			handler(error: err)
		}
	}
	
	var key: String?
}
