//
//  Pixiv.m
//  pixiViewerTest
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Pixiv.h"
#import "CHHtmlParser.h"
#import "CHHtmlParserConnection.h"
#import "Reachability.h"

#import "StatusMessageViewController.h"
#import "PixitailConstants.h"
#import "RegexKitLite.h"
#import "NSData+Crypto.h"


@implementation Pixiv

@synthesize tt;

+ (BOOL) useAPI {
	return NO;
}

+ (Pixiv *) sharedInstance {
	static Pixiv	*obj = nil;
	if (obj == nil) {
		obj = [[Pixiv alloc] init];
	}
	return obj;
}

- (NSString *) hostName {
	if ([[self class] useAPI]) {
		return @"iphone.pxv.jp";
	} else {
		return @"www.pixiv.net";
	}
}

- (id) init {
	self = [super init];
	if (self) {
	}
	return self;
}

- (void) dealloc {
	self.tt = nil;
	[super dealloc];
}

- (NSTimeInterval) loginExpiredTimeInterval {
	//return DBL_MAX;
	if ([[PixitailConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"]) {
		return [[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"] doubleValue];
	} else {
		return DBL_MAX;
	}
}

#pragma mark-

- (NSString *) apiLogin {
	// login
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://iphone.pxv.jp/iphone/login.php"]];
	NSString				*body;
	[req autorelease];
	
	if ([self.username length] == 0 || [self.password length] == 0) {
		return nil;
	} else {		
		body = [NSString stringWithFormat:@"mode=login&pixiv_id=%@&pass=%@&skip=0", encodeURIComponent(self.username), encodeURIComponent(self.password)];
	}
	
	if (!self.reachable) {
		// 接続不可
		return nil;
	}
	
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	[req setValue:@"http://iphone.pxv.jp/" forHTTPHeaderField:@"Referer"];
	[req setHTTPShouldHandleCookies:NO];
		
	//NSURLResponse *res;
	//NSError *err;
	//NSData *data;
	//data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	// http://iphone.pxv.jp/iphone/index.php?PHPSESSID=623623e2da2bf0ff7c7e85ff8a972cbc
	NSString *url = [[req URL] absoluteString];
	NSArray *ary = [url componentsSeparatedByString:@"PHPSESSID="];
	if ([ary count] == 2) {
		return [ary objectAtIndex:1];
	}
	return nil;
}

- (long) login:(id<PixServiceLoginHandler>)handler {
	if ([self.username length] == 0 || [self.password length] == 0) {
		return -1;
	}
	if (!self.reachable) {
		// 接続不可
		return -2;
	}
	if (loginConnection_ || logoutConnection_) {
		return 0;
	}
	
	loginHandler_ = handler;
	[[PixitailConstants sharedInstance] reload:self];
	return 0;
}

- (void) constantsManager:(id)sender finishLoading:(NSError *)err {
#ifdef PIXITAIL
	NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.org.cathand.pixitail"];
	if (![defaults boolForKey:@"initial"] && [[defaults objectForKey:@"widgets"] count] == 0) {
		NSMutableArray *mary = [NSMutableArray array];
		for (NSDictionary *section in [[PixitailConstants sharedInstance] valueForKeyPath:@"menu"]) {
			for (NSDictionary *row in section[@"rows"]) {
				if ([row[@"method"] hasPrefix:@"bookmark_new_illust.php?"] || [row[@"method"] isEqualToString:@"ranking.php?mode=dayly&content=illust&"]) {
					
					NSMutableDictionary *mdic = [[row mutableCopy] autorelease];
					mdic[@"service"] = @"pixiv";
					mdic[@"username"] = self.username;
					mdic[@"password"] = [self.password cryptedString];
					[mary addObject:mdic];
				}
			}
		}
		[defaults setObject:mary forKey:@"widgets"];
		
		[defaults setBool:YES forKey:@"initial"];
		[defaults synchronize];
	}
#endif
		
	
	// logout
	NSString *url = [[PixitailConstants sharedInstance] valueForKeyPath:@"urls.logout"];
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
	[req autorelease];
	
	logoutConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[logoutConnection_ start];
	
	DLog(@"logout start");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
}

- (long) loginCancel {
	if (loginConnection_ || logoutConnection_) {
		[logoutConnection_ cancel];
		[logoutConnection_ release];
		logoutConnection_ = nil;
		[loginConnection_ cancel];
		[loginConnection_ release];
		loginConnection_ = nil;
		[loginRet_ release];
		loginRet_ = nil;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
	return 0;
}

- (long) addToBookmark:(NSString *)illustID withInfo:(NSDictionary *)info handler:(id<PixServiceAddBookmarkHandler>)handler {
	if (!self.reachable) {
		// 接続不可
		return -2;
	}
	
	[self addToBookmarkCancel];
	
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.pixiv.net/bookmark_add.php"]];
	NSMutableString			*body = [NSMutableString string];
	[req autorelease];
	
	int			open = -1;		// 公開
	NSString	*tag = nil;
	NSString	*comment = nil;
	NSString	*type = [info objectForKey:@"Type"];
	
	if ([info objectForKey:@"IsOpen"]) {
		open = [[info objectForKey:@"IsOpen"] boolValue] ? 0 : 1;
	}
	
	[body appendString:[NSString stringWithFormat:@"mode=add&type=%@&tt=%@", type, [[info objectForKey:@"FormInfo"] objectForKey:@"tt"]]];		// type=user
	if ([type isEqual:@"user"]) {
		[body appendString:[NSString stringWithFormat:@"&user_id=%@", illustID]];
	} else {
		[body appendString:[NSString stringWithFormat:@"&id=%@", illustID]];
	}
	if (open > -1) {
		[body appendString:[NSString stringWithFormat:@"&restrict=%d", open]];
	}
	if (tag) {
		[body appendString:[NSString stringWithFormat:@"&tag=%@", encodeURIComponent(tag)]];
	}
	if (comment) {
		[body appendString:[NSString stringWithFormat:@"&comment=%@", encodeURIComponent(comment)]];
	}
	
	DLog(@"pixiv add: %@", body);
	[req setValue:@"http://www.pixiv.net/" forHTTPHeaderField:@"Referer"];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	
	addBookmarkHandler_ = handler;
	addBookmarkConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[addBookmarkConnection_ start];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

// http://www.pixiv.net/bookmark_setting.php?type=user&rest=hide&id[]=767466&del=1
//- (long) removeFromBookmark:(NSString *)illustID {
- (long) removeFromBookmark:(NSString *)illustID withInfo:(NSDictionary *)info handler:(id<PixServiceAddBookmarkHandler>)handler {
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.pixiv.net/bookmark_setting.php"]];
	NSMutableString			*body = [NSMutableString string];
	[req autorelease];
	
	if (!self.reachable) {
		// 接続不可
		return -2;
	}

	int			open = -1;		// 公開
	NSString	*type = [info objectForKey:@"Type"];
	
	if ([info objectForKey:@"IsOpen"]) {
		open = [[info objectForKey:@"IsOpen"] boolValue] ? 0 : 1;
	}
	
	[body appendString:[NSString stringWithFormat:@"id[]=%@&type=%@", illustID, type]];		// type=user
	if (open == 1) {
		[body appendString:@"&rest=hide"];
	}

	
	[body appendString:[NSString stringWithFormat:@"del=1&id=%@&type=illust", illustID]];
	
	[req setValue:@"http://www.pixiv.net/" forHTTPHeaderField:@"Referer"];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];

	NSURLResponse			*res;
	NSError					*err = nil;
	//NSData					*postRet;
	//NSString				*retstr;
	
	/*postRet = */[NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	//retstr = postRet ? [[[NSString alloc] initWithData:postRet encoding:NSJapaneseEUCStringEncoding] autorelease] : nil;
	DLog(@"removeFromBookmark:");
	//DLog(retstr);
	if (err) {
		return [err code];
	}
	
	return 0;
}

- (long) rating:(NSInteger)val withInfo:(NSDictionary *)info handler:(id<PixServiceRatingHandler>)handler {
	if (!self.reachable) {
		// 接続不可
		return -2;
	}
	
	if (![info objectForKey:@"IllustID"] || val < 0 || val > 10) {
		// パラメータ
		return -3;
	}
	
	NSString *uid = nil;
	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://www.pixiv.net"]]) {
		if ([cookie.name isEqualToString:@"PHPSESSID"]) {
			NSArray *a = [cookie.value componentsSeparatedByString:@"_"];
			uid = a.firstObject;
		}
	}
	if (!uid) {
		return -3;
	}
	
	[self ratingCancel];
	
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.pixiv.net/rpc_rating.php"]];
	NSString				*body = nil;
	[req autorelease];
	
	body = [NSString stringWithFormat:@"mode=save&i_id=%@&u_id=%@&qr=%@&score=%@", [info objectForKey:@"IllustID"], uid, @"0", @(val)];
	
	[req setValue:@"http://www.pixiv.net/" forHTTPHeaderField:@"Referer"];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];

	ratingHandler_ = handler;
	ratingConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[ratingConnection_ start];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

- (long) comment:(NSString *)str withInfo:(NSDictionary *)info handler:(id<PixServiceCommentHandler>)handler {
	if (!self.reachable) {
		// 接続不可
		return -2;
	}
	
	if (![info objectForKey:@"IllustID"] || [str length] > 255 || [str length] < 1) {
		// パラメータ
		return -3;
	}
	
	[self commentCancel];
	
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.pixiv.net/member_illust.php"]];
	NSString				*body = nil;
	[req autorelease];
	
	body = [NSString stringWithFormat:@"mode=comment_save&illust_id=%@&tt=%@&comment=%@", [info objectForKey:@"IllustID"], [[info objectForKey:@"FormInfo"] objectForKey:@"tt"], encodeURIComponent(str)];

	[req setValue:[NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@", [info objectForKey:@"IllustID"]] forHTTPHeaderField:@"Referer"];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];

	commentHandler_ = handler;
	commentConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[commentConnection_ start];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

#pragma mark-

- (long) allertReachability {
	long	err = 0;
	
	if (!self.logined) {
		//err = [self login:nil];
		return -1;
	} else if (!self.reachable) {
		// 接続不可
		err = -2;
	}

	if (err == -1) {
		// ログイン失敗
		UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login faied.", nil) message:NSLocalizedString(@"Please confirm your account.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		[alert show];
		[alert release];
	} else if (err == -2) {
		// 通信不可
		UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"Network is not connected.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		[alert show];
		[alert release];
	} else if (err != 0) {
		// その他
		UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		[alert show];
		[alert release];
	}
	
	return err;
}


#pragma mark-

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
}


- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	DLog(@"receive: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	if (con == loginConnection_) {
		if (loginRet_) {
			[loginRet_ appendData:data];
		}
	}
}


- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	if (con == logoutConnection_) {
		[logoutConnection_ release];
		logoutConnection_ = nil;
		[loginHandler_ pixService:self loginFinished:[error code]];
	} else if (con == loginConnection_) {
		[loginConnection_ release];
		loginConnection_ = nil;
		[loginRet_ release];
		loginRet_ = nil;
		[loginHandler_ pixService:self loginFinished:[error code]];
	} else if (con == addBookmarkConnection_) {
		[addBookmarkConnection_ release];
		addBookmarkConnection_ = nil;
		[addBookmarkHandler_ pixService:self addBookmarkFinished:[error code]];
		addBookmarkHandler_ = nil;
	} else if (con == ratingConnection_) {
		[ratingConnection_ release];
		ratingConnection_ = nil;
		[ratingHandler_ pixService:self ratingFinished:[error code]];
		ratingHandler_ = nil;
	} else if (con == commentConnection_) {
		[commentConnection_ release];
		commentConnection_ = nil;
		[commentHandler_ pixService:self commentFinished:[error code]];
		commentHandler_ = nil;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	if (con == logoutConnection_) {
		[logoutConnection_ release];
		logoutConnection_ = nil;
		
		DLog(@"logout finished");
		
		// login
		NSString *url = [[PixitailConstants sharedInstance] valueForKeyPath:@"urls.login"];
		NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
		NSString				*body;
		[req autorelease];
	
		if ([self.username length] == 0 || [self.password length] == 0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

			[loginHandler_ pixService:self loginFinished:-1];
			return;
		} else {
            NSString *fmt = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.login_body_format"];
			body = [NSString stringWithFormat:fmt, encodeURIComponent(self.username), encodeURIComponent(self.password)];
		}
	
		if ([[Reachability reachabilityWithHostName:@"www.pixiv.net"] currentReachabilityStatus] == 0) {
			// 接続不可
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

			[loginHandler_ pixService:self loginFinished:-2];
			return;
		}
	
		[req setHTTPMethod:@"POST"];
		[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
		
		loginRet_ = [[NSMutableData alloc] init];
		
		loginConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		[loginConnection_ start];
		
		DLog(@"login started");
	} else if (con == loginConnection_) {
		[loginConnection_ release];
		loginConnection_ = nil;

		DLog(@"login finished");
	
		NSString	*retstr = loginRet_ ? [[[NSString alloc] initWithData:loginRet_ encoding:NSUTF8StringEncoding] autorelease] : nil;
		DLog(@"login: %@", retstr);
		[loginRet_ release];
		loginRet_ = nil;
	
		NSRange	range = {-1, 0};
		if (retstr) range = [retstr rangeOfString:@"action=\"/login.php\""];
		if (range.location != NSNotFound && range.length > 0) {
			// ログイン失敗
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			[loginHandler_ pixService:self loginFinished:-1];
			return;
		} else {
			NSString *regex = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.tt_regex"];
			NSArray *ary = [retstr captureComponentsMatchedByRegex:regex];
			if (ary.count > 1) {
				self.tt = [ary objectAtIndex:1];
				
				logined = YES;
				[[StatusMessageViewController sharedInstance] showMessage:@"ログインしました"];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
				[loginHandler_ pixService:self loginFinished:0];
			} else {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
				[loginHandler_ pixService:self loginFinished:-1];
				
			}			
		}	
	} else if (con == addBookmarkConnection_) {
		[addBookmarkConnection_ release];
		addBookmarkConnection_ = nil;
		[addBookmarkHandler_ pixService:self addBookmarkFinished:0];
		addBookmarkHandler_ = nil;
		[[StatusMessageViewController sharedInstance] showMessage:@"ブックマークしました"];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	} else if (con == ratingConnection_) {
		[ratingConnection_ release];
		ratingConnection_ = nil;
		[ratingHandler_ pixService:self ratingFinished:0];
		ratingHandler_ = nil;
		[[StatusMessageViewController sharedInstance] showMessage:@"評価しました"];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	} else if (con == commentConnection_) {
		[commentConnection_ release];
		commentConnection_ = nil;
		[commentHandler_ pixService:self commentFinished:0];
		commentHandler_ = nil;
		[[StatusMessageViewController sharedInstance] showMessage:@"コメントしました"];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (NSURLRequest *)connection:(NSURLConnection *)con willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	return request;
}

@end
