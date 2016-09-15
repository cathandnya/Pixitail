//
//  CHImageScaling.swift
//
//  Created by nya on 2014/06/11.
//  Copyright (c) 2014年 CatHand.org. All rights reserved.
//

import UIKit


extension UIImage {
	func scale(_ maxResolution: CGFloat, orientation: UIImageOrientation) -> UIImage {
		let image = self
		let imgRef = image.cgImage
		let width = CGFloat((imgRef?.width)!)
		let height = CGFloat((imgRef?.height)!)
		
		var transform = CGAffineTransform.identity;
		var bounds = CGRect(x: 0, y: 0, width: width, height: height)
		if (width > maxResolution || height > maxResolution) {
			let ratio = width / height
			if (ratio > 1) {
				bounds.size.width = maxResolution;
				bounds.size.height = bounds.size.width / ratio;
			} else {
				bounds.size.height = maxResolution;
				bounds.size.width = bounds.size.height * ratio;
			}
		}
		
		let scaleRatio = bounds.size.width / width
		let imageSize = CGSize(width: width, height: height)
		var boundHeight: CGFloat
		
		switch(orientation) {
		case UIImageOrientation.up:
			transform = CGAffineTransform.identity;
			break;
		case UIImageOrientation.upMirrored:
			transform = CGAffineTransform(translationX: imageSize.width, y: 0.0);
			transform = transform.scaledBy(x: -1.0, y: 1.0);
			break;
		case UIImageOrientation.down:
			transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height);
			transform = transform.rotated(by: CGFloat(M_PI));
			break;
		case UIImageOrientation.downMirrored:
			transform = CGAffineTransform(translationX: 0.0, y: imageSize.height);
			transform = transform.scaledBy(x: 1.0, y: -1.0);
			break;
		case UIImageOrientation.leftMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width);
			transform = transform.scaledBy(x: -1.0, y: 1.0);
			transform = transform.rotated(by: 3.0 * CGFloat(M_PI) / 2.0);
			break;
		case UIImageOrientation.left:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransform(translationX: 0.0, y: imageSize.width);
			transform = transform.rotated(by: 3.0 * CGFloat(M_PI) / 2.0);
			break;
		case UIImageOrientation.rightMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
			transform = transform.rotated(by: CGFloat(M_PI) / 2.0);
			break;
		case UIImageOrientation.right:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransform(translationX: imageSize.height, y: 0.0);
			transform = transform.rotated(by: CGFloat(M_PI) / 2.0);
			break;
		}
		
		UIGraphicsBeginImageContext(bounds.size);
		let context = UIGraphicsGetCurrentContext();
		context?.saveGState();
		if (orientation == UIImageOrientation.right || orientation == UIImageOrientation.left) {
			context?.scaleBy(x: -scaleRatio, y: scaleRatio);
			context?.translateBy(x: -height, y: 0);
		} else {
			context?.scaleBy(x: scaleRatio, y: -scaleRatio);
			context?.translateBy(x: 0, y: -height);
		}
		context?.concatenate(transform);
		context?.draw(imgRef!, in: CGRect(x: 0, y: 0, width: width, height: height));
		let imageCopy = UIGraphicsGetImageFromCurrentImageContext();
		context?.restoreGState();
		UIGraphicsEndImageContext();
		
		return imageCopy!
	}
	
	func scale(_ maxResolution: CGFloat) -> UIImage {
		return scale(maxResolution, orientation: self.imageOrientation)
	}
}
