//
//  CHImageCache.swift
//
//  Created by nya on 2014/06/07.
//  Copyright (c) 2014年 CatHand.org. All rights reserved.
//

import Foundation


class CHImageCache {

    static let sharedInstance = { () -> CHImageCache in
        let path: String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        return CHImageCache(path: (path as NSString).appendingPathComponent("CHImageCache"))
    }()
	
	init(path: String, cacheSize: UInt64 = 100 * 1000 * 1000) {
		self.basePath = path;
		self.cacheSize = cacheSize;
		self.totalCacheSize = 0;
		
		if !FileManager.default.fileExists(atPath: self.basePath) {
			do {
				try FileManager.default.createDirectory(atPath: self.basePath, withIntermediateDirectories:true, attributes: nil)
			} catch _ {
			}
		}
		
		DispatchQueue.global().async {
			self.calculateCacheSizeAndFillUsageMap()
		}
	}
	
	class func keyForURL(_ url: URL) -> String {
		return "\(url.absoluteString.hash)"
	}
	
	func contains(_ key: String) -> Bool {
		let path = pathForKey(key)
		return FileManager.default.fileExists(atPath: path)
	}
	
	func data(_ key: String) -> Data? {
		let path = pathForKey(key)
		let data = try? Data(contentsOf: URL(fileURLWithPath: path))
		if var info = filesDic[path] {
			info.date = Date()
		}
		return data
	}
	
	func setData(_ data: Data, key: String) -> Bool {
		let path = pathForKey(key)
		let b = (try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil
		if !b {
			return false
		} else {
			let len: UInt64 = UInt64(data.count)
			filesDic[path] = FileInfo(size: len, date: Date(), path: path)
			self.totalCacheSize += len;
			
			if self.totalCacheSize > self.cacheSize {
				var mary = Array(self.filesDic.values)
				mary.sort {
					(obj1 : FileInfo, obj2 : FileInfo) -> Bool in
					return obj1.date.timeIntervalSinceReferenceDate < obj2.date.timeIntervalSinceReferenceDate
				}
				
				while self.totalCacheSize > self.cacheSize {
					let obj = mary[0]
					do {
						try FileManager.default.removeItem(atPath: obj.path)
						self.totalCacheSize -= obj.size
						self.filesDic.removeValue(forKey: obj.path)
						mary.remove(at: 0)
					} catch _ {
						break;
					}
				}
			}
			return true;
		}
	}
	
	func removeData(_ key: String) {
		let path = pathForKey(key)
		if FileManager.default.fileExists(atPath: path) {
			do {
				try FileManager.default.removeItem(atPath: path)
			} catch _ {
			}
		}
	}
	
	func removeAll() {
		do {
			try FileManager.default.removeItem(atPath: self.basePath)
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
		var date: Date
		var path: String
	}
	
	func pathForKey(_ key: String) -> String {
		return (self.basePath as NSString).appendingPathComponent(key)
	}
	
	func calculateCacheSizeAndFillUsageMap() {
		var total: UInt64 = 0;
		
		var mary = Array<FileInfo>()
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: basePath);
            for name in contents {
                let path = URL(fileURLWithPath: basePath).appendingPathComponent(name).path
                do {
                    let a = try FileManager.default.attributesOfItem(atPath: path)
                    let size = (a[FileAttributeKey.size] as! NSNumber).uint64Value
                    let date = a[FileAttributeKey.modificationDate] as! Date?
                    if let d = date {
                        let info = FileInfo(size: size, date: d, path: path)
                        mary.append(info)
                        total += size;
                    }
                } catch {
                }
            }
        } catch {
        }
        
		mary.sort {
			(obj1 : FileInfo, obj2 : FileInfo) -> Bool in
			return obj1.date.timeIntervalSinceReferenceDate < obj2.date.timeIntervalSinceReferenceDate
		}
		
		// 古いのけしとく
		while total > self.cacheSize {
			let obj = mary[0]
			do {
				try FileManager.default.removeItem(atPath: obj.path)
				total -= obj.size
				mary.remove(at: 0);
			} catch _ {
				// 削除失敗
				break
			}
		}
	
		DispatchQueue.main.async {
			for obj in mary {
				self.filesDic[obj.path] = obj;
			}
			self.totalCacheSize = total
		}
	}
	
}
