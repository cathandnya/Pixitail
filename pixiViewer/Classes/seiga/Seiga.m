//
//  Seiga.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/22.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "Seiga.h"
#import "SeigaConstants.h"
#import "AccountManager.h"


@implementation Seiga

+ (Seiga *) sharedInstance {
	static Seiga *obj = nil;
	if (obj == nil) {
		obj = [[Seiga alloc] init];
	}
	return obj;
}

- (NSString *) hostName {
	return @"seiga.nicovideo.jp";
}

- (long) allertReachability {
	return 0;
}

- (NSTimeInterval) loginExpiredTimeInterval {
	if ([[SeigaConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"]) {
		return [[[SeigaConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"] doubleValue];
	} else {
		return DBL_MAX;
	}
}

- (void) loginFinished:(id)obj handler:(id<PixServiceLoginHandler>)handler {
	dispatch_async(dispatch_get_main_queue(), ^{
		[handler pixService:self loginFinished:[obj code]];
	});	
}

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
		NSString *body;
		NSString *str;
		
		// constants
		[[SeigaConstants sharedInstance] reloadSync];
		
		// logout
		if ([[AccountManager sharedInstance] accountsForServiceName:@"Seiga"].count > 1) {
			url = [NSURL URLWithString:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.logout"]];
			req = [NSMutableURLRequest requestWithURL:url];
			data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
		}
		if (!err) {
			// login
			url = [NSURL URLWithString:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.login"]];
			req = [NSMutableURLRequest requestWithURL:url];
			
			body = [NSString stringWithFormat:@"mail=%@&password=%@&next_url=%@", encodeURIComponent(self.username), encodeURIComponent(self.password), encodeURIComponent(@"/")];
			[req setHTTPMethod:@"POST"];
			[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
			
			data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
			if (!err) {
				str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
				if ([str rangeOfString:[[SeigaConstants sharedInstance] valueForKeyPath:@"constants.login_failed_str"]].location != NSNotFound) {
					err = [NSError errorWithDomain:@"" code:1 userInfo:nil];
				}
				if (!err) {
					// 春画用
					url = [NSURL URLWithString:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.shunga_submit"]];
					req = [NSMutableURLRequest requestWithURL:url];
					[req setHTTPMethod:@"POST"];
					[req setHTTPBody:[[[SeigaConstants sharedInstance] valueForKeyPath:@"constants.shunga_submit_param"] dataUsingEncoding:NSASCIIStringEncoding]];
					data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
					err = nil;		// 無視
					//DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
				}
			}
		}
		
		[self loginFinished:err handler:handler];
	});
	return 0;
}

- (long) loginCancel {
	return 1;
}

@end
