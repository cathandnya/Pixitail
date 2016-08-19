//
//  PostQueue.m
//
//  Created by nya on 10/09/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PostQueue.h"
#import "Reachability.h"


@implementation PostQueueItem

@synthesize target, postAction, cancelAction, object, delegate;
@dynamic info;

- (id) initWithInfo:(NSDictionary *)dic {
	self = [super init];
	if (self) {
		self.object = [dic objectForKey:@"Object"];
		self.target = [NSClassFromString([dic objectForKey:@"Target"]) sharedInstance];
		self.postAction = NSSelectorFromString([dic objectForKey:@"PostAction"]);
		self.cancelAction = NSSelectorFromString([dic objectForKey:@"CancelAction"]);
	}
	return self;
}

- (void) dealloc {
	self.object = nil;
	[super dealloc];
}

- (NSDictionary *) info {
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setObject:object forKey:@"Object"];
	[dic setObject:NSStringFromClass([target class]) forKey:@"Target"];
	[dic setObject:NSStringFromSelector(postAction) forKey:@"PostAction"];
	[dic setObject:NSStringFromSelector(cancelAction) forKey:@"CancelAction"];
	
	return dic;
}

- (long) post {
	return (long)[target performSelector:postAction withObject:object withObject:delegate];
}

- (void) cancel {
	[target performSelector:cancelAction];
}

@end



@implementation PostQueue

static PostQueue *__static_post_queue = nil;
static PostQueue *__static_evernote_queue = nil;
static PostQueue *__static_dropbox_queue = nil;
static PostQueue *__static_sugarsync_queue = nil;
static PostQueue *__static_googledrive_queue = nil;
static PostQueue *__static_skydrive_queue = nil;
static PostQueue *__static_pogoplug_queue = nil;

+ (PostQueue *) sharedInstance {
	if (__static_post_queue == nil) {
		__static_post_queue = [[PostQueue alloc] initWithName:@"PostQueue"];
	}
	return __static_post_queue;
}

+ (void) clean {
	[__static_post_queue release];
	__static_post_queue = nil;
}

+ (PostQueue *) evernoteQueue {
	if (__static_evernote_queue == nil) {
		__static_evernote_queue = [[PostQueue alloc] initWithName:@"EvernoteQueue"];
	}
	return __static_evernote_queue;
}

+ (void) cleanEvernote {
	[__static_evernote_queue release];
	__static_evernote_queue = nil;
}

+ (PostQueue *) dropboxQueue {
	if (__static_dropbox_queue == nil) {
		__static_dropbox_queue = [[PostQueue alloc] initWithName:@"DropboxQueue"];
	}
	return __static_dropbox_queue;
}

+ (void) cleanDropbox {
	[__static_dropbox_queue release];
	__static_dropbox_queue = nil;
}

+ (PostQueue *) sugarsyncQueue {
	if (__static_sugarsync_queue == nil) {
		__static_sugarsync_queue = [[PostQueue alloc] initWithName:@"SugarSyncQueue"];
	}
	return __static_sugarsync_queue;
}

+ (void) cleanSugarSync {
	[__static_sugarsync_queue release];
	__static_sugarsync_queue = nil;
}

+ (PostQueue *) googleDriveQueue {
	if (__static_googledrive_queue == nil) {
		__static_googledrive_queue = [[PostQueue alloc] initWithName:@"GoogleDriveQueue"];
	}
	return __static_googledrive_queue;
}

+ (void) cleanGoogleDrive {
	[__static_googledrive_queue release];
	__static_googledrive_queue = nil;
}

+ (PostQueue *) skyDriveQueue {
	if (__static_skydrive_queue == nil) {
		__static_skydrive_queue = [[PostQueue alloc] initWithName:@"SkyQueue"];
	}
	return __static_skydrive_queue;
}

+ (void) cleanSkyDrive {
	[__static_skydrive_queue release];
	__static_skydrive_queue = nil;
}

+ (PostQueue *) pogoplugQueue {
	if (__static_pogoplug_queue == nil) {
		__static_pogoplug_queue = [[PostQueue alloc] initWithName:@"PogoplugQueue"];
	}
	return __static_pogoplug_queue;
}

+ (void) cleanPogoplug {
	[__static_pogoplug_queue release];
	__static_pogoplug_queue = nil;
}

