//
//  Pixa.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Pixa.h"
#import "PixaLoginParser.h"
#import "Reachability.h"
#import "StatusMessageViewController.h"


@implementation Pixa

@synthesize authenticityToken;

+ (Pixa *) sharedInstance {
	static Pixa *obj = nil;
	if (obj == nil) {
		obj = [[Pixa alloc] init];
	}
	return obj;
}

- (NSString *) hostName {
	return @"www.pixa.cc";
}

- (NSTimeInterval) loginExpiredTimeInterval {
	return DBL_MAX;
}

- (long) login:(id<PixServiceLoginHandler>)handler {
	if ([self.username length] == 0 || [self.password length] == 0) {
		return -1;
	}	
	if ([[Reachability reachabilityWithHostName:@"www.pixa.cc"] currentReachabilityStatus] == 0) {
		// 接続不可
		return -2;
	}
	if (loginConnection_ || logoutConnection_) {
		return 0;
	}
	loginHandler_ = handler;
	
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.pixa.cc/logout"]];
	[req autorelease];
	
	logoutRet_ = [[NSMutableData alloc] init];
	
	logoutConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[logoutConnection_ start];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

- (long) loginCancel {
	if (loginConnection_ || logoutConnection_) {
		[logoutConnection_ cancel];
		[logoutConnection_ release];
		logoutConnection_ = nil;
		[loginConnection_ cancel];
		[loginConnection_ release];
		loginConnection_ = nil;
		[logoutRet_ release];
		logoutRet_ = nil;
		[loginRet_ release];
		loginRet_ = nil;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
	return 0;
}

- (long) addToBookmark:(NSString *)illustID withInfo:(NSDictionary *)info handler:(id<PixServiceAddBookmarkHandler>)handler {
	if ([[Reachability reachabilityWithHostName:@"www.pixa.cc"] currentReachabilityStatus] == 0) {
		// 接続不可
		return -2;
	}
	if (![info objectForKey:@"AuthenticityToken"]) {
		return -1;
	}

	[self addToBookmarkCancel];
	
	NSMutableURLRequest		*req;	
	if ([[info objectForKey:@"Type"] isEqualToString:@"user"]) {	
		// フォロー
		req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixa.cc/follows/add/%@?%@=%@", illustID, [@"authenticity_token" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[info objectForKey:@"AuthenticityToken"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
	} else {
		// コレクション
		req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixa.cc/illustrations/collection_illust/%@?%@=%@", illustID, [@"authenticity_token" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[info objectForKey:@"AuthenticityToken"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
	}
	[req autorelease];
	[req setValue:[NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", illustID] forHTTPHeaderField:@"Referer"];
	
	addBookmarkHandler_ = handler;
	addBookmarkConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
/*
	NSURLResponse			*res;
	NSError					*err = nil;
	NSData					*postRet;
	NSString				*retstr;
	
	postRet = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	retstr = postRet ? [[[NSString alloc] initWithData:postRet encoding:NSUTF8StringEncoding] autorelease] : nil;
	DLog(@"addToBookmark: %@", retstr);
	if (err) {
		return [err code];
	}
*/	

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

- (long) allertReachability {
	long	err = 0;
		
	if (!self.logined) {
		return -1;
		//err = [self login];
	} else if (!self.reachable) {
		// 接続不可
		err = -2;
	}

	if (err == -1) {
		// ログイン失敗 -> そのまま
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
	if (con == loginConnection_) {
		[loginRet_ appendData:data];
	} else if (con == logoutConnection_) {
		[logoutRet_ appendData:data];
	}
}


- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	if (con == logoutConnection_) {
		[logoutConnection_ release];
		logoutConnection_ = nil;
		[logoutRet_ release];
		logoutRet_ = nil;
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
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	if (con == logoutConnection_) {
		[logoutConnection_ release];
		logoutConnection_ = nil;
	
		// login
		PixaLoginParser	*parser = [[PixaLoginParser alloc] initWithEncoding:NSUTF8StringEncoding];
		[parser autorelease];
		[parser addData:logoutRet_];
		
		[logoutRet_ release];
		logoutRet_ = nil;
		
		// login
		NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.pixa.cc/session"]];
		[req autorelease];
		[req setHTTPMethod:@"POST"];
		[req setValue:@"http://www.pixa.cc/" forHTTPHeaderField:@"Referer"];
	
		// body
		NSMutableString		*body = [NSMutableString string];
		BOOL				first = YES;
		for (NSDictionary *input in parser.inputs) {
			NSString	*name = [input objectForKey:@"name"];
		
			if (first) {
				first = NO;
			} else {
				[body appendString:@"&"];
			}
		
			if ([name isEqualToString:@"email"]) {
				[body appendFormat:@"%@=%@", name, encodeURIComponent(self.username)];
			} else if ([name isEqualToString:@"password"]) {
				[body appendFormat:@"%@=%@", name, encodeURIComponent(self.password)];
			} else if ([name isEqualToString:@"remember_me"]) {
				[body appendFormat:@"%@=%d", name, 1];
			} else {
				NSString	*value = [input objectForKey:@"value"];
				[body appendFormat:@"%@=%@", name, encodeURIComponent(value)];
			}
		
			if ([name isEqualToString:@"authenticity_token"]) {
				self.authenticityToken = [input objectForKey:@"value"];
			}
		}
		[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
		
		loginRet_ = [[NSMutableData alloc] init];
		
		loginConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		[loginConnection_ start];
	} else if (con == loginConnection_) {
		[loginConnection_ release];
		loginConnection_ = nil;
	
		NSString	*retstr = loginRet_ ? [[[NSString alloc] initWithData:loginRet_ encoding:NSUTF8StringEncoding] autorelease] : nil;
		DLog(@"login: %@", retstr);
		[loginRet_ release];
		loginRet_ = nil;
	
		NSRange	range = {NSNotFound, 0};
		if (retstr) range = [retstr rangeOfString:@"<form action=\"/session\""];
		if (range.location != NSNotFound && range.length > 0) {
			// ログイン失敗
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

			[loginHandler_ pixService:self loginFinished:-1];
			return;
		}
	
		logined = YES;
		[loginHandler_ pixService:self loginFinished:0];
		[[StatusMessageViewController sharedInstance] showMessage:@"ログインしました"];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	} else if (con == addBookmarkConnection_) {
		[addBookmarkConnection_ release];
		addBookmarkConnection_ = nil;
		[addBookmarkHandler_ pixService:self addBookmarkFinished:0];
		addBookmarkHandler_ = nil;
		[[StatusMessageViewController sharedInstance] showMessage:@"ブックマークしました"];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

@end
