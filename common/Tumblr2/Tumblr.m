//
//  Tumblr.m
//  pixiViewer
//
//  Created by nya on 09/12/12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Tumblr.h"
#import "TumblrAccountManager.h"
#import "PostQueue.h"

#import "OAConsumer.h"
#import "Requests.h"
#import "Reachability.h"
#import "StatusMessageViewController.h"
//#import "PostCache.h"
#import "SharedAlertView.h"

#import "BigURLDownloader.h"
#import "ImageDownloader.h"
#import "AlertView.h"


#define	CONSUMER_KEY	TUMBLR_CONSUMER_KEY
#define CONSUMER_SECRET	TUMBLR_CONSUMER_SECRET


static NSString *encodeURIComponent(NSString *string) {
	NSString *newString = NSMakeCollectable([(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease]);
	if (newString) {
		return newString;
	}
	return @"";
}


@implementation Tumblr

@dynamic consumer;
@synthesize reachable;

+ (Tumblr *) sharedInstance {
	static Tumblr *obj = nil;
	if (obj == nil) {
		obj = [[Tumblr alloc] init];
	}
	return obj;
}

- (id) init {
	self = [super init];
	if (self) {
		_reachability = [[Reachability reachabilityForInternetConnection] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:kReachabilityChangedNotification object:_reachability];
		[[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:_reachability];
		[_reachability startNotifer];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reblogFinished:) name:@"ReblogRequestFinishedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceReblogFinished:) name:@"PostRequestFinishedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(likeFinished:) name:@"LikeRequestFinishedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlikeFinished:) name:@"UnlikeRequestFinishedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followFinished:) name:@"FollowRequestFinishedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unfollowFinished:) name:@"UnfollowRequestFinishedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceReblogFinished:) name:@"ForceReblogRequestFinishedNotification" object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_reachability stopNotifer];
	[_reachability release];

	[super dealloc];
}

- (void) reachabilityChanged {
	reachable = ([_reachability currentReachabilityStatus] != NotReachable);
}

