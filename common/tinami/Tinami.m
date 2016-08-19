//
//  Tinami.m
//  pixiViewer
//
//  Created by nya on 10/02/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Tinami.h"
#import "Reachability.h"
#import "TinamiAuthParser.h"
#import "TinamiRatingResponseParser.h"
#import "StatusMessageViewController.h"


@implementation Tinami

@synthesize creatorID;

+ (Tinami *) sharedInstance {
	static Tinami	*obj = nil;
	if (obj == nil) {
		obj = [[Tinami alloc] init];
	}
	return obj;
}

- (void) dealloc {
	[creatorID release];
	[super dealloc];
}

- (NSString *) hostName {
	return @"api.tinami.com";
}

- (NSTimeInterval) loginExpiredTimeInterval {
	return 3600;
}

- (long) login:(id<PixServiceLoginHandler>)handler {
	if (!self.reachable) {
		// 接続不可
		return -2;
	}
	if (loginConnection_ || logoutConnection_ || getLoginInfoConnection) {
		return 0;
	}
	
	[creatorID release];
	creatorID = nil;
	
	{
		// logout
		loginHandler_ = handler;
		
		NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.tinami.com/logout?api_key=%@", TINAMI_API_KEY]]];
		[req autorelease];
	
		if ([[Reachability reachabilityWithHostName:@"api.tinami.com"] currentReachabilityStatus] == 0) {
			// 接続不可
			return -2;
		}
	
		[req setHTTPMethod:@"GET"];
				
		logoutConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		[logoutConnection_ start];
	
		DLog(@"logout start");
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

- (long) loginCancel {
	if (loginConnection_ || logoutConnection_ || getLoginInfoConnection) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

		[logoutConnection_ cancel];
		[logoutConnection_ release];
		logoutConnection_ = nil;
		[loginConnection_ cancel];
		[loginConnection_ release];
		loginConnection_ = nil;
		[getLoginInfoConnection cancel];
		[getLoginInfoConnection release];
		getLoginInfoConnection = nil;
		[loginRet_ release];
		loginRet_ = nil;
	}
	return 0;
}

- (long) rating:(NSInteger)val withInfo:(NSDictionary *)info handler:(id<PixServiceRatingHandler>)handler {
	if (!self.reachable) {
		// 接続不可
		return -2;
	}
	
	if (![info objectForKey:@"IllustID"]) {
		// パラメータ
		return -3;
	}
	
	[self ratingCancel];
	
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.tinami.com/content/support"]];
	NSString				*body = nil;
	[req autorelease];

	body = [NSString stringWithFormat:@"api_key=%@&cont_id=%@", TINAMI_API_KEY, [info objectForKey:@"IllustID"]];

	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	
	ratingRet = [[NSMutableData alloc] init];
	
	ratingHandler_ = handler;
	ratingConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[ratingConnection_ start];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

- (void) ratingCancel {
	[ratingRet release];
	ratingRet = nil;
	[super ratingCancel];
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
	
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.tinami.com/content/comment/add"]];
	NSString				*body = nil;
	[req autorelease];
	
	body = [NSString stringWithFormat:@"api_key=%@&cont_id=%@&comment=%@", TINAMI_API_KEY, [info objectForKey:@"IllustID"], encodeURIComponent(str)];

	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];

	commentHandler_ = handler;
	commentConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[commentConnection_ start];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

- (long) addToBookmark:(NSString *)illustID withInfo:(NSDictionary *)info handler:(id<PixServiceAddBookmarkHandler>)handler {
	if (!self.reachable) {
		// 接続不可
		return -2;
	}
	
	[self addToBookmarkCancel];

	NSString	*type = [info objectForKey:@"Type"];
	
	NSMutableURLRequest		*req;
	NSMutableString			*body;

	req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.tinami.com/%@/add", type]]];
	[req autorelease];
		
	if ([type isEqual:@"collection"]) {
		body = [NSMutableString stringWithFormat:@"api_key=%@&cont_id=%@", TINAMI_API_KEY, illustID];
	} else if ([type isEqual:@"bookmark"]) {
		body = [NSMutableString stringWithFormat:@"api_key=%@&prof_id=%@", TINAMI_API_KEY, illustID];
	} else {
		assert(0);
	}
	
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	
	bookmarkRet = [[NSMutableData alloc] init];
	
	addBookmarkHandler_ = handler;
	addBookmarkConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[addBookmarkConnection_ start];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	return 0;
}

- (long) addToBookmarkCancel {
	[bookmarkRet release];
	bookmarkRet = nil;
	return [super addToBookmarkCancel];
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
	} else if (con == getLoginInfoConnection) {
		if (loginRet_) {
			[loginRet_ appendData:data];
		}
	} else if (con == ratingConnection_) {
		[ratingRet appendData:data];
	} else if (con == addBookmarkConnection_) {
		[bookmarkRet appendData:data];
	}
}


- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	
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
	} else if (con == getLoginInfoConnection) {
		[getLoginInfoConnection release];
		getLoginInfoConnection = nil;
		[loginRet_ release];
		loginRet_ = nil;
		[loginHandler_ pixService:self loginFinished:[error code]];
	} else if (con == addBookmarkConnection_) {
		[addBookmarkConnection_ release];
		addBookmarkConnection_ = nil;
		[bookmarkRet release];
		bookmarkRet = nil;
		[addBookmarkHandler_ pixService:self addBookmarkFinished:[error code]];
		addBookmarkHandler_ = nil;
	} else if (con == ratingConnection_) {
		[ratingConnection_ release];
		ratingConnection_ = nil;
		[ratingRet release];
		ratingRet = nil;
		[ratingHandler_ pixService:self ratingFinished:-[error code]];
		ratingHandler_ = nil;
	} else if (con == commentConnection_) {
		[commentConnection_ release];
		commentConnection_ = nil;
		[commentHandler_ pixService:self commentFinished:[error code]];
		commentHandler_ = nil;
	}
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	if (con == logoutConnection_) {
		// login
		NSString				*body;

		[logoutConnection_ release];
		logoutConnection_ = nil;
	
		if ([self.username length] == 0 || [self.password length] == 0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			
			logined = YES;
			[loginHandler_ pixService:self loginFinished:0];
			return;
		} else {		
			body = [NSString stringWithFormat:@"api_key=%@&email=%@&password=%@", TINAMI_API_KEY, encodeURIComponent(self.username), encodeURIComponent(self.password)];
		}
		DLog(@"%@ -> %@", self.username, encodeURIComponent(self.username));
	
		if ([[Reachability reachabilityWithHostName:@"api.tinami.com"] currentReachabilityStatus] == 0) {
			// 接続不可
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			
			[loginHandler_ pixService:self loginFinished:-1];
			return;
		}
	
		NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.tinami.com/auth"]];
		[req autorelease];
		[req setHTTPMethod:@"POST"];
		[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
		
		loginRet_ = [[NSMutableData alloc] init];
		
		loginConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		[loginConnection_ start];
	
		DLog(@"login start");
	} else if (con == loginConnection_) {
		[loginConnection_ release];
		loginConnection_ = nil;

		DLog(@"login finished");
	
		//NSString	*retstr = loginRet_ ? [[[NSString alloc] initWithData:loginRet_ encoding:NSUTF8StringEncoding] autorelease] : nil;
		DLog(@"login: %@", [[[NSString alloc] initWithData:loginRet_ encoding:NSUTF8StringEncoding] autorelease]);
		TinamiAuthParser *parser = [[[TinamiAuthParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
		[parser addData:loginRet_];
		[loginRet_ release];
		loginRet_ = nil;
		if ([parser.status isEqual:@"ok"] == NO) {
			// ログイン失敗
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			
			[loginHandler_ pixService:self loginFinished:-1];
			return;
		}

		NSString *body = [NSString stringWithFormat:@"api_key=%@", TINAMI_API_KEY];
		if ([[Reachability reachabilityWithHostName:@"api.tinami.com"] currentReachabilityStatus] == 0) {
			// 接続不可
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

			[loginHandler_ pixService:self loginFinished:-1];
			return;
		}	
		NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.tinami.com/login/info"]];
		[req autorelease];
		[req setHTTPMethod:@"POST"];
		[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
		
		loginRet_ = [[NSMutableData alloc] init];
		
		getLoginInfoConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		[getLoginInfoConnection start];
		
	} else if (con == getLoginInfoConnection) {
		[getLoginInfoConnection release];
		getLoginInfoConnection = nil;

		DLog(@"get info finished");
	
		DLog(@"login: %@", [[[NSString alloc] initWithData:loginRet_ encoding:NSUTF8StringEncoding] autorelease]);
		TinamiAuthParser *parser = [[[TinamiAuthParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
		[parser addData:loginRet_];
		[loginRet_ release];
		loginRet_ = nil;
		if ([parser.status isEqual:@"ok"] == NO) {
			// ログイン失敗
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

			[loginHandler_ pixService:self loginFinished:-1];
			return;
		}
		
		[creatorID release];
		creatorID = [parser.creatorID retain];

		logined = YES;
		[loginHandler_ pixService:self loginFinished:0];
		[[StatusMessageViewController sharedInstance] showMessage:@"ログインしました"];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	} else if (con == addBookmarkConnection_) {
		DLog(@"bookmark: %@", [[[NSString alloc] initWithData:bookmarkRet encoding:NSUTF8StringEncoding] autorelease]);

		TinamiRatingResponseParser *parser = [[TinamiRatingResponseParser alloc] initWithEncoding:NSUTF8StringEncoding];
		[parser addData:bookmarkRet];
		int rate = parser.rate;
		[parser release];
		[bookmarkRet release];
		bookmarkRet = nil;

		[addBookmarkConnection_ release];
		addBookmarkConnection_ = nil;
		[addBookmarkHandler_ pixService:self addBookmarkFinished:rate != -1 ? 0 : 1];
		addBookmarkHandler_ = nil;
		[[StatusMessageViewController sharedInstance] showMessage:@"ブックマークしました"];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	} else if (con == ratingConnection_) {
		DLog(@"rating: %@", [[[NSString alloc] initWithData:ratingRet encoding:NSUTF8StringEncoding] autorelease]);

		TinamiRatingResponseParser *parser = [[TinamiRatingResponseParser alloc] initWithEncoding:NSUTF8StringEncoding];
		[parser addData:ratingRet];
		int rate = parser.rate;
		[parser release];
		[ratingRet release];
		ratingRet = nil;
	
		[ratingConnection_ release];
		ratingConnection_ = nil;
		[ratingHandler_ pixService:self ratingFinished:rate];
		ratingHandler_ = nil;
		[[StatusMessageViewController sharedInstance] showMessage:@"支援しました"];

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

- (NSString *) ratingFailedMessage {
	return @"支援に失敗しました。";
}

@end
