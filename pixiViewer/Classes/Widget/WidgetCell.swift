//
//  WidgetCell.swift
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

import UIKit


let margin: CGFloat = 1
let defaultImageSize: CGFloat = 75


class WidgetCell: UITableViewCell {

	fileprivate var imageViews: [CHCachedImageView] = []
	//private var activityBaseView: RoundedRectView
	//private var activityView: UIActivityIndicatorView
	fileprivate var selectionLayer: CALayer
	var context: NSExtensionContext?

    required init?(coder aDecoder: NSCoder) {
		//activityBaseView = RoundedRectView(frame: CGRectMake(0, 0, 44, 44))
		//activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
		selectionLayer = CALayer()
		
		super.init(coder: aDecoder)
		
		//contentView.addSubview(activityBaseView)
		//contentView.addSubview(activityView)
		contentView.layer.addSublayer(selectionLayer)
		
		/*
		activityBaseView.backgroundColor = UIColor.clearColor()
		activityBaseView.color = UIColor.blackColor().colorWithAlphaComponent(0.7)
		activityBaseView.radius = 4
		activityView.hidesWhenStopped = true;
		*/
		selectionLayer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
		selectionLayer.isHidden = true;
		selectionLayer.zPosition = 10
		
		let gr = UITapGestureRecognizer(target: self, action: #selector(WidgetCell.tapAction(_:)))
		self.contentView.addGestureRecognizer(gr)
	}

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	class func heightForWidth(_ w: CGFloat) -> CGFloat {
		return floor(w / CGFloat(Int(w / defaultImageSize)))
	}

	fileprivate var cols: Int {
		get {
			return Int(self.frame.size.width / imageSize)
		}
	}
	fileprivate var imageSize: CGFloat {
		get {
			return WidgetCell.heightForWidth(self.frame.size.width)
		}
	}
	
	var entries: Entries? {
		didSet {
			setNeedsLayout()
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		var count = 0
		if let es = entries {
			count = min(cols, es.list.count)
		}
		if count < imageViews.count {
			while imageViews.count != count {
				imageViews.last!.removeFromSuperview()
				imageViews.removeLast()
			}
		}
		if count > 0 {
			for i in 0...count-1 {
				if let e = entries?.list[i] as? Entry {
					var v: CHCachedImageView
					if i < imageViews.count {
						v = imageViews[i]
					} else {
						v = CHCachedImageView()
						v.backgroundColor = UIColor.white.withAlphaComponent(0.2)
						v.contentMode = UIViewContentMode.scaleAspectFill
						v.clipsToBounds = true
						v.referer = "http://www.pixiv.net/"
						contentView.addSubview(v)
						//contentView.insertSubview(v, belowSubview: activityBaseView)
						imageViews.append(v)
					}
					v.url = URL(string: e.thumbnail_url)
				}
			}
		}
		
		let size = imageSize
		var r = CGRect(x: 0, y: 0, width: size, height: size)
		for v in imageViews {
			var f = r;
			if v != imageViews.last {
				f.size.width -= margin
			}
			v.frame = f
			r.origin.x += r.size.width
		}
		
		/*
		activityBaseView.center = contentView.center
		activityView.center = contentView.center
		if let es = entries {
			if es.isLoading && !activityView.isAnimating() {
				activityView.startAnimating();
			} else if !es.isLoading && activityView.isAnimating() {
				activityView.stopAnimating();
			}
			activityBaseView.hidden = !es.isLoading
		} else {
			if activityView.isAnimating() {
				activityView.stopAnimating();
			}
			activityBaseView.hidden = true
		}
		*/
		
		selectionLayer.isHidden = true;
	}
	
	func tapAction(_ sender: UITapGestureRecognizer) {
		let loc = sender.location(in: contentView)
		for v in imageViews {
			if v.frame.contains(loc) {
				if let idx = imageViews.index(of: v) {
					CATransaction.begin()
					CATransaction.setDisableActions(true)
					selectionLayer.frame = v.frame
					selectionLayer.isHidden = false
					CATransaction.commit()
					
					DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(NSEC_PER_SEC / 10)) / Double(NSEC_PER_SEC)) {
						if let e = self.entries?.list[idx] as? Entry {
							self.selected(e)
						}
					}
				}
			}
		}
	}
	
	func selected(_ entry: Entry) {
		var url: URL?
		if entry.service_name == "pixiv" {
			url = URL(string: "pixitail://org.cathand.pixitail/pixiv/\(entry.illust_id)")
		} else if entry.service_name == "TINAMI" {
			url = URL(string: "illustail://org.cathand.illustail/tinami/\(entry.illust_id)")
		} else if entry.service_name == "Danbooru" && entry.other_info != nil {
			if let defaults = UserDefaults(suiteName: "group.org.cathand.illustail") {
				defaults.set(entry.other_info, forKey: "danbooru_selected_post")
				defaults.synchronize()
				
				url = URL(string: "illustail://org.cathand.illustail/danbooru/\(entry.illust_id)")
			}
		} else if entry.service_name == "Seiga" {
			url = URL(string: "illustail://org.cathand.illustail/seiga/\(entry.illust_id)")
		}
		
		if let u = url {
			self.context?.open(u, completionHandler: nil)
		}
	}
}
