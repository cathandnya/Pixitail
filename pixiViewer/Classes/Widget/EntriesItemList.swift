//
//  EntriesItemList.swift
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

import UIKit

class EntriesItemList {
	
	static let sharedInstance = EntriesItemList()
	
	var list: [EntriesItem]
	init() {
		list = []
	}
	
	func refresh() {
		list = []
		
		#if PIXITAIL
		let defaults = UserDefaults(suiteName: "group.org.cathand.pixitail")
		#else
		let defaults = UserDefaults(suiteName: "group.org.cathand.illustail")
		#endif

		if let widgets = defaults?.object(forKey: "widgets") as? [NSDictionary] {
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
