//
//  EntriesItemList.swift
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

import UIKit

class EntriesItemList {
	
	class var sharedInstance: EntriesItemList {
		get {
			struct Static {
				static var instance : EntriesItemList? = nil
				static var token : dispatch_once_t = 0
			}
			
			dispatch_once(&Static.token) {
				Static.instance = EntriesItemList()
			}
			
			return Static.instance!
		}
	}
	
	var list: [EntriesItem]
	init() {
		list = []
	}
	
	func refresh() {
		list = []
		
		#if PIXITAIL
		let defaults = NSUserDefaults(suiteName: "group.org.cathand.pixitail")
		#else
		let defaults = NSUserDefaults(suiteName: "group.org.cathand.illustail")
		#endif

		if let widgets = defaults?.objectForKey("widgets") as? [NSDictionary] {
			for i in widgets {
				let item = EntriesItem(info: i)
				list.append(item)
			}
		}
	}
	
	var count: Int {
		get {
			return list.count
		}
	}
	
	subscript(index: Int) -> EntriesItem {
		get {
			return list[index]
		}
	}
}
