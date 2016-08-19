//
//  CameraRoll.m
//  pixiViewer
//
//  Created by nya on 11/01/19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CameraRoll.h"
#import "BigURLDownloader.h"
#import "ImageDownloader.h"
#import "AlertView.h"
#import "StatusMessageViewController.h"


@implementation CameraRoll

+ (CameraRoll *) sharedInstance {
	static CameraRoll *obj = nil;
	if (obj == nil) {
		obj = [[CameraRoll alloc] init];
	}
	return obj;
}

- (void) dealloc {
	[saveInfo release];
	[super dealloc];
}

- (void) fin:(long)err {	
	NSString *imgPath = [saveInfo objectForKey:@"Path"];
	if (imgPath && [[NSFileManager defaultManager] fileExistsAtPath:imgPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:imgPath error:nil];
	}

	[postHandler post:self finished:err];
}

- (long) save:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	postHandler = obj;
	
	if (saveInfo != info) {
		[saveInfo release];
		saveInfo = [info retain];
	}

	NSString *imgPath = [info objectForKey:@"Path"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath] == NO) {
		NSString *imgURL = [info objectForKey:@"ImageURL"];
		if (imgURL) {
			imageDownloader = [[ImageDownloader alloc] init];
			imageDownloader.url = imgURL;
			imageDownloader.savePath = imgPath;
			imageDownloader.referer = [info objectForKey:@"Referer"];
			imageDownloader.object = info;
			imageDownloader.delegate = self;
		
			[imageDownloader download];			
		} else {
			urlDownloader = [[BigURLDownloader alloc] init];
			urlDownloader.parserClassName = [info objectForKey:@"ParserClass"];
			urlDownloader.bigSourceURL = [info objectForKey:@"SourceURL"];
			urlDownloader.referer = [info objectForKey:@"Referer"];
			urlDownloader.object = info;
			urlDownloader.delegate = self;
		
			[urlDownloader download];
		}
	} else {
		UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
		if (img) {
			UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), [info retain]);
		} else {
			// どーしよ
			/*
			AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Save failed.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
			alert.object = info;
			[alert show];
			*/
			//assert(0);
			AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Save failed.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
			[alert show];

			[self fin:0];
		}
	}
	return 0;
}

- (void) image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	if (error) {
		// もうしゃーないな
		//assert(0);
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Save failed.", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
		[alert show];
	} else {
		[[StatusMessageViewController sharedInstance] showMessage:@"カメラロールへ保存しました"];
	}

	[self fin:0];
	[(id)contextInfo autorelease];
}
				 
- (void) save:(NSDictionary *)info {
	[[PostQueue sharedInstance] pushObject:info toTarget:self action:@selector(save:handler:) cancelAction:@selector(cancel)];
}

- (void) cancel {
	[imageDownloader cancel];
	[imageDownloader release];
	imageDownloader = nil;
	
	[urlDownloader cancel];
	[urlDownloader release];
	urlDownloader = nil;
}

#pragma mark-

- (void) bigURLDownloader:(BigURLDownloader *)sender finished:(NSError *)err {
	[urlDownloader autorelease];
	urlDownloader = nil;

	if (err) {
		[self fin:[err code]];
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
			i++;
	
			[[PostQueue sharedInstance] pushObject:info toTarget:self action:@selector(save:handler:) cancelAction:@selector(cancel)];
		}
		[self fin:0];
	}	
}

- (void) imageDownloader:(ImageDownloader *)sender finished:(NSError *)err {
	[imageDownloader autorelease];
	imageDownloader = nil;

	if (err) {
		[self fin:[err code]];
	} else {
		[self save:sender.object handler:postHandler];
	}	
}

#pragma mark-

- (void)alertView:(AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self save:alertView.object];
	} else {
		NSString *path = [(NSDictionary *)alertView.object objectForKey:@"Path"];
		if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
		}
	}
}

@end
