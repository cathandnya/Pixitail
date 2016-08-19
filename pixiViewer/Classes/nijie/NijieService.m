//
//  NijieService.m
//  pixiViewer
//
//  Created by Naomoto nya on 12/06/23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NijieService.h"
#import "NijieLoginFormParser.h"
#import "ConstantsManager.h"
#import "ScrapingConstants.h"
#import "AccountManager.h"
#import "NijieAgeJumpParser.h"

@implementation NijieService

//- (NSTimeInterval) loginExpiredTimeInterval {
//	return 0;
//}

- (long) login:(id<PixServiceLoginHandler>)handler {
	if ([self.username length] == 0 || [self.password length] == 0) {			
		return -1;
	}
	if (!self.reachable) {
		return -2;
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *err = nil;
		NSURLResponse *res = nil;
		NSData *data = nil;
		NSMutableURLRequest *req;
		NSURL *url;
		NSString *str;
		
		// constants
		[[self constants] reloadSync];
		
		// logout
		str = [[self constants] valueForKeyPath:@"urls.logout"];
		if (str) {
			url = [NSURL URLWithString:str];
			req = [NSMutableURLRequest requestWithURL:url];
			[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
			data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
		}
		
		// login
		if (!err) {
			str = [[self constants] valueForKeyPath:@"urls.login"];
			if (str) {
				req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:str]];
				[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
				data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
				
				NSArray *comp = [str componentsSeparatedByString:@"/"];
				NSString *loginBase = [str substringToIndex:str.length - [comp.lastObject length]];
				
				if (!err) {
					NijieLoginFormParser *formParser = [[[NijieLoginFormParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
					
					NijieAgeJumpParser *ageParser = [[[NijieAgeJumpParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
					ageParser.urlPrefix = [[self constants] valueForKeyPath:@"constants.age_jump_prefix"];
					[ageParser addData:data];
					[ageParser addDataEnd];
					
					if (ageParser.url) {
						req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[loginBase stringByAppendingPathComponent:ageParser.url]]];
						[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
						data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
						
						if (!err) {
							[formParser addData:data];
							[formParser addDataEnd];
						}
					} else {
						[formParser addData:data];
						[formParser addDataEnd];
					}
					if (!err) {
						//[data writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"login.html"] atomically:YES];
						//DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF16BigEndianStringEncoding] autorelease]);
						
						if (formParser.action) {
							loginBase = [loginBase stringByAppendingString:formParser.action];
						}
						
						url = [NSURL URLWithString:loginBase];
						req = [NSMutableURLRequest requestWithURL:url];
						[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
						
						NSMutableString *formBodyString = [NSMutableString string];
						str = [[self constants] valueForKeyPath:@"constants.login_param"];
						[formBodyString appendFormat:str, encodeURIComponent(self.username), encodeURIComponent(self.password)];
						for (NSString *key in formParser.hiddenInputs) {
							[formBodyString appendFormat:@"&%@=%@", key, [formParser.hiddenInputs objectForKey:key]];
						}
						
						[req setHTTPMethod:@"POST"];
						[req setHTTPBody:[formBodyString dataUsingEncoding:NSUTF8StringEncoding]];
						
						data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
						if (!err) {
							NSString *failed = [[self constants] valueForKeyPath:@"constants.login_failed_str"];
							if (failed) {
								str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
								DLog(@"%@", str);
								if ([str rangeOfString:failed].location != NSNotFound) {
									err = [NSError errorWithDomain:@"" code:1 userInfo:nil];
								}
							}
						}
					} else {
						err = [NSError errorWithDomain:@"" code:2 userInfo:nil];
					}
				}
			}
		}
		
		[self loginFinished:err handler:handler];
	});
	return 0;
}

- (NSError *) addBookmarkSync:(NSDictionary *)info {
	NSString *url = [self.constants valueForKeyPath:@"urls.bookmark_add"];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setHTTPMethod:@"POST"];
	
	NSString *bodyString = [NSString stringWithFormat:@"id=%@&tag=", [info objectForKey:@"IllustID"]];
	[req setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
	[req setValue:[NSString stringWithFormat:@"http://nijie.info/bookmark.php?id=%@", [info objectForKey:@"IllustID"]] forHTTPHeaderField:@"Referer"];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	return err;
}

- (NSError *) addFavoriteUserSync:(NSDictionary *)info {
	NSString *url = [NSString stringWithFormat:[self.constants valueForKeyPath:@"urls.favorite_user_add"], [info objectForKey:@"UserID"]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	
	[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
	[req setValue:[NSString stringWithFormat:@"http://nijie.info/view.php?id=%@", [info objectForKey:@"IllustID"]] forHTTPHeaderField:@"Referer"];

	NSHTTPURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	DLog(@"%@", [[res allHeaderFields] description]);
	DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	return err;
}

- (NSString *) ratingFailedMessage {
	return @"抜くのに失敗しました";
}

- (NSString *) ratingMessage {
	return @"抜きました";
}

- (NSError *) ratingSync:(NSDictionary *)info {
	NSString *url = [NSString stringWithFormat:[self.constants valueForKeyPath:@"urls.rating"], [info objectForKey:@"IllustID"]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	
	[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
	[req setValue:[NSString stringWithFormat:@"http://nijie.info/view.php?id=%@", [info objectForKey:@"IllustID"]] forHTTPHeaderField:@"Referer"];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	return err;
}

#pragma mark-

#if 0
- (long) addFavoriteUser:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	//[favoriteUserAddingIDs addObject:[info objectForKey:@"UserID"]];

	NSString *url = [NSString stringWithFormat:[self.constants valueForKeyPath:@"urls.favorite_user_add"], [info objectForKey:@"UserID"]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

	[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
	[req setValue:[NSString stringWithFormat:@"http://nijie.info/view.php?id=%@", [info objectForKey:@"IllustID"]] forHTTPHeaderField:@"Referer"];
	
	NSURLConnection *con = [[[NSURLConnection alloc] initWithRequest:req delegate:self] autorelease];
	[con start];
	
	/*
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *err = [self addFavoriteUserSync:info];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			[favoriteUserAddingIDs removeObject:[info objectForKey:@"UserID"]];
			
			if (err) {
				UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@への追加に失敗しました", [self.constants valueForKeyPath:@"constants.favorite_user_title"]] message:[err localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
				[alert show];				
			} else {
				[[StatusMessageViewController sharedInstance] showMessage:[NSString stringWithFormat:@"%@へ追加しました", [self.constants valueForKeyPath:@"constants.favorite_user_title"]]];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"PixServiceBookmarkFinishedNotification" object:self userInfo:info];
			}
			
			[obj post:self finished:0];
		});	
	});
	 */
	return 0;
}
#endif

#pragma mark-

-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSHTTPURLResponse *)redirectResponse {
	DLog(@"redirect: %@", [[request URL] absoluteString]);
	if (0) {
		if ([[[request URL] absoluteString] isEqual:@"http://nijie.info/"]) {
			return nil;
		} else {
			return request;
		}		
	} else {
		return request;
	}
}

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
}

@end
