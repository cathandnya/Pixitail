//
//  EvernoteTumbletail.m
//  Tumbltail
//
//  Created by nya on 10/11/26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EvernoteTail.h"
#import "UserDefaults.h"
#import "AlertView.h"
#import "BigURLDownloader.h"
#import "ImageDownloader.h"
#import "StatusMessageViewController.h"
#import "EvernoteNoteStore.h"


#define CONSUMER_KEY		EVERNOTE_CONSUMER_KEY
#define CONSUMER_SECRET		EVERNOTE_CONSUMER_SECRET
#define NOTE_NAME			EVERNOTE_NOTE_NAME


@implementation EvernoteTail

+ (EvernoteTail *) sharedInstance {
	static EvernoteTail *obj = nil;
	if (obj == nil) {
		obj = [[EvernoteTail alloc] initWithConsumerKey:CONSUMER_KEY andSecret:CONSUMER_SECRET];
	}
	return obj;
}

#pragma mark-

- (void) uploadFinished:(NSError *)err {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Evernote.", nil) message:[err localizedDescription] delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.tag = 200;
		alert.object = uploadingInfo;
		[alert show];
	} else {
		if ([uploadingInfo objectForKey:@"Path"] && [[NSFileManager defaultManager] fileExistsAtPath:[uploadingInfo objectForKey:@"Path"]]) {
			[[NSFileManager defaultManager] removeItemAtPath:[uploadingInfo objectForKey:@"Path"] error:nil];
		}
		[[StatusMessageViewController sharedInstance] showMessage:@"Evernoteへ保存しました"];
	}
	[uploadingInfo release];
	uploadingInfo = nil;
	[uploadHandler post:self finished:0];
	uploadHandler = nil;
}

- (void) uploadFinished {
	[self uploadFinished:0];
}

- (long) upload:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if (self.logined == NO) {
		[self performSelector:@selector(uploadFinished) withObject:nil afterDelay:0.1];
		return 0;
	}

	NSString *imgPath = [info objectForKey:@"Path"];
	//DLog(@"upload: %@", imgPath);
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
			//DLog(@" -> download image");
		} else {
			urlDownloader = [[BigURLDownloader alloc] init];
			urlDownloader.parserClassName = [info objectForKey:@"ParserClass"];
			urlDownloader.bigSourceURL = [info objectForKey:@"SourceURL"];
			urlDownloader.referer = [info objectForKey:@"Referer"];
			urlDownloader.object = info;
			urlDownloader.delegate = self;
			urlDownloadHandler = obj;
		
			[urlDownloader download];
			//DLog(@" -> download url");
		}
		return 0;
	}
	//DLog(@" -> upload");
	
	[uploadingInfo release];
	uploadingInfo = [info retain];
	uploadHandler = obj;
	
	
	void (^failure)(NSError *error) = ^(NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
		[self uploadFinished:error];
	};
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	[self.noteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
		EDAMNotebook *nb = nil;
		for (nb in notebooks) {
			if ([nb.name isEqualToString:NOTE_NAME]) {
				break;
			}
		}
		
		void (^createNoteFinished)(EDAMNotebook *notebook) = ^(EDAMNotebook *notebook) {
			NSData *data = [NSData dataWithContentsOfFile:[info objectForKey:@"Path"]];
			EDAMNote *note = [self noteWithTitle:[info objectForKey:@"Title"] andImage:data size:[info objectForKey:@"Size"] ? CGSizeFromString([info objectForKey:@"Size"]) : CGSizeZero forNotebook:notebook];
			
#ifdef PIXITAIL
			NSString *appName = @"Pixitail";
#else
			NSString *appName = @"Illustail";
#endif
			
			EDAMNoteAttributes *attr = [[[EDAMNoteAttributes alloc] initWithSubjectDate:0 latitude:0 longitude:0 altitude:0 author:[info objectForKey:@"Username"] source:[info objectForKey:@"ServiceName"] sourceURL:[info objectForKey:@"URL"] sourceApplication:appName shareDate:[[NSDate date] timeIntervalSince1970] placeName:nil contentClass:nil applicationData:nil lastEditedBy:nil] autorelease];
			note.attributes = attr;
			
			BOOL enableTags = YES;
			if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SaveTags"]) {
				enableTags = [[NSUserDefaults standardUserDefaults] boolForKey:@"SaveTags"];
			}
			if (enableTags && [[info objectForKey:@"Tags"] count] > 0) {
				note.tagNames = [info objectForKey:@"Tags"];
			}

			[self.noteStore createNote:note success:^(EDAMNote *note) {
				// 成功
				[self.noteStore stopSharingNoteWithGuid:note.guid success:^{
					[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
					[self uploadFinished:nil];
				} failure:failure];
			} failure:failure];
		};
		if (nb == nil) {
			nb = [[[EDAMNotebook alloc] init] autorelease];
			nb.name = NOTE_NAME;
			[self.noteStore createNotebook:nb success:createNoteFinished failure:failure];
		} else {
			createNoteFinished(nb);
		}
	} failure:failure];
	return 0;
}

- (void) uploadCancel {
}

- (void) upload:(NSDictionary *)info {
	[[PostQueue evernoteQueue] pushObject:info toTarget:self action:@selector(upload:handler:) cancelAction:@selector(uploadCancel)];
}

#pragma mark-

- (void) bigURLDownloader:(BigURLDownloader *)sender finished:(NSError *)err {
	[urlDownloader autorelease];
	urlDownloader = nil;

	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Evernote.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.tag = 200;
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
				NSString *n = [info objectForKey:@"Title"];
				n = [n stringByAppendingFormat:@"_%03d", i + 1];
				[info setObject:n forKey:@"Title"];
			}
			i++;
	
			[[PostQueue evernoteQueue] pushObject:info toTarget:self action:@selector(upload:handler:) cancelAction:@selector(uploadCancel)];
		}
		[urlDownloadHandler post:self finished:0];
	}	
	urlDownloadHandler = nil;
}

- (void) imageDownloader:(ImageDownloader *)sender finished:(NSError *)err {
	[imageDownloader autorelease];
	imageDownloader = nil;

	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Evernote.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.tag = 200;
		alert.object = sender.object;
		[alert show];

		[imageDownloadHandler post:self finished:0];
	} else {
		[self upload:sender.object handler:imageDownloadHandler];
	}	
	imageDownloadHandler = nil;
}

#pragma mark-

- (void)alertView:(AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		if (alertView.tag == 200) {
			[self upload:alertView.object];
		}
	} else {
		if (alertView.tag == 200) {
			NSString *path = [(NSDictionary *)alertView.object objectForKey:@"Path"];
			if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
				[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
			}
		}
	}
}

@end
