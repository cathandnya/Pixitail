//
//  ScrapingService.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingService.h"
#import "ConstantsManager.h"
#import "AccountManager.h"
#import "ScrapingConstants.h"
#import "AccountManager.h"
#import "StatusMessageViewController.h"


@implementation ScrapingService

@synthesize serviceName, constants;
@dynamic ratingIsEnabled, commentIsEnabled, favoriteUserIsEnabled, bookmarkIsEnabled;

+ (ScrapingService *) serviceFromName:(NSString *)name {
	static NSMutableDictionary *services = nil;
	if (!services) {
		services = [[NSMutableDictionary alloc] init];
	}
	ScrapingService *service = [services objectForKey:name];
	if (!service) {
		NSDictionary *info = [PixAccount serviceWithName:name];
		
		Class class = NSClassFromString([NSString stringWithFormat:@"%@Service", name]);
		if (!class) {
			class = [ScrapingService class];
		}
		service = [[[class alloc] init] autorelease];
		service.serviceName = name;

		ScrapingConstants *c = [[[ScrapingConstants alloc] initWithInfo:info] autorelease];
		service.constants = c;
		
		[services setObject:service forKey:name];
	}
	return service;
}

- (id) init {
	self = [super init];
	if (self) {
		favoriteUserAddingIDs = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	self.serviceName = nil;
	self.constants = nil;
	[favoriteUserAddingIDs release];
	[super dealloc];
}

- (NSString *) hostName {
	return [self.constants valueForKeyPath:@"urls.host"];
}

- (NSTimeInterval) loginExpiredTimeInterval {
	if ([self.constants valueForKeyPath:@"constants.expired_seconds"]) {
		return [[self.constants valueForKeyPath:@"constants.expired_seconds"] doubleValue];
	} else {
		return DBL_MAX;
	}
}

- (long) allertReachability {
	return 0;
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
		[[self constants] reloadSync];
		
		// logout
		if ([[AccountManager sharedInstance] accountsForServiceName:self.serviceName].count > 1) {
			str = [[self constants] valueForKeyPath:@"urls.logout"];
			if (str) {
				url = [NSURL URLWithString:str];
				req = [NSMutableURLRequest requestWithURL:url];
				data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
			}
		}
		
		// login
		if (!err) {
			str = [[self constants] valueForKeyPath:@"urls.login"];
			if (str) {
				url = [NSURL URLWithString:str];
				req = [NSMutableURLRequest requestWithURL:url];
				
				str = [[self constants] valueForKeyPath:@"constants.login_param"];
				body = [NSString stringWithFormat:str, encodeURIComponent(self.username), encodeURIComponent(self.password)];
				[req setHTTPMethod:@"POST"];
				[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
				
				data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
				if (!err) {
					NSString *failed = [[self constants] valueForKeyPath:@"constants.login_failed_str"];
					if (failed) {
						str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
						if ([str rangeOfString:failed].location != NSNotFound) {
							err = [NSError errorWithDomain:@"" code:1 userInfo:nil];
						}
					}
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

#pragma mark-

- (BOOL) ratingIsEnabled {
	return [[self.constants valueForKeyPath:@"constants.rating_is_enabled"] boolValue];
}

- (BOOL) commentIsEnabled {
	return [[self.constants valueForKeyPath:@"constants.comment_is_enabled"] boolValue];
}

- (BOOL) bookmarkIsEnabled {
	return [[self.constants valueForKeyPath:@"constants.bookmark_is_enabled"] boolValue];
}

- (BOOL) favoriteUserIsEnabled {
	return [[self.constants valueForKeyPath:@"constants.favorite_user_is_enabled"] boolValue];
}

#pragma mark-

- (NSError *) addBookmarkSync:(NSDictionary *)info {
	return nil;
}

- (NSError *) addFavoriteUserSync:(NSDictionary *)info {
	return nil;
}

- (NSError *) commentSync:(NSDictionary *)info {
	return nil;
}

- (NSError *) ratingSync:(NSDictionary *)info {
	return nil;
}

#pragma mark-

- (BOOL) isFavoritingUser:(NSString *)userID {
	return [favoriteUserAddingIDs containsObject:userID];
}

- (long) addBookmark:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[bookmarkAddingIDs addObject:[info objectForKey:@"IllustID"]];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *err = [self addBookmarkSync:info];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			[bookmarkAddingIDs removeObject:[info objectForKey:@"IllustID"]];
			
			if (err) {
				UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@への追加に失敗しました", [self.constants valueForKeyPath:@"constants.bookmark_title"]] message:[err localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
				[alert show];				
			} else {
				[[StatusMessageViewController sharedInstance] showMessage:[NSString stringWithFormat:@"%@へ追加しました", [self.constants valueForKeyPath:@"constants.bookmark_title"]]];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"PixServiceBookmarkFinishedNotification" object:self userInfo:info];
			}
			
			[obj post:self finished:0];
		});	
	});
	return 0;
}

