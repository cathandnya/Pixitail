//
//  CHURLImageView.m
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHURLImageView.h"
//#import "CHMatrixView.h"
#import "ImageDiskCache.h"


static CGRect maxCenter(CGSize s, CGRect ir) {
    CGRect result;
    if(ir.size.height/ir.size.width>s.height/s.width){
        result.size.width=ir.size.width;
        result.size.height=s.height*ir.size.width/s.width;
        result.origin.x=ir.origin.x;
        result.origin.y=ir.origin.y+(ir.size.height-result.size.height)/2;
    }else{
        result.size.height=ir.size.height;
        result.size.width=s.width*ir.size.height/s.height;
        result.origin.y=ir.origin.y;
        result.origin.x=ir.origin.x+(ir.size.width-result.size.width)/2;
    }
    return result;
}


@implementation CHURLImageView

@synthesize urlString;
@synthesize referer;
@synthesize object;
@synthesize imagePosition;
@synthesize cache;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (void) dealloc {
	//[self cancelLoadImageData];
	//[self cancelLoad];
	
	[urlString release];
	[referer release];
	[object release];
	self.image = nil;
	
	[super dealloc];
}


- (void) adjustSize:(CGSize)size {
	//if (![[self superview] isKindOfClass:[CHMatrixView class]]) {
		CGRect	newRect = self.frame;
		CGFloat	delta = newRect.size.height - size.height;
		
		newRect.origin.y -= delta;
		newRect.size.height = size.height;
		[self setFrame:newRect];
		
		for (UIView *view in [[self superview] subviews]) {
			if (view != self) {
				newRect = view.frame;
				newRect.origin.y -= delta;
				[view setFrame:newRect];
			}
		}
	//}
}


- (void) urlLoadCompleted:(NSNotification *)notif {
	if ([[[notif userInfo] objectForKey:@"URLString"] isKindOfClass:[NSNull class]]) {
		// 失敗
		UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self viewWithTag:100];
		if (indicator) {
			//[indicator stopAnimating];
			[indicator removeFromSuperview];
		}
		
		UIImage		*img = [UIImage imageNamed:@"load_failed.png"];
		UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
		CGRect	rect = [imgView frame];
		rect.origin.x = ([self frame].size.width - rect.size.width) / 2;
		rect.origin.y = ([self frame].size.height - rect.size.height) / 2;
		[imgView setFrame:rect];
		[imgView setTag:200];
		[self addSubview:imgView];
		[imgView release];
		
	} else {
		[self performSelectorOnMainThread:@selector(loadImageData) withObject:nil waitUntilDone:NO];
	}
}

- (void) clear {
	self.image = nil;
}

