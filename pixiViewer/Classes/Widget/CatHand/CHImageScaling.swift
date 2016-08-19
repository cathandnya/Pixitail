//
//  CHImageScaling.swift
//
//  Created by nya on 2014/06/11.
//  Copyright (c) 2014年 CatHand.org. All rights reserved.
//

import UIKit


extension UIImage {
	func scale(maxResolution: CGFloat, orientation: UIImageOrientation) -> UIImage {
		let image = self
		let imgRef = image.CGImage
		let width = CGFloat(CGImageGetWidth(imgRef))
		let height = CGFloat(CGImageGetHeight(imgRef))
		
		var transform = CGAffineTransformIdentity;
		var bounds = CGRectMake(0, 0, width, height)
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
		let imageSize = CGSizeMake(width, height)
		var boundHeight: CGFloat
		
		switch(orientation) {
		case UIImageOrientation.Up:
			transform = CGAffineTransformIdentity;
			break;
		case UIImageOrientation.UpMirrored:
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
		case UIImageOrientation.Down:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, CGFloat(M_PI));
			break;
		case UIImageOrientation.DownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
		case UIImageOrientation.LeftMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * CGFloat(M_PI) / 2.0);
			break;
		case UIImageOrientation.Left:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * CGFloat(M_PI) / 2.0);
			break;
		case UIImageOrientation.RightMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, CGFloat(M_PI) / 2.0);
			break;
		case UIImageOrientation.Right:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, CGFloat(M_PI) / 2.0);
			break;
		}
		
		UIGraphicsBeginImageContext(bounds.size);
		let context = UIGraphicsGetCurrentContext();
		CGContextSaveGState(context);
		if (orientation == UIImageOrientation.Right || orientation == UIImageOrientation.Left) {
			CGContextScaleCTM(context, -scaleRatio, scaleRatio);
			CGContextTranslateCTM(context, -height, 0);
		} else {
			CGContextScaleCTM(context, scaleRatio, -scaleRatio);
			CGContextTranslateCTM(context, 0, -height);
		}
		CGContextConcatCTM(context, transform);
		CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
		let imageCopy = UIGraphicsGetImageFromCurrentImageContext();
		CGContextRestoreGState(context);
		UIGraphicsEndImageContext();
		
		return imageCopy
	}
	
	func scale(maxResolution: CGFloat) -> UIImage {
		return scale(maxResolution, orientation: self.imageOrientation)
	}
}
