//
//  WidgetViewController.swift
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

import UIKit
import NotificationCenter


let sectionHeaderHeight: CGFloat = 16


class WidgetViewController: UITableViewController, NCWidgetProviding {

	fileprivate var activityViews = Dictionary<Int, UIActivityIndicatorView>()
	
    override func viewDidLoad() {
        super.viewDidLoad()

		NSLog("viewDidLoad")

		// Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		EntriesItemList.sharedInstance.refresh()
		
		for item in EntriesItemList.sharedInstance.list {
			item.entries.load()
		}
		reloadData()
    }
	
	deinit {
		NSLog("deinit")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		refresh()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if let block = handler {
			NSLog("viewWillDisappear completionHandler")
			block(.noData)
			handler = nil
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		if EntriesItemList.sharedInstance.count == 0 {
			return 1
		} else {
			return EntriesItemList.sharedInstance.count
		}
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if EntriesItemList.sharedInstance.count == 0 {
			return 44
		} else {
			return WidgetCell.heightForWidth(self.view.frame.size.width)
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if EntriesItemList.sharedInstance.count == 0 {
			return 0
		} else {
			return sectionHeaderHeight
		}
	}
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if EntriesItemList.sharedInstance.count == 0 {
			return nil
		}
		
		let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: sectionHeaderHeight))
		view.backgroundColor = UIColor.clear
		
		let label = UILabel(frame: CGRect(x: 5, y: 0, width: 310 - 21 - 5, height: sectionHeaderHeight))
		label.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
		label.backgroundColor = UIColor.clear
		label.font = UIFont.boldSystemFont(ofSize: 11)
		label.textColor = UIColor.white.withAlphaComponent(0.7)
		label.text = EntriesItemList.sharedInstance[section].name
		view.addSubview(label)
		
		var activityView: UIActivityIndicatorView
		if let activity = activityViews[section] {
			activityView = activity
			activityView.removeFromSuperview()
		} else {
			activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
			activityView.hidesWhenStopped = true
			activityView.layer.setValue(0.6, forKeyPath: "transform.scale")
			activityViews[section] = activityView
		}
		activityView.frame = CGRect(x: 320 - 21 - 5, y: -2, width: 21, height: 21)
		activityView.autoresizingMask = UIViewAutoresizing.flexibleLeftMargin
		view.addSubview(activityView)
		
		return view
	}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if EntriesItemList.sharedInstance.count == 0 {
			return tableView.dequeueReusableCell(withIdentifier: "no_item", for: indexPath) as UITableViewCell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! WidgetCell
			
			cell.selectionStyle = UITableViewCellSelectionStyle.none
			cell.entries = EntriesItemList.sharedInstance[(indexPath as NSIndexPath).section].entries
			cell.context = self.extensionContext
			
			return cell
		}
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if EntriesItemList.sharedInstance.count == 0 {
			var url: URL?
			#if PIXITAIL
				url = URL(string: "pixitail://org.cathand.pixitail/settings/widget")
			#else
				url = URL(string: "illustail://org.cathand.illustail/settings/widget")
			#endif
			if let u = url {
				extensionContext?.open(u, completionHandler: nil)
			}
		}
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView!, moveRowAtIndexPath fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView!, canMoveRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
	
	func updatePreferredContentSize() {
		if EntriesItemList.sharedInstance.count == 0 {
			preferredContentSize = CGSize(width: 0, height: 44)
		} else {
			preferredContentSize = CGSize(width: 0, height: CGFloat(EntriesItemList.sharedInstance.count) * (WidgetCell.heightForWidth(self.view.frame.size.width) + sectionHeaderHeight))
		}
	}
	
	func reloadData() {
		updatePreferredContentSize()
		tableView.reloadData()
	}

	func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
		return UIEdgeInsets.zero
		//marginInsets = defaultMarginInsets
		//return defaultMarginInsets
	}
	
	fileprivate var handler: ((NCUpdateResult) -> Void)?
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		// Perform any setup necessary in order to update the view.
		
		// If an error is encountered, use NCUpdateResult.Failed
		// If there's no update required, use NCUpdateResult.NoData
		// If there's an update, use NCUpdateResult.NewData
		
		NSLog("widgetPerformUpdateWithCompletionHandler")
		
		completionHandler(.noData)
		//handler = completionHandler
		
		refresh()
	}
	
	fileprivate var updateResult = NCUpdateResult.noData
	fileprivate var loaded = true
	
	func refreshEnd() {
		if loaded {
			return
		}
		
		for item in EntriesItemList.sharedInstance.list {
			if item.entries.isLoading {
				return;
			}
		}
		
		if let block = handler {
			NSLog("completionHandler")
			block(.noData)
			handler = nil
		}
		loaded = true
	}
	
	func refresh() {
		if !loaded {
			if let block = handler {
				NSLog("completionHandler")
				block(.noData)
				handler = nil
			}
			return
		}
		
		updateResult = .noData
		loaded = false
		
		if EntriesItemList.sharedInstance.list.count > 0 {
			var section = 0
			for item in EntriesItemList.sharedInstance.list {
				weak var activity = activityViews[section]
				activity?.startAnimating()
				
				DispatchQueue.global().async { [weak self] in
					if let me = self {
						let ret = item.entries.refresh()
						if ret == NCUpdateResult.failed {
							me.updateResult = ret
						} else if ret == NCUpdateResult.newData {
							me.updateResult = ret
						}
						item.entries.save()
						
						DispatchQueue.main.async {
							activity?.stopAnimating()
							
							if let me = self {
								for cell in me.tableView.visibleCells as! [WidgetCell] {
									cell.setNeedsLayout()
								}
								me.refreshEnd()
							}
						}
					}
				}
				
				section += 1
			}
		} else {
			if let block = handler {
				NSLog("completionHandler")
				block(.noData)
				handler = nil
			}
			loaded = true
		}
		
		reloadData()
	}
}
