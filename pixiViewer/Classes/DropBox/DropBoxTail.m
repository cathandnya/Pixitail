//
//  DropBoxTail.m
//  Tumbltail
//
//  Created by nya on 10/11/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DropBoxTail.h"
#import "UserDefaults.h"
#import "AlertView.h"
#import "PixiViewerAppDelegate.h"
#import "BigURLDownloader.h"
#import "ImageDownloader.h"
#import "StatusMessageViewController.h"
#import "DropboxCustom.h"


@implementation DropBoxTail

+ (DropBoxTail *) sharedInstance {
	static DropBoxTail *obj = nil;
	if (obj == nil) {
		obj = [[DropBoxTail alloc] init];
		[SessionDelegate sharedInstance];
	}
	return obj;
}

#pragma mark-

- (NSString *) photosPath {
#ifdef PIXITAIL
	return @"/Photos/Pixitail";
#else
	return @"/Photos/Illustail";
#endif
}

- (void) uploadFinished:(id)obj {
	[obj post:self finished:0];

	if ([uploadingInfo objectForKey:@"Path"] && [[NSFileManager defaultManager] fileExistsAtPath:[uploadingInfo objectForKey:@"Path"]]) {
		[[NSFileManager defaultManager] removeItemAtPath:[uploadingInfo objectForKey:@"Path"] error:nil];
	}

	[uploadingInfo release];
	uploadingInfo = nil;
}

- (long) uploadPhoto:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if (![[DBSession sharedSession] isLinked]) {
		[self performSelector:@selector(uploadFinished:) withObject:obj afterDelay:0.1];
		return 0;
	}
	
	NSString *imgPath = [info objectForKey:@"Path"];
	DLog(@"upload: %@", imgPath);
	if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath] == NO) {
		NSString *imgURL = [info objectForKey:@"ImageURL"];
		if (imgURL) {
			imageDownloader = [[ImageDownloader alloc] init];
			imageDownloader.url = imgURL;
			imageDownloader.savePath = imgPath;
			imageDownloader.referer = [info objectForKey:@"Referer"];
			imageDownloader.object = info;
			imageDownloader.delegate = self;
			imageDownloadHandler = obj;
		
			[imageDownloader download];			
			DLog(@" -> download image");
		} else {
			urlDownloader = [[BigURLDownloader alloc] init];
			urlDownloader.parserClassName = [info objectForKey:@"ParserClass"];
			urlDownloader.bigSourceURL = [info objectForKey:@"SourceURL"];
			urlDownloader.referer = [info objectForKey:@"Referer"];
			urlDownloader.object = info;
			urlDownloader.delegate = self;
			urlDownloadHandler = obj;
		
			[urlDownloader download];
			DLog(@" -> download url");
		}
		return 0;
	}
	DLog(@" -> upload");

	[uploadingInfo release];
	uploadingInfo = [info retain];

	static const char pngBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
	NSData *png = [NSData dataWithBytes:pngBytes length:8];
	static const char gifBytes[3] = {0x47, 0x49, 0x46};
	NSData *gif = [NSData dataWithBytes:gifBytes length:3];

	NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:[info objectForKey:@"Path"]];
	NSData *data = [fh readDataOfLength:8];
	
	NSString *ext = nil;
	if ([[data subdataWithRange:NSMakeRange(0, 8)] isEqualToData:png]) {
		ext = @"png";
	} else if ([[data subdataWithRange:NSMakeRange(0, 3)] isEqualToData:gif]) {
		ext = @"gif";
	} else {
		ext = @"jpg";
	}

	BOOL enableFolder = YES;
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SaveFolder"]) {
		enableFolder = [[NSUserDefaults standardUserDefaults] boolForKey:@"SaveFolder"];
	}
	
	NSString *name = [info objectForKey:@"Name"];
	NSString *replacement = ESCAPE_CHARS;
	for (int i = 0; i < replacement.length; i++) {
		NSString *s = [replacement substringWithRange:NSMakeRange(i, 1)];
		name = [name stringByReplacingOccurrencesOfString:s withString:@"#"];
	}
	NSString *path = [self photosPath];
#ifndef PIXITAIL
	if ([info objectForKey:@"ServiceName"]) {
		path = [path stringByAppendingPathComponent:[info objectForKey:@"ServiceName"]];
	}
