//
//  PixService.m
//  pixiViewer
//
//  Created by nya on 09/09/24.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixService.h"
#import "Reachability.h"
#import "AlertView.h"
#import "AccountManager.h"


NSString* encodeURIComponent(NSString* s) {
    return [((NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
        (CFStringRef)s,
        NULL,
        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
        kCFStringEncodingUTF8)) autorelease];
}


@implementation PixService

@synthesize username;
@synthesize password;
@synthesize logined, reachable;
@dynamic needsLogin, expireDate, hasExpireDate;

- (NSString *) hostName {
	return nil;
}

- (id) init {
	self = [super init];
	if (self) {
		logined = NO;
		illustStorage_ = [[NSMutableDictionary alloc] init];
		
		bookmarkAddingIDs = [[NSMutableArray alloc] init];
		ratingIDs = [[NSMutableArray alloc] init];
		commentingIDs = [[NSMutableArray alloc] init];

		_reachability = [[Reachability reachabilityForInternetConnection] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:kReachabilityChangedNotification object:_reachability];
		[[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:_reachability];
		[_reachability startNotifer];
	}
	return self;
}

- (void) dealloc {
	[illustStorage_ release];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_reachability stopNotifer];
	[_reachability release];
	
	[bookmarkAddingIDs release];
	[ratingIDs release];
	[commentingIDs release];

	[loginDate release];

	[super dealloc];
}

- (NSDate *) expireDate {
	NSDate *expire = nil;
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
		DLog(@"%@", [cookie description]);
		if ([cookie.domain hasSuffix:@"pixiv.net"]) {
			DLog(@"%@", [cookie description]);
			if (cookie.expiresDate) {
				if (!expire || [cookie.expiresDate timeIntervalSinceDate:expire] < 0) {
					expire = cookie.expiresDate;
				}
			}
		}
	}
	/*
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [self hostName]]]]) {
		if ([cookie.domain hasSuffix:@"pixiv.net"]) {
			DLog(@"%@", [cookie description]);
			if (cookie.expiresDate) {
				if (!expire || [cookie.expiresDate timeIntervalSinceDate:expire] < 0) {
					expire = cookie.expiresDate;
				}
			}
		}
	}
	 */
	return expire;
}

- (BOOL) hasExpireDate {
	return YES;
}

- (NSTimeInterval) loginExpiredTimeInterval {
	return 0;
}

- (BOOL) needsLogin {
	if (logined && loginDate) {
		//NSDate *expire = self.expireDate;
		return -[loginDate timeIntervalSinceNow] > [self loginExpiredTimeInterval] - 3 * 60;
		
		/*
		if (self.hasExpireDate) {
			NSDate *expire = self.expireDate;
			expire = [NSDate dateWithTimeInterval:0 sinceDate:expire];
			if (expire) {
				DLog(@"ti: %d [h]", (int)[expire timeIntervalSinceNow] / (60 * 60));
				return [expire timeIntervalSinceNow] < 60 * 5;
			} else {
				return YES;
			}
		} else {
			return YES;
		}
		 */
	} else {
		return YES;
	}
}

- (void) setLogined:(BOOL)b {
	logined = b;
	[loginDate release];
	if (logined) {
		loginDate = [[NSDate alloc] init];
	} else {
		loginDate = nil;
	}
}

- (long) login:(id<PixServiceLoginHandler>)handler {
	return -1;
}

- (long) loginCancel {
	return -1;
}

- (long) addToBookmark:(NSString *)illustID withInfo:(NSDictionary *)info handler:(id<PixServiceAddBookmarkHandler>)handler {
	return -1;
}

