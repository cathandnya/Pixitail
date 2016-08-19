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

	private var activityViews = Dictionary<Int, UIActivityIndicatorView>()
	
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
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		refresh()
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		
		if let block = handler {
			NSLog("viewWillDisappear completionHandler")
			block(.NoData)
			handler = nil
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if EntriesItemList.sharedInstance.count == 0 {
			return 1
		} else {
			return EntriesItemList.sharedInstance.count
		}
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if EntriesItemList.sharedInstance.count == 0 {
			return 44
		} else {
			return WidgetCell.heightForWidth(self.view.frame.size.width)
		}
	}
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if EntriesItemList.sharedInstance.count == 0 {
			return 0
		} else {
			return sectionHeaderHeight
		}
	}
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if EntriesItemList.sharedInstance.count == 0 {
			return nil
		}
		
		let view = UIView(frame: CGRectMake(0, 0, 320, sectionHeaderHeight))
		view.backgroundColor = UIColor.clearColor()
		
		let label = UILabel(frame: CGRectMake(5, 0, 310 - 21 - 5, sectionHeaderHeight))
		label.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
		label.backgroundColor = UIColor.clearColor()
		label.font = UIFont.boldSystemFontOfSize(11)
		label.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
		label.text = EntriesItemList.sharedInstance[section].name
		view.addSubview(label)
		
		var activityView: UIActivityIndicatorView
		if let activity = activityViews[section] {
			activityView = activity
			activityView.removeFromSuperview()
		} else {
			activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
			activityView.hidesWhenStopped = true
			activityView.layer.setValue(0.6, forKeyPath: "transform.scale")
			activityViews[section] = activityView
		}
		activityView.frame = CGRectMake(320 - 21 - 5, -2, 21, 21)
		activityView.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin
		view.addSubview(activityView)
		
		return view
	}

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if EntriesItemList.sharedInstance.count == 0 {
			return tableView.dequeueReusableCellWithIdentifier("no_item", forIndexPath: indexPath) as UITableViewCell
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! WidgetCell
			
			cell.selectionStyle = UITableViewCellSelectionStyle.None
			cell.entries = EntriesItemList.sharedInstance[indexPath.section].entries
			cell.context = self.extensionContext
			
			return cell
		}
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		if EntriesItemList.sharedInstance.count == 0 {
			var url: NSURL?
			#if PIXITAIL
				url = NSURL(string: "pixitail://org.cathand.pixitail/settings/widget")
			#else
				url = NSURL(string: "illustail://org.cathand.illustail/settings/widget")
			#endif
			if let u = url {
				extensionContext?.openURL(u, completionHandler: nil)
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
			preferredContentSize = CGSizeMake(0, 44)
		} else {
			preferredContentSize = CGSizeMake(0, CGFloat(EntriesItemList.sharedInstance.count) * (WidgetCell.heightForWidth(self.view.frame.size.width) + sectionHeaderHeight))
		}
	}
	
	func reloadData() {
		updatePreferredContentSize()
		tableView.reloadData()
	}

	func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
		return UIEdgeInsetsZero
		//marginInsets = defaultMarginInsets
		//return defaultMarginInsets
	}
	
	private var handler: ((NCUpdateResult) -> Void)?
	
	func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
		// Perform any setup necessary in order to update the view.
		
		// If an error is encountered, use NCUpdateResult.Failed
		// If there's no update required, use NCUpdateResult.NoData
		// If there's an update, use NCUpdateResult.NewData
		
		NSLog("widgetPerformUpdateWithCompletionHandler")
		
		completionHandler(.NoData)
		//handler = completionHandler
		
		refresh()
	}
	
	private var updateResult = NCUpdateResult.NoData
	private var loaded = true
	
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
			block(.NoData)
			handler = nil
		}
		loaded = true
	}
	
	func refresh() {
		if !loaded {
			if let block = handler {
				NSLog("completionHandler")
				block(.NoData)
				handler = nil
			}
			return
		}
		
		updateResult = .NoData
		loaded = false
		
		if EntriesItemList.sharedInstance.list.count > 0 {
			var section = 0
			for item in EntriesItemList.sharedInstance.list {
				weak var activity = activityViews[section]
				activity?.startAnimating()
				
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] in
					if let me = self {
						let ret = item.entries.refresh()
						if ret == NCUpdateResult.Failed {
							me.updateResult = ret
						} else if ret == NCUpdateResult.NewData {
							me.updateResult = ret
						}
						item.entries.save()
						
						dispatch_async(dispatch_get_main_queue()) {
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
				block(.NoData)
				handler = nil
			}
			loaded = true
		}
		
		reloadData()
	}
}
