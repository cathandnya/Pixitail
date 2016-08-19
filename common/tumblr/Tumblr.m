//
//  Tumblr.m
//  pixiViewer
//
//  Created by nya on 09/12/12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Tumblr.h"
#import "AccountManager.h"
#import "TumblrLoginParser.h"
#import "TagCloud.h"
#import "ImageDownloader.h"
#import "BigURLDownloader.h"
#import "AlertView.h"
#import "UserDefaults.h"
#import "StatusMessageViewController.h"
#import "NSData+Crypto.h"
#import <objc/runtime.h>


@implementation Tumblr

@dynamic available, sending;
@synthesize name;

+ (Tumblr *) instance {
	static Tumblr *obj = nil;
	if (obj == nil) {
		obj = [[Tumblr alloc] init];
	}
	return obj;
}

+ (Tumblr *) sharedInstance {
	static Tumblr *obj = nil;
	if (obj == nil) {
		obj = [[Tumblr alloc] init];
		obj.username = UDString(@"TumblrUsername");
		obj.password = [UDString(@"TumblrPassword") decryptedString];
		DLog(@"%@ / %@", obj.username, obj.password);
	}
	return obj;
}

- (void) dealloc {
	self.name = nil;
	[super dealloc];
}

- (NSString *) hostName {
	return @"www.tumblr.com";
}

/*
- (BOOL) needsLogin {
	return NO;
}
*/

- (NSTimeInterval) loginExpiredTimeInterval {
	return DBL_MAX;
}

- (void) setup {
	NSString *user = [[AccountManager sharedInstance] defaultAccount:@"Tumblr"].username;
	NSString *pass = [[AccountManager sharedInstance] defaultAccount:@"Tumblr"].password;
	if (![self.username isEqual:user] || ![self.password isEqual:pass]) {
		self.username = user;
		self.password = pass;
		self.logined = NO;
	}	
}

/*
- (NSString *) mailaddress {
	return [[AccountManager sharedInstance] defaultAccount:AccountType_Tumblr].username;
}

- (NSString *) password {
	return [[AccountManager sharedInstance] defaultAccount:AccountType_Tumblr].password;
}
*/

- (BOOL) available {
	NSString *user = [[AccountManager sharedInstance] defaultAccount:@"Tumblr"].username;
	NSString *pass = [[[AccountManager sharedInstance] defaultAccount:@"Tumblr"].password decryptedString];
	return [user length] > 0 && [pass length] > 0;
}

- (BOOL) sending {
	return writePhotoConnection_ || reblogConnection_ || likeConnection_;
}

- (long) allertReachability {
	long	err = 0;
	
	if (!self.reachable) {
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

- (long) login:(id<PixServiceLoginHandler>)handler {
	if ([self.username length] == 0 || [self.password length] == 0) {
		return -1;
	}	
	if (self.reachable == NO) {
		// 接続不可
		return -2;
	}
	if (loginConnection_ || logoutConnection_) {
		return 0;
	}
	loginHandler_ = handler;
	self.name = nil;
	
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.tumblr.com/api/authenticate"]];
	[req autorelease];
	
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[[NSString stringWithFormat:@"email=%@&password=%@", encodeURIComponent(username), encodeURIComponent(password)] dataUsingEncoding:NSASCIIStringEncoding]];
	
	loginRet_ = [[NSMutableData alloc] init];
	
	loginConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[loginConnection_ start];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	return 0;
}

- (long) loginCancel {
	if (loginConnection_) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];

		[loginConnection_ cancel];
		[loginConnection_ release];
		loginConnection_ = nil;
		[loginRet_ release];
		loginRet_ = nil;
	}
	return 0;
}

