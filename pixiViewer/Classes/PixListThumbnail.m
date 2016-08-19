//
//  PixListThumbnail.m
//  pixiViewer
//
//  Created by nya on 09/10/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixListThumbnail.h"
#import "AccountManager.h"


@implementation PixListThumbnail

static NSString *nameFromMethod(NSString *method) {
	return [method stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

- (NSString *) path:(NSString *)method {
	NSArray		*paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString	*documentsDirectory = [paths objectAtIndex:0];
	NSString	*dirPath = name ? [documentsDirectory stringByAppendingPathComponent:name] : documentsDirectory;
	if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath] == NO) {
		BOOL b = [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
		if (!b) {
			return nil;
		}
	}
	return [[dirPath stringByAppendingPathComponent:nameFromMethod(method)] stringByAppendingPathExtension:@"png"];
}

- (UIImage *) loadImage:(NSString *)method {
	NSString	*path = [self path:method];
	if (path == nil) {
		return nil;
	}
	
	NSData		*data = [NSData dataWithContentsOfFile:path];
	if (data) {
		UIImage* image = [[[UIImage alloc] initWithData:data] autorelease];
		return image;
	} else {
		return nil;
	}
}

- (void) thumbnailImageChanged:(NSNotification *)notif {
	UIImage		*img = [[notif userInfo] objectForKey:@"Image"];
	NSString	*method = [[notif userInfo] objectForKey:@"Method"];
	NSString	*path = [self path:method];
	if (path == nil) {
		return;
	}
	
	// リサイズ
	CGSize newSize = CGSizeMake(80, 80);
	UIGraphicsBeginImageContext(newSize);
	[img drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	// 保存
	NSData *data = UIImagePNGRepresentation(newImage);
	[data writeToFile:path atomically:YES];
	
	// 格納
	[thumbnail_ setObject:newImage forKey:nameFromMethod(method)];
}

- (UIImage *) imageWithMethod:(NSString *)method {
	id		key = nameFromMethod(method);
	UIImage	*img = [thumbnail_ objectForKey:key];
	if (!img) {
		img = [self loadImage:method];
		if (img) {
			[thumbnail_ setObject:img forKey:key];
		}
	}
	if (!img) {
		img = [UIImage imageNamed:@"dummy.png"];
	}
	return img;
}

- (id) init {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailImageChanged:) name:@"TopImageChangedNotification" object:nil];
	}
	return self;
}

- (id) initWithAccount:(PixAccount *)acc {
	self = [super init];
	if (self) {
		name = [[NSString stringWithFormat:@"%@_%@", acc.serviceName, acc.username] retain];
	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailImageChanged:) name:@"TopImageChangedNotification" object:acc];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[thumbnail_ release];
	[name release];
	
	[super dealloc];
}

+ (PixListThumbnail *) sharedInstance {
	static PixListThumbnail *obj = nil;
	if (obj == nil) {
		obj = [[PixListThumbnail alloc] init];
	}
	return obj;
}

@end
