//
//  fgService.m
//  pixiViewer
//
//  Created by Naomoto nya on 12/01/04.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import "fgService.h"
#import "ScrapingConstants.h"


@implementation fgService

- (NSError *) addBookmarkSync:(NSDictionary *)info {
	NSString *url = [NSString stringWithFormat:[self.constants valueForKeyPath:@"urls.bookmark_add"], [info objectForKey:@"IllustID"]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setHTTPMethod:@"POST"];
	
	NSString *bodyString = [self.constants valueForKeyPath:@"constants.bookmark_add_param"];
	[req setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	return err;
}

- (NSError *) addFavoriteUserSync:(NSDictionary *)info {
	NSString *url = [NSString stringWithFormat:[self.constants valueForKeyPath:@"urls.favorite_user_add"], [info objectForKey:@"UserID"]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setHTTPMethod:@"POST"];
	
	NSString *bodyString = [self.constants valueForKeyPath:@"constants.favorite_user_add_param"];
	[req setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	return err;
}

- (NSError *) commentSync:(NSDictionary *)info {
	NSString *url = [NSString stringWithFormat:[self.constants valueForKeyPath:@"urls.comment"], [info objectForKey:@"IllustID"]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setHTTPMethod:@"POST"];
	
	NSString *bodyString = [NSString stringWithFormat:[self.constants valueForKeyPath:@"constants.comment_param"], [info objectForKey:@"CommentValue"]];
	[req setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	return err;
}

- (NSError *) ratingSync:(NSDictionary *)info {
	NSString *url = [self.constants valueForKeyPath:@"urls.rating"];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setHTTPMethod:@"POST"];
	
	NSString *bodyString = [NSString stringWithFormat:[self.constants valueForKeyPath:@"constants.rating_param"], [info objectForKey:@"RatingValue"], [info objectForKey:@"UserID"], [info objectForKey:@"IllustID"]];
	[req setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	return err;
}

@end