- (void) cancel {
	if (imageConnection_) {
		[imageConnection_ cancel];
		[imageConnection_ release];
		imageConnection_ = nil;
		[imageData_ release];
		imageData_ = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
}


- (void) loadImageData {
	if (cache) {
		NSData *img = [cache imageDataForKey:[object objectForKey:@"IllustID"]];
		if (img) {
			//needsWhiteBack_ = [cache isGifPng:[object objectForKey:@"IllustID"]];

			[self setLoadedImage:img];
			return;
		}
	}

	NSMutableURLRequest			*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[self.urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	//assert(imageConnection_ == nil);
	
	[self cancel];
	
	if (self.referer) {
		[req setValue:self.referer forHTTPHeaderField:@"Referer"];
	}
	imageConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	imageData_ = [[NSMutableData alloc] init];
	[req release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[imageConnection_ start];

	// 表示
	if (![self viewWithTag:100]) {
		/*
		UIActivityIndicatorView	*indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		
		CGRect	rect = [indicator frame];
		rect.origin.x = ([self frame].size.width - rect.size.width) / 2;
		rect.origin.y = ([self frame].size.height - rect.size.height) / 2;
		[indicator setFrame:rect];
		[indicator setTag:100];
		[self addSubview:indicator];
		[indicator startAnimating];
		[indicator release];
		*/
		
		UIProgressView			*progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		progress.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

		CGRect	rect = [progress frame];
		rect.size.width = [self frame].size.width * 2.0 / 3.0;
		rect.origin.x = ([self frame].size.width - rect.size.width) / 2;
		rect.origin.y = ([self frame].size.height - rect.size.height) / 2;

		[progress setFrame:rect];
		[progress setTag:100];
		progress.progress = 0.0;
		//progress.alpha = 0.8;
		[self addSubview:progress];
		[progress release];		
	}
}

- (void) cancelLoadImageData {
	if (imageConnection_) {
		[imageConnection_ cancel];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
	[imageConnection_ release];
	imageConnection_ = nil;
	
	[imageData_ release];
	imageData_ = nil;
}

- (void) setLoadedImage:(NSData *)img {
	if (self.imagePosition == CHURLImageViewImagePosition_Fill) {
		self.contentMode = UIViewContentModeScaleAspectFill;
	} else if (self.imagePosition == CHURLImageViewImagePosition_MaxCenter) {
		self.contentMode = UIViewContentModeScaleAspectFit;
	}
	
	//[self setImageData:img];
	self.image = [UIImage imageWithData:img];
	return;
	
	/*
			CGRect		ir, fr;
			CGImageRef	cgimg;
			UIImage		*newImage = nil;
			
			if (self.imagePosition == CHURLImageViewImagePosition_Fill) {
				// trim
				ir.size = self.frame.size;
				ir.origin = CGPointZero;
				if (img.size.width > img.size.height) {
					fr.size.width = img.size.height;
					fr.size.height = img.size.height;
					fr.origin.x = (img.size.width - img.size.height) / 2.0;
					fr.origin.y = 0;
				} else {
					fr.size.width = img.size.width;
					fr.size.height = img.size.width;
					fr.origin.x = 0;
					fr.origin.y = (img.size.height - img.size.width) / 2.0;
				}
				
				//self.contentMode = UIViewContentModeScaleAspectFit;
			} else if (self.imagePosition == CHURLImageViewImagePosition_MaxCenter) {
				ir.size = self.frame.size;
				ir.origin = CGPointZero;
				ir = maxCenter([img size], ir);
				fr.origin = CGPointZero;
				fr.size = [img size];

				//self.contentMode = UIViewContentModeScaleAspectFit;
			}
			self.clipsToBounds = YES;
	
			cgimg = CGImageCreateWithImageInRect(img.CGImage, fr);
			
			UIGraphicsBeginImageContext(CGSizeMake(self.frame.size.width * 2, self.frame.size.height * 2));
			
			if (needsWhiteBack_) {
				[[UIColor whiteColor] set];
				UIRectFill(ir);
			}
			
			// 反転
			CGAffineTransform a_tr = CGAffineTransformIdentity;
			a_tr.d = -1.0f;
			a_tr.ty = self.frame.size.height;
			CGContextConcatCTM(UIGraphicsGetCurrentContext(), a_tr);

			ir.size.width *= 2;
			ir.size.height *= 2;
			
			CGContextDrawImage(UIGraphicsGetCurrentContext(), ir, cgimg);
			NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
			newImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
			[pool release];

			UIGraphicsEndImageContext();			
			
			CFRelease(cgimg);
			
			[self setImage:newImage forState:UIControlStateNormal];
			[self setNeedsDisplay];
			[newImage release];
	*/
}

- (void) loaded:(NSData *)data {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

	UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self viewWithTag:100];
	if (indicator) {
		//[indicator stopAnimating];
		[indicator removeFromSuperview];
	}
				
	if (data && [object objectForKey:@"IllustID"]) {
		//UIImage	*img = [[UIImage alloc] initWithData:data];
		//if (img) {						
			// cache
			[cache setImageData:data forKey:[object objectForKey:@"IllustID"]];
			//needsWhiteBack_ = [cache isGifPng:[object objectForKey:@"IllustID"]];

			[self setLoadedImage:data];
			
			//[img release];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"CHURLImageViewLoadedNotification" object:self];
		//}	
	}
	
	[imageConnection_ release];
	imageConnection_ = nil;
	[imageData_ release];
	imageData_ = nil;

	if (!self.image) {
		// 失敗
		UIImage		*img = [UIImage imageNamed:@"load_failed.png"];
		UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
		CGRect	rect = [imgView frame];
		rect.origin.x = ([self frame].size.width - rect.size.width) / 2;
		rect.origin.y = ([self frame].size.height - rect.size.height) / 2;
		[imgView setFrame:rect];
		[imgView setTag:200];
		[self addSubview:imgView];
		[imgView release];
	}	
}


- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
	imageDataLength_ = [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[imageData_ appendData:data];
	
	UIProgressView	*view = (UIProgressView *)[self viewWithTag:100];
	if (view) {
		view.progress = (double)[imageData_ length] / (double)imageDataLength_;
	}
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	//[self performSelectorOnMainThread:@selector(loaded:) withObject:nil waitUntilDone:NO];
	[self loaded:nil];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	//[self performSelectorOnMainThread:@selector(loaded:) withObject:imageData_ waitUntilDone:NO];
	[self loaded:imageData_];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}


- (void) setUrlString:(NSString *)str {
	if (str != urlString) {
		[urlString release];
		urlString = [str retain];
		
		if (urlString) {
			[self loadImageData];
			return;
		}
	}

	if (cache) {
		UIImage *img = [cache imageForKey:[object objectForKey:@"IllustID"]];
		if (img) {
			[self loadImageData];
		}
	}
}

@end
