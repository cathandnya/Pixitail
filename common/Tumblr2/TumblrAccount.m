//
//  TumblrAccount.m
//  Tumbltail
//
//  Created by nya on 11/09/19.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "TumblrAccount.h"
#import "OAToken.h"
#import "Requests.h"
#import "Blog.h"


@implementation TumblrAccount

@synthesize userID, token, userInfo;
@dynamic name, blogs, primaryBlog, followingCount;

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) dealloc {
	[self cancel];
	self.userID = nil;
	self.token = nil;
	self.userInfo = nil;
	[super dealloc];
}

- (BOOL) isEqual:(id)other {
	if ([other isKindOfClass:[self class]]) {
		return [self.userID isEqual:((TumblrAccount *)other).userID];
	} else {
		return NO;
	}
}

- (id) initWithInfo:(NSDictionary *)info {
	self = [super init];
	if (self) {
		id obj, obj1;
		
		obj = [info objectForKey:@"TokenKey"];
		obj1 = [info objectForKey:@"TokenSecret"];
		if (obj && obj1) {
			self.token = [[[OAToken alloc] initWithKey:obj secret:obj1] autorelease];
		} else {
			[self release];
			return nil;
		}
		
		obj = [info objectForKey:@"UserID"];
		self.userID = obj;
		obj = [info objectForKey:@"UserInfo"];
		self.userInfo = obj;
	}
	return self;
}

- (NSDictionary *)info {
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	
	if (self.token) {
		[ret setObject:token.key forKey:@"TokenKey"];
		[ret setObject:token.secret forKey:@"TokenSecret"];
	}
	if (self.userID) {
		[ret setObject:self.userID forKey:@"UserID"];
	}
	if (self.userInfo) {
		[ret setObject:self.userInfo forKey:@"UserInfo"];
	}

	return ret;
}

#pragma mark-

- (void) load {
	if (request) {
		return;
	}
	
	request = [[UserInfoRequest alloc] init];
	request.token = self.token;
	request.delegate = self;
	[request start];
}

- (void) cancel {
	request.delegate = nil;
	[request cancel];
	[request autorelease];
	request = nil;
}

- (void) userInfoRequest:(id)sender finished:(id)ret {
	if ([ret isKindOfClass:[NSDictionary class]] && [ret objectForKey:@"Result"]) {
		self.userInfo = [ret objectForKey:@"Result"];
	}
	[self cancel];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrAccountUserInfoLoadedNotification" object:self userInfo:nil];
}

- (void) userInfoRequest:(id)sender failed:(NSError *)err {
	[self cancel];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrAccountUserInfoLoadedNotification" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:err, @"Error", nil]];
}

#pragma mark-

- (NSString *) name {
	return [userInfo valueForKeyPath:@"user.name"];
}

- (NSArray *) blogs {
	NSArray *ary = [userInfo valueForKeyPath:@"user.blogs"];
	NSMutableArray *mary = [NSMutableArray array];
	for (NSDictionary *d in ary) {
		[mary addObject:[[[LoginUserBlog alloc] initWithJson:d] autorelease]];
	}
	return mary;
}

- (LoginUserBlog *) primaryBlog {
	for (LoginUserBlog *b in self.blogs) {
		if (b.isPrimary) {
			return b;
		}
	}
	return nil;
}

- (int) followingCount {
	return [[userInfo valueForKeyPath:@"user.following"] intValue];
}

@end
