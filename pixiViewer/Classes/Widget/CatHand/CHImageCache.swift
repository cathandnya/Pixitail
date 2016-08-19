//
//  CHImageCache.swift
//
//  Created by nya on 2014/06/07.
//  Copyright (c) 2014年 CatHand.org. All rights reserved.
//

import Foundation


class CHImageCache {
	class var sharedInstance: CHImageCache {
	get {
		struct Static {
			static var instance : CHImageCache? = nil
			static var token : dispatch_once_t = 0
		}
			
		dispatch_once(&Static.token) {
			let path: String = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
			Static.instance = CHImageCache(path: (path as NSString).stringByAppendingPathComponent("CHImageCache"))
		}
			
		return Static.instance!
	}
	}
	
	init(path: String, cacheSize: UInt64 = 100 * 1000 * 1000) {
		self.basePath = path;
		self.cacheSize = cacheSize;
		self.totalCacheSize = 0;
		
		if !NSFileManager.defaultManager().fileExistsAtPath(self.basePath) {
			do {
				try NSFileManager.defaultManager().createDirectoryAtPath(self.basePath, withIntermediateDirectories:true, attributes: nil)
			} catch _ {
			}
		}
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			self.calculateCacheSizeAndFillUsageMap()
		}
	}
	
	class func keyForURL(url: NSURL) -> String {
		return "\(url.absoluteString.hash)"
	}
	
	func contains(key: String) -> Bool {
		let path = pathForKey(key)
		return NSFileManager.defaultManager().fileExistsAtPath(path)
	}
	
	func data(key: String) -> NSData? {
		let path = pathForKey(key)
		let data = NSData(contentsOfFile: path)
		if var info = filesDic[path] {
			info.date = NSDate()
		}
		return data
	}
	
	func setData(data: NSData, key: String) -> Bool {
		let path = pathForKey(key)
		let b = data.writeToFile(path, atomically: true)
		if !b {
			return false
		} else {
			let len: UInt64 = UInt64(data.length)
			filesDic[path] = FileInfo(size: len, date: NSDate(), path: path)
			self.totalCacheSize += len;
			
			if self.totalCacheSize > self.cacheSize {
				var mary = Array(self.filesDic.values)
				mary.sortInPlace {
					(obj1 : FileInfo, obj2 : FileInfo) -> Bool in
					return obj1.date.timeIntervalSinceReferenceDate < obj2.date.timeIntervalSinceReferenceDate
				}
				
				while self.totalCacheSize > self.cacheSize {
					let obj = mary[0]
					do {
						try NSFileManager.defaultManager().removeItemAtPath(obj.path)
						self.totalCacheSize -= obj.size
						self.filesDic.removeValueForKey(obj.path)
						mary.removeAtIndex(0)
					} catch _ {
						break;
					}
				}
			}
			return true;
		}
	}
	
	func removeData(key: String) {
		let path = pathForKey(key)
		if NSFileManager.defaultManager().fileExistsAtPath(path) {
			do {
				try NSFileManager.defaultManager().removeItemAtPath(path)
			} catch _ {
			}
		}
	}
	
	func removeAll() {
		do {
			try NSFileManager.defaultManager().removeItemAtPath(self.basePath)
		} catch _ {
		}
	}

	// private
	
	var basePath: String
	var cacheSize: UInt64
	var totalCacheSize: UInt64
	var filesDic = Dictionary<String, FileInfo>()
	
	struct FileInfo {
		var size: UInt64
		var date: NSDate
		var path: String
	}
	
	func pathForKey(key: String) -> String {
		return (self.basePath as NSString).stringByAppendingPathComponent(key)
	}
	
	func calculateCacheSizeAndFillUsageMap() {
		var total: UInt64 = 0;
		
		var mary = Array<FileInfo>()
        do {
            let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(basePath);
            for name in contents {
                if let path = NSURL(fileURLWithPath: basePath).URLByAppendingPathComponent(name).path {
                    do {
                        let a = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
                        let size = (a[NSFileSize] as! NSNumber).unsignedLongLongValue
                        let date = a[NSFileModificationDate] as! NSDate?
                        if let d = date {
                            let info = FileInfo(size: size, date: d, path: path)
                            mary.append(info)
                            total += size;
                        }
                    } catch {
                    }
                }
            }
        } catch {
        }
        
		mary.sortInPlace {
			(obj1 : FileInfo, obj2 : FileInfo) -> Bool in
			return obj1.date.timeIntervalSinceReferenceDate < obj2.date.timeIntervalSinceReferenceDate
		}
		
		// 古いのけしとく
		while total > self.cacheSize {
			let obj = mary[0]
			do {
				try NSFileManager.defaultManager().removeItemAtPath(obj.path)
				total -= obj.size
				mary.removeAtIndex(0);
			} catch _ {
				// 削除失敗
				break
			}
		}
	
		dispatch_async(dispatch_get_main_queue()) {
			for obj in mary {
				self.filesDic[obj.path] = obj;
			}
			self.totalCacheSize = total
		}
	}
	
}