- (id) initWithName:(NSString *)name {
	self = [super init];
	if (self) {
		reachability = [[Reachability reachabilityForInternetConnection] retain];
		reachable = (reachability.currentReachabilityStatus != NotReachable);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:reachability];
		[reachability startNotifer];
		
		queueName = [name retain];
		queue = [[NSMutableArray alloc] init];
		active = NO;
		
		NSArray *ary = [[NSUserDefaults standardUserDefaults] objectForKey:queueName];
		for (NSDictionary *dic in ary) {
			PostQueueItem *item = [[[PostQueueItem alloc] initWithInfo:dic] autorelease];
			item.delegate = self;
			
			[queue addObject:item];
		}
		
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:queueName];
		[[NSUserDefaults standardUserDefaults] synchronize];

		[self performSelector:@selector(next)];
	}
	return self;
}

- (void) dealloc {
	[reachability stopNotifer];
	[reachability release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	NSMutableArray *ary = [NSMutableArray array];
	for (PostQueueItem *item in queue) {
		[item cancel];
		[ary addObject:item.info];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:queueName];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[queue release];
	[queueName release];
	[super dealloc];
}

#pragma mark-

- (void) next {
	if (active) {
		return;
	}
	if (reachable == NO) {
		return;
	}
	
	if ([queue count] > 0) {
		PostQueueItem *item = [queue objectAtIndex:0];
		
		active = YES;
		long err = [item post];
		if (err) {
			active = NO;
			[self performSelector:@selector(next) withObject:nil afterDelay:1.0];
		}
	}
}

- (void) reachabilityChanged:(NSNotification *)notif {
	reachable = (reachability.currentReachabilityStatus != NotReachable);
	[self next];
}

- (void) pushObject:(NSDictionary *)info toTarget:(id)target action:(SEL)action cancelAction:(SEL)cancel {
	PostQueueItem *item = [[[PostQueueItem alloc] init] autorelease];
	item.object = info;
	item.target = target;
	item.postAction = action;
	item.delegate = self;
	item.cancelAction = cancel;
	
	[queue addObject:item];
	[self next];
}

- (void) post:(id)sender finished:(long)err {
	active = NO;
	if (queue.count == 0) {
		return;
	}

	PostQueueItem *item = [queue objectAtIndex:0];
	if (item.target != sender) {
		assert(0);
		//[self next];
		[self performSelector:@selector(next) withObject:nil afterDelay:0.2];
		return;
	}
	
	if (err != 0) {
		[self performSelector:@selector(next) withObject:nil afterDelay:1.0];
	} else {
		NSMutableDictionary *info = [[item.object mutableCopy] autorelease];
		[info setObject:item.target forKey:@"Target"];
		[info setObject:NSStringFromClass([item.target class]) forKey:@"TargetClassName"];
		[info setObject:NSStringFromSelector(item.postAction) forKey:@"PostActionName"];
		
		[queue removeObjectAtIndex:0];
		
		if ([[info objectForKey:@"TargetClassName"] isEqual:@"Tumblr"]) {
			if ([[info objectForKey:@"PostActionName"] isEqual:@"reblogAPI:handler:"]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrReblogFinished" object:[info objectForKey:@"Target"] userInfo:info];
			} else if ([[info objectForKey:@"PostActionName"] isEqual:@"likeAPI:handler:"]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrLikeFinished" object:[info objectForKey:@"Target"] userInfo:info];
			} else if ([[info objectForKey:@"PostActionName"] isEqual:@"follow:handler:"]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrFollowFinished" object:[info objectForKey:@"Target"] userInfo:info];
			}
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"PostQueueFinishedNotification" object:self userInfo:info];
		}
		
		//[self next];
		[self performSelector:@selector(next) withObject:nil afterDelay:0.2];
	}
}

- (BOOL) isActive:(id)target action:(SEL)action withObjectKey:(id)key value:(id)val {
	for (PostQueueItem *item in queue) {
		if (target == item.target && action == item.postAction) {
			if ([[item.object objectForKey:key] isEqual:val]) {
				return YES;
			}
		}
	}
	return NO;
}

- (PostQueueItem *) currentItem {
	return [queue objectAtIndex:0];
}

@end