- (void) reblogFinished:(NSNotification *) notif {
	Request *req = [notif object];
	NSError *err = [[notif userInfo] objectForKey:@"Error"];
	if (!err) {
		[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Reblog finished", nil)];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrReblogFinished" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[req.param objectForKey:@"id"], @"PostID", nil]];
	} else {
		[[SharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Reblog failed.", nil)];
	}
}

- (void) forceReblogFinished:(NSNotification *) notif {
	NSError *err = [[notif userInfo] objectForKey:@"Error"];
	if (!err) {
		[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Force Reblog finished", nil)];
	} else {
		[[SharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Force Reblog failed.", nil)];
	}
}

- (void) likeFinished:(NSNotification *) notif {
	Request *req = [notif object];
	NSError *err = [[notif userInfo] objectForKey:@"Error"];
	if (!err) {
		[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Like finished", nil)];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrLikeFinished" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"Unlike", [req.param objectForKey:@"id"], @"PostID", nil]];
	} else {
		[[SharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Like failed.", nil)];
	}
}

- (void) unlikeFinished:(NSNotification *) notif {
	Request *req = [notif object];
	NSError *err = [[notif userInfo] objectForKey:@"Error"];
	if (!err) {
		[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Unlike finished", nil)];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrLikeFinished" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"Unlike", [req.param objectForKey:@"id"], @"PostID", nil]];
	} else {
		[[SharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Unlike failed.", nil)];
	}
}

- (void) followFinished:(NSNotification *) notif {
	Request *req = [notif object];
	NSError *err = [[notif userInfo] objectForKey:@"Error"];
	if (!err) {
		//Tumblog *blog = [[PostCache sharedInstance] tumblogWithName:[req.param objectForKey:@"name"]];
		//blog.following = [NSNumber numberWithBool:YES];
		
		[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Follow finished", nil)];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrFollowFinished" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"Unfollow", [req.param objectForKey:@"url"], @"TumblogURL", nil]];
	} else {
		[[SharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Follow failed.", nil)];
	}
}

- (void) unfollowFinished:(NSNotification *) notif {
	Request *req = [notif object];
	NSError *err = [[notif userInfo] objectForKey:@"Error"];
	if (!err) {
		//Tumblog *blog = [[PostCache sharedInstance] tumblogWithName:[req.param objectForKey:@"name"]];
		//blog.following = [NSNumber numberWithBool:NO];

		[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Unfollow finished", nil)];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrFollowFinished" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"Unfollow", [req.param objectForKey:@"url"], @"TumblogURL", nil]];
	} else {
		[[SharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Unfollow failed.", nil)];
	}
}

- (OAConsumer *) consumer {
	return [[[OAConsumer alloc] initWithKey:CONSUMER_KEY secret:CONSUMER_SECRET] autorelease];
}

#pragma mark-

- (NSString *) errorMessage:(NSError *)err {
	return [err localizedDescription];
}

- (void) uploadFinished:(id)obj {
	[obj post:self finished:0];
}

- (void) uploadCancel {
}

- (void)alertView:(AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		NSDictionary *dic = alertView.object;
		[self upload:dic];
	}
}

#pragma mark-

- (void) uploadPhoto:(NSDictionary *)dic block:(void (^)(NSError *))completionBlock {
	void (^block)(NSError *) = (completionBlock ? Block_copy(completionBlock) : nil);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *path = [dic objectForKey:@"LocalPath"];
		NSData *data = nil;
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			data = [NSData dataWithContentsOfFile:path];
		}
		
		NSError *err = nil;
		if (data) {
			PostPhotoRequest *req = [[[PostPhotoRequest alloc] init] autorelease];
			req.dataList = @[@{@"data": data, @"filename": dic[@"Filename"], @"mime_type": dic[@"ContentType"]}];
			req.caption = [dic objectForKey:@"Caption"];
			req.tags = [dic objectForKey:@"Tags"];
			req.link = [dic objectForKey:@"Link"];
			req.type = @"photo";
			req.blogHostName = [TumblrAccountManager sharedInstance].currentAccount.primaryBlog.hostName;
			
			NSDictionary *ret = [req load];
			err = [[ret objectForKey:@"Error"] retain];
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			if (block) {
				block(err);
				Block_release(block);
			}
			[err autorelease];
		});
	});	
}

- (long) uploadPhoto:(NSDictionary *)dic handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if ([TumblrAccountManager sharedInstance].currentAccount == nil) {
		[self performSelector:@selector(uploadFinished:) withObject:obj afterDelay:0.1];
		return 0;
	}
	
	NSArray *infoList = dic[@"list"];
	if (!infoList) {
		infoList = @[dic];
	}
	
	for (int i = 0; i < infoList.count; i++) {
		NSDictionary *info = infoList[i];
		NSString *imgPath = info[@"Path"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath] == NO) {
			NSString *imgURL = info[@"ImageURL"];
			if (imgURL) {
				imageDownloader = [[ImageDownloader alloc] init];
				imageDownloader.url = imgURL;
				imageDownloader.savePath = imgPath;
				imageDownloader.referer = [info objectForKey:@"Referer"];
				imageDownloader.object = dic;
				imageDownloader.delegate = self;
				imageDownloadHandler = obj;
				
				[imageDownloader download];
				DLog(@" -> download image");
			} else {
				urlDownloader = [[BigURLDownloader alloc] init];
				urlDownloader.parserClassName = [info objectForKey:@"ParserClass"];
				urlDownloader.bigSourceURL = [info objectForKey:@"SourceURL"];
				urlDownloader.referer = [info objectForKey:@"Referer"];
				urlDownloader.object = dic;
				urlDownloader.delegate = self;
				urlDownloadHandler = obj;
				
				[urlDownloader download];
				DLog(@" -> download url");
			}
			return 0;
		}
	}
	
	[dic retain];
	[infoList retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[infoList autorelease];
		
		NSError *err = nil;
		NSMutableString *tags = [NSMutableString string];
		if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SaveTagsTumblr"] == nil || [[NSUserDefaults standardUserDefaults] boolForKey:@"SaveTagsTumblr"]) {
			NSDictionary *info = infoList.firstObject;
			for (NSString *s in [info objectForKey:@"Tags"]) {
				[tags appendString:s];
				if (s != [[info objectForKey:@"Tags"] lastObject]) {
					[tags appendString:@","];
				}
			}
		}
		
		NSMutableArray *dataList = [NSMutableArray array];
		for (NSDictionary *info in infoList) {
			[dataList addObject:@{@"filepath": info[@"Path"], @"filename": info[@"Filename"], @"mime_type": info[@"ContentType"]}];
		}
		
		PostPhotoRequest *req = [[[PostPhotoRequest alloc] init] autorelease];
		req.dataList = dataList;
		req.tags = tags;
		{
			NSDictionary *info = infoList.firstObject;
			req.caption = [info objectForKey:@"Caption"];
			req.link = [info objectForKey:@"SourceURL"];
		}
		req.type = @"photo";
		req.blogHostName = [self postingBlog].hostName;
		req.sendToTwitter = [[NSUserDefaults standardUserDefaults] boolForKey:@"TumblrTweet"];
		
		NSDictionary *ret = [req load];
		err = [[ret objectForKey:@"Error"] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
			[err autorelease];
			[dic autorelease];
			
			[self uploadFinished:obj];
			if (err) {
				NSString *msg = [self errorMessage:err];
				AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Tumblr.", nil) message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
				alert.object = dic;
				[alert show];
			} else {
				[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Sharing to Tumblr is finished.", nil)];
			}
		});
	});
	
	return 0;
}

#pragma mark-

- (void) bigURLDownloader:(BigURLDownloader *)sender finished:(NSError *)err {
	[urlDownloader autorelease];
	urlDownloader = nil;
	
	id handler = urlDownloadHandler;
	urlDownloadHandler = nil;
	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Pogoplug.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = sender.object;
		[alert show];
		
		[handler post:self finished:0];
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
			
			[[PostQueue pogoplugQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
		}
		[handler post:self finished:0];
	}
}

- (void) imageDownloader:(ImageDownloader *)sender finished:(NSError *)err {
	id info = [[sender.object retain] autorelease];
	[imageDownloader autorelease];
	imageDownloader = nil;
	
	id handler = imageDownloadHandler;
	imageDownloadHandler = nil;
	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Pogoplug.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = info;
		[alert show];
		
		[handler post:self finished:0];
	} else {
		[self uploadPhoto:info handler:handler];
	}
}

#pragma mark-

- (void) upload:(NSDictionary *)info {
	[[PostQueue skyDriveQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
}

- (Tumblog *) postingBlog {
	NSString *blogName = [[NSUserDefaults standardUserDefaults] stringForKey:@"TumblrBlogName"];
	
	for (LoginUserBlog *b in [TumblrAccountManager sharedInstance].currentAccount.blogs) {
		if ([b.name isEqualToString:blogName]) {
			return b;
		}
	}
	return [TumblrAccountManager sharedInstance].currentAccount.primaryBlog;
}

@end
