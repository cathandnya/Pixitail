//
//  EntriesItem.swift
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

import UIKit

class EntriesItem {
	
	var name: String
	var entries: Entries
	
	init(info: NSDictionary) {
		name = info["name"] as! String;
		
		var dic = [String: String]();
		if let method = info["method"] as? String {
			dic["method"] = method
		}
		if let parser = info["parser"] as? String {
			dic["parser"] = parser
		}
		entries = MatrixEntries(info: dic)
		
		let serviceName = info["service"] as! String;
		let username = info["username"] as! String;
		var password = info["password"] as! String;
		password = password.decryptedString()
		entries.service = Service(name: serviceName, username: username, password: password)
	}
}