- (long) addFavoriteUser:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[favoriteUserAddingIDs addObject:[info objectForKey:@"UserID"]];
	
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
	return 0;
}

- (long) comment:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[commentingIDs addObject:[info objectForKey:@"IllustID"]];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *err = [self commentSync:info];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			[commentingIDs removeObject:[info objectForKey:@"IllustID"]];
			
			if (err) {
				UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@に失敗しました", [self.constants valueForKeyPath:@"constants.comment_title"]] message:[err localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
				[alert show];				
			} else {
				[[StatusMessageViewController sharedInstance] showMessage:[NSString stringWithFormat:@"%@しました", [self.constants valueForKeyPath:@"constants.comment_title"]]];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"PixServiceCommentFinishedNotification" object:self userInfo:info];
			}
			
			[obj post:self finished:0];
		});	
	});
	return 0;
}

- (NSString *) ratingFailedMessage {
	return [NSString stringWithFormat:@"%@に失敗しました", [self.constants valueForKeyPath:@"constants.rating_title"]];
}

- (NSString *) ratingMessage {
	return [NSString stringWithFormat:@"%@しました", [self.constants valueForKeyPath:@"constants.rating_title"]];
}

- (long) rating:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[ratingIDs addObject:[info objectForKey:@"IllustID"]];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *err = [self ratingSync:info];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			[ratingIDs removeObject:[info objectForKey:@"IllustID"]];
			
			if (err) {
				UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[self ratingFailedMessage] message:[err localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
				[alert show];				
			} else {
				[[StatusMessageViewController sharedInstance] showMessage:[self ratingMessage]];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"PixServiceBookmarkFinishedNotification" object:self userInfo:info];
			}
			
			[obj post:self finished:0];
		});	
	});
	return 0;
}

#pragma mark-

- (void) addToBookmark:(NSDictionary *)info {
	if (![self isBookmarking:[info objectForKey:@"IllustID"]]) {
		[[PostQueue sharedInstance] pushObject:info toTarget:self action:@selector(addBookmark:handler:) cancelAction:@selector(addToBookmarkCancel)];
	}
}

- (long) addToBookmarkCancel {
	return 0;
}

- (void) addToFavoriteUser:(NSDictionary *)info {
	if (![self isBookmarking:[info objectForKey:@"UserID"]]) {
		[[PostQueue sharedInstance] pushObject:info toTarget:self action:@selector(addFavoriteUser:handler:) cancelAction:@selector(addToBookmarkCancel)];
	}
}

- (void) rating:(NSInteger)val withInfo:(NSDictionary *)info {
	if (![self isRating:[info objectForKey:@"IllustID"]]) {
		NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:info];
		[mdic setObject:[NSNumber numberWithInteger:val] forKey:@"RatingValue"];
		[[PostQueue sharedInstance] pushObject:mdic toTarget:self action:@selector(rating:handler:) cancelAction:@selector(ratingCancel)];	
	}
}

- (void) ratingCancel {
}

- (void) comment:(NSString *)str withInfo:(NSDictionary *)info {
	if (![self isCommenting:[info objectForKey:@"IllustID"]]) {
		NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:info];
		[mdic setObject:str forKey:@"CommentValue"];
		[[PostQueue sharedInstance] pushObject:mdic toTarget:self action:@selector(comment:handler:) cancelAction:@selector(commentCancel)];	
	}
}

- (void) commentCancel {
}

@end