- (long) writePhoto:(NSData *)data withInfo:(NSDictionary *)info handler:(id)delegate {
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.tumblr.com/api/write"]] autorelease];
	
	//DLog(@"writePhoto: %@", [info description]);
	
	NSString *boundary = @"------------0xKhTmLbOuNdArY";
	[req addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [boundary substringFromIndex:2]] forHTTPHeaderField: @"Content-Type"];
	
	NSMutableData	*body = [NSMutableData data];
	
	[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"email\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[username dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

	[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[password dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

	[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"type\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"photo" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

	if ([info objectForKey:@"Private"]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"private\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[[info objectForKey:@"Private"] boolValue] ? @"1" : @"0" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"generator\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
#ifdef PIXITAIL
	[body appendData:[@"pixitail" dataUsingEncoding:NSUTF8StringEncoding]];
#else
	[body appendData:[@"illustail" dataUsingEncoding:NSUTF8StringEncoding]];
#endif
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

	if ([info objectForKey:@"Caption"]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"caption\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[info objectForKey:@"Caption"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	if ([info objectForKey:@"URL"]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"click-through-url\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[info objectForKey:@"URL"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	if ([info objectForKey:@"Tags"]) {	
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"tags\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[info objectForKey:@"Tags"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	if ([info objectForKey:@"PostID"]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"post-id\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[info objectForKey:@"PostID"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}

	[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"send-to-twitter\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"no" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	
	if (data) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: file; name=\"data\"; filename=\"%@\"\r\n", [info objectForKey:@"Filename"]] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", [info objectForKey:@"ContentType"]] dataUsingEncoding:NSUTF8StringEncoding]];
		//DLog(@"tumblr data: %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
		[body appendData:data];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	[body appendData:[[NSString stringWithFormat:@"%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	

	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:body];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];

	delegate_ = delegate;
	writePhotoConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[writePhotoConnection_ start];
	
	if (uploadingInfo) {
		objc_setAssociatedObject(writePhotoConnection_, @"Info", uploadingInfo, OBJC_ASSOCIATION_RETAIN);
	}
	return 0;
}

- (void) writePhotoCancel {
	if (writePhotoConnection_) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
		
		[writePhotoConnection_ cancel];
		[writePhotoConnection_ release];
		writePhotoConnection_ = nil;
	}
}

- (void) writePhotoNext {
	if (writePhotoConnection_) {
		return;
	}
	
	if ([writePhotoQueue_ count] > 0) {
		NSData *data = [[writePhotoQueue_ objectAtIndex:0] objectForKey:@"Data"];
		NSDictionary *info = [[writePhotoQueue_ objectAtIndex:0] objectForKey:@"Info"];
		
		long err = [self writePhoto:data withInfo:info handler:self];
		if (err) {
			[self performSelector:@selector(writePhotoNext) withObject:nil afterDelay:1.0];
		}
	}
}

- (void) writePhotoInBackground:(NSData *)data withInfo:(NSDictionary *)info {
	if (writePhotoQueue_ == nil) {
		writePhotoQueue_ = [[NSMutableArray alloc] init];
	}
	
	[writePhotoQueue_ addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		data,		@"Data",
		info,		@"Info",
		nil]];
	[self writePhotoNext];
}

- (void) tumblr:(Tumblr *)sender writePhotoProgress:(int)percent {
}

- (void) tumblr:(Tumblr *)sender writePhotoFinished:(long)err withInfo:(NSDictionary *)info {
	if (err != 201) {
		if (uploadHandler) {
			AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Tumblr.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
			alert.tag = 200;
			alert.object = info;
			[alert show];

			[uploadHandler post:self finished:0];
		} else {
			
			[self writePhotoNext];
			[self performSelector:@selector(writePhotoNext) withObject:nil afterDelay:1.0];
		}
	} else {
		[[StatusMessageViewController sharedInstance] showMessage:@"リブログしました"];
		if (uploadHandler) {
			[uploadHandler post:self finished:0];
		} else {
			for (NSString *tag in [[writePhotoQueue_ objectAtIndex:0] objectForKey:@"Tags"]) {
				[[TagCloud sharedInstance] add:tag forType:@"Tumblr" user:self.username];
			}
			
			[writePhotoQueue_ removeObjectAtIndex:0];
			[self writePhotoNext];
		}
	}
}

- (long) reblog:(NSDictionary *)info handler:(id)obj {
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://tumblr.com/statuses/retweet/%@.xml", [info objectForKey:@"StatusID"]]]] autorelease];
	
	[req setHTTPMethod:@"POST"];
	
	reblogDelegate_ = obj;
	reblogConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[reblogConnection_ start];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	return 0;
}

- (void) reblogNext {
	if (reblogConnection_) {
		return;
	}
	
	if ([reblogQueue_ count] > 0) {
		NSDictionary *info = [reblogQueue_ objectAtIndex:0];
		
		long err = [self reblogAPI:info handler:self];
		if (err) {
			[self performSelector:@selector(reblogNext) withObject:nil afterDelay:1.0];
		}
	}
}

- (void) reblogInBackground:(NSDictionary *)info {
	if (reblogQueue_ == nil) {
		reblogQueue_ = [[NSMutableArray alloc] init];
	}
	
	[reblogQueue_ addObject:info];
	[self reblogNext];
}

- (void) tumblr:(Tumblr *)sender reblogFinished:(long)err {
	if (err != 0) {
		[self performSelector:@selector(reblogNext) withObject:nil afterDelay:1.0];
	} else {
		for (NSString *tag in [[reblogQueue_ objectAtIndex:0] objectForKey:@"Tags"]) {
			[[TagCloud sharedInstance] add:tag forType:@"Tumblr" user:self.username];
		}
	
		[reblogQueue_ removeObjectAtIndex:0];
		[self reblogNext];
	}
}

- (long) like:(NSDictionary *)info handler:(id)obj {
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://tumblr.com/favorites/create/%@.xml", [info objectForKey:@"StatusID"]]]] autorelease];
	
	[req setHTTPMethod:@"POST"];
	
	likeDelegate_ = obj;
	likeConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[likeConnection_ start];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	return 0;
}

- (long) reblogAPI:(NSDictionary *)info handler:(id)obj {
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.tumblr.com/api/reblog"]] autorelease];	
	NSMutableString *bodyStr = [NSMutableString stringWithFormat:@"email=%@&password=%@&post-id=%@&reblog-key=%@&send-to-twitter=no", encodeURIComponent(username), encodeURIComponent(password), [info objectForKey:@"PostID"], [info objectForKey:@"ReblogKey"]];
	/*
	if ([info objectForKey:@"Tags"]) {
		NSMutableString *str = [NSMutableString string];
		for (NSString *tag in [info objectForKey:@"Tags"]) {
			if ([tag length] > 0) {
				[str appendFormat:@"\"%@\"", tag];
			}
			if (tag != [[info objectForKey:@"Tags"] lastObject]) {
				[str appendString:@","];
			}
		}
		if (str.length > 0) {
			[bodyStr appendFormat:@"&tags=%@", [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	if ([info objectForKey:@"Private"]) {
		[bodyStr appendFormat:@"&private=%@", [[[info objectForKey:@"Private"] boolValue] ? @"1" : @"0" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	*/
	
	[reblogingInfo release];
	reblogingInfo = [info retain];
	[reblogRet release];
	reblogRet = [[NSMutableData alloc] init];
	
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[bodyStr dataUsingEncoding:NSASCIIStringEncoding]];
	
	reblogDelegate_ = obj;
	reblogConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[reblogConnection_ start];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	return 0;
}

- (void) reblogCancel {
	if (reblogConnection_ || reblogTaggingConnection_) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
		
		[reblogConnection_ cancel];
		[reblogConnection_ release];
		reblogConnection_ = nil;
		[reblogTaggingConnection_ cancel];
		[reblogTaggingConnection_ release];
		reblogTaggingConnection_ = nil;
	}
}

- (long) likeAPI:(NSDictionary *)info handler:(id)obj {
	NSString *str;
	if ([[info objectForKey:@"Unlike"] boolValue]) {
		str = @"http://www.tumblr.com/api/unlike";	
	} else {
		str = @"http://www.tumblr.com/api/like";	
	}
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:str]] autorelease];
	
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[[NSString stringWithFormat:@"email=%@&password=%@&post-id=%@&reblog-key=%@", encodeURIComponent(username), encodeURIComponent(password), [info objectForKey:@"PostID"], [info objectForKey:@"ReblogKey"]] dataUsingEncoding:NSASCIIStringEncoding]];
	
	likeDelegate_ = obj;
	likeConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[likeConnection_ start];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	return 0;
}

