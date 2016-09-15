//
//  CHCachedImageView.swift
//
//  Created by nya on 2014/06/10.
//  Copyright (c) 2014年 CatHand.org. All rights reserved.
//

import UIKit


class CHCachedImageView : UIImageView {
    var errorHandler: ((_ error: NSError?) -> Void)? = nil
	var referer: String?
	
	var url: URL? {
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
						var req = URLRequest(url: u)
						if let r = referer {
							req.addValue(r, forHTTPHeaderField: "Referer")
						}
						
						NSURLConnection.sendAsynchronousRequest(req, queue: OperationQueue.main) {[weak self] (res: URLResponse?, data: Data?, err: Error?) -> Void in
							if let me = self {
								if (me.key == nil || me.key == str) {
									if let e = err {
										me.failed(err: e as NSError)
									} else {
										if let d = data {
											let img = UIImage(data: d)
											if let i = img {
												me.image = i
												let _ = CHImageCache.sharedInstance.setData(d, key: str)
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
			handler(err)
		}
	}
	
	var key: String?
}