- (long) addToBookmarkCancel {
	if (addBookmarkConnection_) {
		[addBookmarkConnection_ cancel];
		[addBookmarkConnection_ release];
		addBookmarkConnection_ = nil;
		addBookmarkHandler_ = nil;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
	return 0;
}

- (long) removeFromBookmark:(NSString *)illustID {
	return -1;
}

- (long) rating:(NSInteger)val withInfo:(NSDictionary *)info handler:(id<PixServiceRatingHandler>)handler {
	return -1;
}

- (void) ratingCancel {
	if (ratingConnection_) {
		[ratingConnection_ cancel];
		[ratingConnection_ release];
		ratingConnection_ = nil;
		ratingHandler_ = nil;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
	return;
}

- (long) comment:(NSString *)str withInfo:(NSDictionary *)info handler:(id<PixServiceCommentHandler>)handler {
	return -1;
}

- (void) commentCancel {
	if (commentConnection_) {
		[commentConnection_ cancel];
		[commentConnection_ release];
		commentConnection_ = nil;
		commentHandler_ = nil;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
}

- (long) allertReachability {
	return -1;
}

- (void) addEntries:(NSDictionary *)info forIllustID:(NSString *)iid {
	if (!info || !iid) {
		//assert(0);
		return;
	}

@synchronized(self) {
	NSMutableDictionary		*ret;
	ret = [illustStorage_ objectForKey:iid];
	if (ret == nil) {
		ret = [[NSMutableDictionary alloc] init];
		[illustStorage_ setObject:ret forKey:iid];
		[ret autorelease];
	}
	[ret addEntriesFromDictionary:info];
	[ret setObject:iid forKey:@"IllustID"];
}
}

- (void) removeEntriesForIllustID:(NSString *)iid {
	if (!iid) {
		assert(0);
		return;
	}

@synchronized(self) {
	NSMutableDictionary		*ret;
	ret = [illustStorage_ objectForKey:iid];
	if (ret) {
		[illustStorage_ removeObjectForKey:iid];
	}
}
}

- (void) removeAllEntries {
@synchronized(self) {
	[illustStorage_ removeAllObjects];
}
}

- (NSMutableDictionary *) infoForIllustID:(NSString *)iid {
	NSMutableDictionary		*ret;
@synchronized(self) {
	ret = [illustStorage_ objectForKey:iid];
}
	return ret;
}

- (void) reachabilityChanged {
	reachable = ([_reachability currentReachabilityStatus] != NotReachable);
}

+ (BOOL) useAPI {
	return NO;
}

#pragma mark-

- (BOOL) isBookmarking:(NSString *)ID {
	return [bookmarkAddingIDs containsObject:ID];
}

- (void) addToBookmark:(NSString *)illustID withInfo:(NSDictionary *)info {
	if ([self isBookmarking:illustID]) {
		return;
	}
	
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:info];
	[mdic setObject:illustID forKey:@"IllustID"];
	[[PostQueue sharedInstance] pushObject:mdic toTarget:self action:@selector(addBookmark:handler:) cancelAction:@selector(addToBookmarkCancel)];
	
	[bookmarkAddingIDs addObject:illustID];
}

- (void) addBookmarkFailed:(NSDictionary *)info {
	AlertView *alert = [[[AlertView alloc] initWithTitle:@"ブックマークに失敗しました。" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
	alert.tag = 100;
	alert.object = info;
	[alert show];
	
	[bookmarkAddingIDs removeObject:[info objectForKey:@"IllustID"]];
}

- (long) addBookmark:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if ([self addToBookmark:[info objectForKey:@"IllustID"] withInfo:info handler:self]) {
		[self addBookmarkFailed:info];
		[obj post:self finished:0];
	} else {
		addBookmarkQueueHandler = obj;
	}
	return 0;
}

- (void) pixService:(PixService *)sender addBookmarkFinished:(long)err {
	NSDictionary *dic = [[[[PostQueue sharedInstance] currentItem].object retain] autorelease];
	[addBookmarkQueueHandler post:self finished:0];
	if (err < 0) {
		[self addBookmarkFailed:dic];
	} else {
		[bookmarkAddingIDs removeObject:[dic objectForKey:@"IllustID"]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PixServiceBookmarkFinishedNotification" object:self userInfo:dic];
	}
}

- (BOOL) isRating:(NSString *)ID {
	return [ratingIDs containsObject:ID];
}

- (void) rating:(NSInteger)val withInfo:(NSDictionary *)info {
	if ([self isRating:[info objectForKey:@"IllustID"]]) {
		return;
	}
	
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:info];
	[mdic setObject:[NSNumber numberWithInteger:val] forKey:@"Value"];
	[[PostQueue sharedInstance] pushObject:mdic toTarget:self action:@selector(rating:handler:) cancelAction:@selector(ratingCancel)];
	
	[ratingIDs addObject:[info objectForKey:@"IllustID"]];
}

- (NSString *) ratingFailedMessage {
	return @"評価に失敗しました。";
}

- (void) ratingFailed:(NSDictionary *)info {
	AlertView *alert = [[[AlertView alloc] initWithTitle:[self ratingFailedMessage] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
	alert.tag = 200;
	alert.object = info;
	[alert show];

	[ratingIDs removeObject:[info objectForKey:@"IllustID"]];
}

- (long) rating:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if ([self rating:[[info objectForKey:@"Value"] intValue] withInfo:info handler:self]) {
		[self ratingFailed:info];
		[obj post:self finished:0];
	} else {
		ratingQueueHandler = obj;
	}
	return 0;
}

- (void) pixService:(PixService *)sender ratingFinished:(long)err {
	NSDictionary *dic = [[[[PostQueue sharedInstance] currentItem].object retain] autorelease];
	[ratingQueueHandler post:self finished:0];
	if (err < 0) {
		[self ratingFailed:dic];
	} else {
		[ratingIDs removeObject:[dic objectForKey:@"IllustID"]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PixServiceRatingFinishedNotification" object:self userInfo:dic];
	}
}

- (BOOL) isCommenting:(NSString *)ID {
	return [commentingIDs containsObject:ID];
}

- (void) comment:(NSString *)str withInfo:(NSDictionary *)info {
	if ([self isCommenting:[info objectForKey:@"IllustID"]]) {
		return;
	}
	
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:info];
	[mdic setObject:str forKey:@"Value"];
	[[PostQueue sharedInstance] pushObject:mdic toTarget:self action:@selector(comment:handler:) cancelAction:@selector(commentCancel)];
	
	[commentingIDs addObject:[info objectForKey:@"IllustID"]];
}

- (void) commentFailed:(NSDictionary *)info {
	AlertView *alert = [[[AlertView alloc] initWithTitle:@"コメントの投稿に失敗しました。" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
	alert.tag = 300;
	alert.object = info;
	[alert show];
	
	[commentingIDs removeObject:[info objectForKey:@"IllustID"]];
}

- (long) comment:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if ([self comment:[info objectForKey:@"Value"] withInfo:info handler:self]) {
		[self commentFailed:info];
		[obj post:self finished:0];
	} else {
		commentQueueHandler = obj;
	}
	return 0;
}

- (void) pixService:(PixService *)sender commentFinished:(long)err {
	NSDictionary *dic = [[[[PostQueue sharedInstance] currentItem].object retain] autorelease];
	[commentQueueHandler post:self finished:0];
	if (err < 0) {
		[self commentFailed:dic];
	} else {
		[commentingIDs removeObject:[dic objectForKey:@"IllustID"]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PixServiceCommentFinishedNotification" object:self userInfo:dic];
	}
}

- (void)alertView:(AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		return;
	}
	
	switch (alertView.tag) {
		case 100:
			[[PostQueue sharedInstance] pushObject:alertView.object toTarget:self action:@selector(addBookmark:handler:) cancelAction:@selector(addToBookmarkCancel)];
			break;
		case 200:
			[[PostQueue sharedInstance] pushObject:alertView.object toTarget:self action:@selector(rating:handler:) cancelAction:@selector(addToBookmarkCancel)];
			break;
		case 300:
			[[PostQueue sharedInstance] pushObject:alertView.object toTarget:self action:@selector(comment:handler:) cancelAction:@selector(addToBookmarkCancel)];
			break;
			
		default:
			break;
	}
}

#pragma mark-

+ (PixService *) serviceWithName:(NSString *)name {
	PixService *service = nil;
	if ([name isEqualToString:@"pixiv"]) {
		service = (PixService *)[NSClassFromString(@"Pixiv") sharedInstance];
	} else if ([name isEqualToString:@"PiXA"]) {
		service = (PixService *)[NSClassFromString(@"Pixa") sharedInstance];
	} else if ([name isEqualToString:@"TINAMI"]) {
		service = (PixService *)[NSClassFromString(@"Tinami") sharedInstance];
	//} else if ([name isEqualToString:@"Tumblr"]) {
	//	service = (PixService *)[NSClassFromString(@"Tumblr") performSelector:@selector(instance)];
	} else if ([name isEqualToString:@"Seiga"]) {
		service = (PixService *)[NSClassFromString(@"Seiga") sharedInstance];
	} else {
		service = (PixService *)[NSClassFromString(@"ScrapingService") performSelector:@selector(serviceFromName:) withObject:[[PixAccount serviceWithName:name] objectForKey:@"name"]];
	}
	return service;
}

@end
