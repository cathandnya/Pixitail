//
//  PixivUgoIllust.m
//  pixiViewer
//
//  Created by nya on 2014/06/30.
//
//

#import "PixivUgoIllust.h"
#import "UnzipFile.h"
//#import "UIImage+animatedGIF.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>


static UIImage *scaleAndRotatedImage(UIImage *image, NSInteger kMaxResolution) {
	CGImageRef imgRef = image.CGImage;
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > kMaxResolution || height > kMaxResolution) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = kMaxResolution;
			bounds.size.height = bounds.size.width / ratio;
		} else {
			bounds.size.height = kMaxResolution;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) {
		case UIImageOrientationUp:
			transform = CGAffineTransformIdentity;
			break;
		case UIImageOrientationUpMirrored:
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
		case UIImageOrientationDown:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
		case UIImageOrientationLeftMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationLeft:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationRightMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		case UIImageOrientationRight:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	} else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	CGContextRestoreGState(context);
	UIGraphicsEndImageContext();
	
	return imageCopy;
}


@interface PixivUgoIllust()
//@property(strong) NSArray *images;
@property(strong) NSDictionary *info;
@property(strong) NSString *uuid;
@property(strong) UnzipFile *unzip;
@end


@implementation PixivUgoIllust

- (id) initWithInfo:(NSDictionary *)info {
	self = [super init];
	if (self) {
		CFUUIDRef ref = CFUUIDCreate(kCFAllocatorDefault);
		self.uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, ref));
		CFRelease(ref);
		
		self.info = info;
	}
	return self;
}

- (void) dealloc {
	[[NSFileManager defaultManager] removeItemAtPath:[self zipPath] error:nil];
}

- (NSData *)zipData {
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self zipPath]]) {
		return [NSData dataWithContentsOfFile:[self zipPath]];
	} else {
		return nil;
	}
}

- (NSData *)gifData:(NSInteger)maxSize {
	NSString *gifPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:self.uuid] stringByAppendingPathExtension:@"gif"];
	size_t const count = [self frameCount];
	
	[[NSFileManager defaultManager] createFileAtPath:gifPath contents:[NSData data] attributes:nil];
	CFURLRef url = CFBridgingRetain([NSURL fileURLWithPath:gifPath]);
	CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, count, NULL);
	CFRelease(url);
	
	NSMutableArray *imgs = [NSMutableArray new];
	for (int i = 0; i < count; i++) {
		@autoreleasepool {
			UIImage *img = scaleAndRotatedImage([self imageAtIndex:i], maxSize);
			NSTimeInterval time = [self delayAtIndex:i];
			
			NSDictionary *frameProperties = @{(NSString *)kCGImagePropertyGIFDictionary: @{(NSString *)kCGImagePropertyGIFDelayTime: @(time)}};
			CFDictionaryRef ref = CFBridgingRetain(frameProperties);
			CGImageDestinationAddImage(destination, img.CGImage, ref);
			CFRelease(ref);
			
			[imgs addObject:img];
		}
	}
	
	NSDictionary *gifProperties = @{(NSString *)kCGImagePropertyGIFDictionary: @{(NSString *)kCGImagePropertyGIFLoopCount: @(0)}};
	CFDictionaryRef ref = CFBridgingRetain(gifProperties);
	CGImageDestinationSetProperties(destination, ref);
	CGImageDestinationFinalize(destination);
	CFRelease(ref);
	CFRelease(destination);

	NSData *data = [NSData dataWithContentsOfFile:gifPath];
	[[NSFileManager defaultManager] removeItemAtPath:gifPath error:nil];
	return data;
}

- (NSData *)gifData {
	return [self gifData:INT_MAX];
}

- (NSData *)gifDataForTumblr {
	return [self gifData:500];
}

- (BOOL) isLoaded {
	return self.unzip != nil;
}

- (UIImage *) firstImage {
	return [self imageAtIndex:0];
}

- (NSInteger) frameCount {
	NSArray *frames = self.info[@"frames"];
	return [frames count];
}

- (NSTimeInterval) delayAtIndex:(NSInteger)i {
	NSArray *frames = self.info[@"frames"];
	NSNumber *delay = frames[i][@"delay"];
	return [delay doubleValue] / 1000.0;
}

- (UIImage *) imageAtIndex:(NSInteger)i {
	NSArray *frames = self.info[@"frames"];
	NSString *path = frames[i][@"file"];
	const char *cstr = [path cStringUsingEncoding:NSUTF8StringEncoding];
	NSData *data = [self.unzip contentWithFilename:[NSData dataWithBytesNoCopy:(void *)cstr length:strlen(cstr) freeWhenDone:NO]];
	return [UIImage imageWithData:data];
}

- (void) load {
	NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.info[@"src"]]];
	[req setValue:@"http://www.pixiv.net" forHTTPHeaderField:@"Referer"];
	
	__weak PixivUgoIllust *me = self;
	[NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		if (me) {
			if (!connectionError) {
				NSString *zipPath = [me zipPath];
				[data writeToFile:zipPath atomically:YES];
				me.unzip = [[UnzipFile alloc] initWithPath:zipPath];
				[me.delegate ugoIllustLoaded:me error:nil];
			} else {
				[me.delegate ugoIllustLoaded:me error:connectionError];
			}
		}
	}];
}

- (NSString *) zipPath {
	return [[NSTemporaryDirectory() stringByAppendingPathComponent:self.uuid] stringByAppendingPathExtension:@"zip"];
}

@end


@interface PixivUgoIllustPlayer()
@property(weak) NSTimer *timer;
@property(assign) NSInteger currentIndex;
@end

@implementation PixivUgoIllustPlayer

- (id) initWithUgoIllust:(PixivUgoIllust *)ui {
	self = [super init];
	if (self) {
		self.ugoIllust = ui;
		self.repeat = YES;
	}
	return self;
}

#pragma mark-

- (BOOL) isPlaying {
	return self.timer != nil;
}

- (void) play {
	[self stop];
	
	self.currentIndex = 0;
	[self next];
}

- (void) stop {
	[self.timer invalidate];
	self.timer = nil;
}

- (void) next {
	[self.delegate frameChanged:self image:[self.ugoIllust imageAtIndex:self.currentIndex]];
	self.timer = [NSTimer scheduledTimerWithTimeInterval:[self.ugoIllust delayAtIndex:self.currentIndex] target:self selector:@selector(timerAction:) userInfo:nil repeats:NO];
}

- (void) timerAction:(NSTimer *)timer {
	self.timer = nil;
	
	self.currentIndex++;
	if (self.currentIndex >= [self.ugoIllust frameCount]) {
		if (self.repeat) {
			self.currentIndex = 0;
		} else {
			[self stop];
			return;
		}
	}
	[self next];
}

@end