- (void) likeCancel {
	if (likeConnection_) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
		
		[likeConnection_ cancel];
		[likeConnection_ release];
		likeConnection_ = nil;
	}
}

- (long) deletePost:(NSString *)postID handler:(id<TumblrDeleteDelegate>)obj {
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.tumblr.com/api/delete"]] autorelease];	
	NSMutableString *bodyStr = [NSMutableString stringWithFormat:@"email=%@&password=%@&post-id=%@", encodeURIComponent(username), encodeURIComponent(password), postID];

	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[bodyStr dataUsingEncoding:NSASCIIStringEncoding]];
	
	deleteDelegate_ = obj;
	deleteConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[deleteConnection_ start];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	return 0;
}

- (void) deletePostCancel {
	if (deleteConnection_) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
		
		[deleteConnection_ cancel];
		[deleteConnection_ release];
		deleteConnection_ = nil;
	}
}

#pragma mark-

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
	DLog(@"tumblr didReceiveResponse: %d", [(NSHTTPURLResponse*)response statusCode]);
	if (con == loginConnection_) {
	
	} else {
		lastResponce_ = [(NSHTTPURLResponse*)response statusCode];
	}
}


- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	if (con == loginConnection_) {
		[loginRet_ appendData:data];
	} else if (con == reblogConnection_) {
		DLog(@"reblog: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
		[reblogRet appendData:data];
	}
}


- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	DLog(@"tumblr didFailWithError: %d", [error code]);
	if (con == loginConnection_) {
		[loginConnection_ release];
		loginConnection_ = nil;
		[loginHandler_ pixService:self loginFinished:[error code]];
	} else if (con == writePhotoConnection_) {
		NSDictionary *info = objc_getAssociatedObject(writePhotoConnection_, @"Info");
		[[info retain] autorelease];

		[writePhotoConnection_ release];
		writePhotoConnection_ = nil;
		[delegate_ tumblr:self writePhotoFinished:[error code] withInfo:info];
	} else if (con == reblogConnection_) {
		[reblogConnection_ release];
		reblogConnection_ = nil;
		[reblogDelegate_ tumblr:self reblogFinished:[error code]];
	} else if (con == reblogTaggingConnection_) {
		[reblogTaggingConnection_ release];
		reblogTaggingConnection_ = nil;
		[reblogDelegate_ tumblr:self reblogFinished:0];
	} else if (con == likeConnection_) {
		[likeConnection_ release];
		likeConnection_ = nil;
		[likeDelegate_ tumblr:self likeFinished:[error code]];
	} else if (con == deleteConnection_) {
		[deleteConnection_ release];
		deleteConnection_ = nil;
		[deleteDelegate_ tumblr:self deleteFinished:[error code]];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
}

