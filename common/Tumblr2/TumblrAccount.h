//
//  TumblrAccount.h
//  Tumbltail
//
//  Created by nya on 11/09/19.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginUserBlog.h"


@class OAToken;
@class UserInfoRequest;

@interface TumblrAccount : NSObject {
	NSString *userID;
	OAToken *token;
	NSDictionary *userInfo;
	UserInfoRequest *request;
}

@property(retain, nonatomic, readwrite) NSString *userID;
@property(retain, nonatomic, readwrite) OAToken *token;
@property(retain, nonatomic, readwrite) NSDictionary *userInfo;

@property(assign, nonatomic, readonly) NSString *name;
@property(assign, nonatomic, readonly) NSArray *blogs;
@property(assign, nonatomic, readonly) LoginUserBlog *primaryBlog;
@property(assign, nonatomic, readonly) int followingCount;

- (id) initWithInfo:(NSDictionary *)info;
- (NSDictionary *)info;

- (void) load;
- (void) cancel;

@end