#endif
	if ([info objectForKey:@"Username"]) {
		NSString *uname = [info objectForKey:@"Username"];
		NSString *replacement = ESCAPE_CHARS;
		for (int i = 0; i < replacement.length; i++) {
			NSString *s = [replacement substringWithRange:NSMakeRange(i, 1)];
			uname = [uname stringByReplacingOccurrencesOfString:s withString:@"#"];
		}

		if (enableFolder) {
			path = [path stringByAppendingPathComponent:uname];
		} else {
			name = [uname stringByAppendingFormat:@"_%@", name];
		}
	} else {
		//path = [path stringByAppendingPathComponent:@"Unknown"];
	}
	
	if ([info objectForKey:@"Directory"]) {
		if (enableFolder) {
			path = [path stringByAppendingPathComponent:[info objectForKey:@"Directory"]];
		}
	}
	
	[self upload:[NSDictionary dictionaryWithObjectsAndKeys:
		[info objectForKey:@"Path"],			@"LocalPath",
		path,									@"ServerPath",
		[name stringByAppendingPathExtension:ext],	@"Name",
		nil] handler:obj];
	return 0;
}

- (void) upload:(NSDictionary *)info {
	[[PostQueue dropboxQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
}

- (void) uploadCancel {
	[urlDownloader cancel];
	[urlDownloader release];
	urlDownloader = nil;
	
	[super uploadCancel];
}

- (NSString *) consumerKey {
	return DROPBOX_CONSUMER_KEY;
}

- (NSString *) consumerSecret {
	return DROPBOX_CONSUMER_SECRET;
}

- (UIViewController *) currentViewController {
	PixiViewerAppDelegate *appDelegate = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
	UIViewController *vc = [appDelegate.viewControllers lastObject];
	while (vc.modalViewController) {
		vc = vc.modalViewController;
	}
	return vc;
}

#pragma mark-

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
	DLog(@"Dropbox uploaded: %@", [destPath lastPathComponent]);
	[super restClient:client uploadedFile:destPath from:srcPath metadata:metadata];
	
	if ([uploadingInfo objectForKey:@"Path"] && [[NSFileManager defaultManager] fileExistsAtPath:[uploadingInfo objectForKey:@"Path"]]) {
		[[NSFileManager defaultManager] removeItemAtPath:[uploadingInfo objectForKey:@"Path"] error:nil];
	} else {
		assert(0);
	}
	
	[uploadingInfo release];
	uploadingInfo = nil;

	[[StatusMessageViewController sharedInstance] showMessage:@"Dropboxへ保存しました"];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath {

}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	if (error) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Dropbox.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = uploadingInfo;
		[alert show];
	} else {
		if ([uploadingInfo objectForKey:@"Path"] && [[NSFileManager defaultManager] fileExistsAtPath:[uploadingInfo objectForKey:@"Path"]]) {
			[[NSFileManager defaultManager] removeItemAtPath:[uploadingInfo objectForKey:@"Path"] error:nil];
		}
	}
	[uploadingInfo release];
	uploadingInfo = nil;
	[uploadHandler post:self finished:0];
	uploadHandler = nil;
}

#pragma mark-

- (void) bigURLDownloader:(BigURLDownloader *)sender finished:(NSError *)err {
	[urlDownloader autorelease];
	urlDownloader = nil;

	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Dropbox.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = sender.object;
		[alert show];

		[urlDownloadHandler post:self finished:0];
	} else {
		int i = 0;
		for (NSString *url in sender.imageURLs) {
			NSMutableDictionary *info = [[sender.object mutableCopy] autorelease];
			[info setObject:url forKey:@"ImageURL"];
			if (i > 0) {
				NSString *p = [info objectForKey:@"Path"];
				p = [p stringByAppendingFormat:@"_%d", i];
				[info setObject:p forKey:@"Path"];
			}
			if (sender.imageURLs.count > 1) {
				NSString *n = [info objectForKey:@"Name"];

				[info setObject:[[n copy] autorelease] forKey:@"Directory"];

				n = [n stringByAppendingFormat:@"_%03d", i + 1];
				[info setObject:n forKey:@"Name"];				
			}
			i++;
			
			[[PostQueue dropboxQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
		}
		[urlDownloadHandler post:self finished:0];
	}	
	urlDownloadHandler = nil;
}

- (void) imageDownloader:(ImageDownloader *)sender finished:(NSError *)err {
	NSDictionary *info = [[sender.object retain] autorelease];
	[imageDownloader autorelease];
	imageDownloader = nil;

	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Dropbox.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = info;
		[alert show];

		[imageDownloadHandler post:self finished:0];
	} else {
		[self uploadPhoto:info handler:imageDownloadHandler];
	}	
	imageDownloadHandler = nil;
}

#pragma mark-

- (void)alertView:(AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *path = [[[(NSDictionary *)alertView.object objectForKey:@"Path"] retain] autorelease];

	if (buttonIndex == 1) {
		[self upload:alertView.object];
	} else {
		if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
		}
	}
}

@end