- (void) reblogTagging:(NSString *)postID {
	NSDictionary *info = reblogingInfo;
	DLog(@"reblogTagging: %@", [info description]);
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.tumblr.com/api/write"]] autorelease];	
	NSMutableString *bodyStr = [NSMutableString stringWithFormat:@"email=%@&password=%@&post-id=%@", encodeURIComponent(username), encodeURIComponent(password), postID];
	if ([info objectForKey:@"Tags"]) {
		NSMutableString *str = [NSMutableString string];
		for (NSString *tag in [info objectForKey:@"Tags"]) {
			if ([tag length] > 0) {
				[str appendFormat:@"\"%@\"", tag];
			}
			if (tag != [[info objectForKey:@"Tags"] lastObject]) {
				[str appendString:@","];
			}
		}
		if (str.length > 0) {
			[bodyStr appendFormat:@"&tags=%@", encodeURIComponent(str)];
		}
	}
	if ([info objectForKey:@"Private"]) {
		[bodyStr appendFormat:@"&private=%@", [[info objectForKey:@"Private"] boolValue] ? @"1" : @"0"];
	}
	if ([info objectForKey:@"PhotoLink"]) {
		[bodyStr appendFormat:@"&click-through-url=%@", encodeURIComponent([info objectForKey:@"PhotoLink"])];
	}
	if ([info objectForKey:@"Caption"]) {
		[bodyStr appendFormat:@"&caption=%@", encodeURIComponent([info objectForKey:@"Caption"])];
	}
	[bodyStr appendString:@"&send-to-twitter=no"];
	
	[req setHTTPBody:[bodyStr dataUsingEncoding:NSUTF8StringEncoding]];
	[req setHTTPMethod:@"POST"];
			
	reblogTaggingConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[reblogTaggingConnection_ start];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	DLog(@"tumblr connectionDidFinishLoading: %d", 0);
	if (con == loginConnection_) {
		//DLog([[[NSString alloc] initWithData:loginRet_ encoding:NSUTF8StringEncoding] autorelease]);

		[loginConnection_ release];
		loginConnection_ = nil;
		
		TumblrLoginParser *parser = [[TumblrLoginParser alloc] initWithEncoding:NSUTF8StringEncoding];
		[parser addData:loginRet_];
		[loginRet_ release];
		[parser autorelease];
		
		if (parser.name == nil) {
			[loginHandler_ pixService:self loginFinished:-1];
		}
		self.name = parser.name;
		self.logined = YES;
		
		[loginHandler_ pixService:self loginFinished:0];
		[[StatusMessageViewController sharedInstance] showMessage:@"ログインしました"];
	} else if (con == writePhotoConnection_) {
		NSDictionary *info = objc_getAssociatedObject(writePhotoConnection_, @"Info");
		[[info retain] autorelease];
		
		[writePhotoConnection_ release];
		writePhotoConnection_ = nil;
		[delegate_ tumblr:self writePhotoFinished:lastResponce_ withInfo:info];
	} else if (con == reblogConnection_) {
		[reblogConnection_ release];
		reblogConnection_ = nil;
		
		NSString *postID = [[[NSString alloc] initWithData:reblogRet encoding:NSUTF8StringEncoding] autorelease];
		if ([postID intValue] > 0 && ([[reblogingInfo objectForKey:@"Tags"] count] > 0 || [reblogingInfo objectForKey:@"Private"] != nil)) {
			//[self performSelector:@selector(reblogTagging:) withObject:postID afterDelay:0.0];
			[self reblogTagging:postID];
		} else {
			[reblogDelegate_ tumblr:self reblogFinished:0];
			[[StatusMessageViewController sharedInstance] showMessage:@"リブログしました"];
		}
	} else if (con == reblogTaggingConnection_) {
		[reblogTaggingConnection_ release];
		reblogTaggingConnection_ = nil;
		[reblogDelegate_ tumblr:self reblogFinished:0];
		[[StatusMessageViewController sharedInstance] showMessage:@"リブログしました"];
	} else if (con == likeConnection_) {
		[likeConnection_ release];
		likeConnection_ = nil;
		[likeDelegate_ tumblr:self likeFinished:0];
		[[StatusMessageViewController sharedInstance] showMessage:@"Likeしました"];
	} else if (con == deleteConnection_) {
		[deleteConnection_ release];
		deleteConnection_ = nil;
		[deleteDelegate_ tumblr:self deleteFinished:0];
		[[StatusMessageViewController sharedInstance] showMessage:@"削除しました"];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	if (connection == writePhotoConnection_) {
		if (totalBytesExpectedToWrite > 0) {
			DLog(@"tumblr write: %d", (int)(100.0 * totalBytesWritten / (float)totalBytesExpectedToWrite));
			[delegate_ tumblr:self writePhotoProgress:100.0 * totalBytesWritten / (float)totalBytesExpectedToWrite];
		}
	}
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return ([self.username length] > 0 && [self.password length] > 0);
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:self.username
                                                 password:self.password
                                              persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential
               forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

#pragma mark-

- (long) upload:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if (!UDBool(@"SaveToTumblr")) {
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
	
	NSMutableString *tags = [NSMutableString string];
	for (NSString *tag in [info objectForKey:@"Tags"]) {
		if ([tag length] > 0) {
			[tags appendString:tag];
		}
		if (tag != [[info objectForKey:@"Tags"] lastObject]) {
			[tags appendString:@","];
		}
	}

	NSData *data = [NSData dataWithContentsOfFile:[info objectForKey:@"Path"]];
	NSString *url = [info objectForKey:@"URL"];
	NSString *caption = [info objectForKey:@"Caption"];
	NSDictionary *postInfo = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"image/jpeg",	@"ContentType",
						  @"image.jpg",		@"Filename",
						  [info objectForKey:@"Private"],		@"Private",
						  caption,			@"Caption",
						  url,				@"URL",
						  tags,				@"Tags",
						  nil];
	
	[self writePhoto:data withInfo:postInfo handler:self];
	return 0;
}

- (void) uploadCancel {
	[self writePhotoCancel];
}

- (void) upload:(NSDictionary *)info {
	[[PostQueue evernoteQueue] pushObject:info toTarget:self action:@selector(upload:handler:) cancelAction:@selector(uploadCancel)];
}

#pragma mark-

- (void) bigURLDownloader:(BigURLDownloader *)sender finished:(NSError *)err {
	[urlDownloader autorelease];
	urlDownloader = nil;
	
	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Tumblr.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
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
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Tumblr.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.tag = 200;
		alert.object = sender.object;
		[alert show];
		
		[imageDownloadHandler post:self finished:0];
	} else {
		[self upload:sender.object handler:imageDownloadHandler];
	}	
	imageDownloadHandler = nil;
}

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
