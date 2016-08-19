//
//  Blog.h
//  Tumbltail
//
//  Created by nya on 11/09/19.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JsonObject.h"


@class BlogInfoRequest;


@interface Blog : JsonObject {
	BlogInfoRequest *request;
}

@property(readonly, nonatomic, assign) NSString *title;
@property(readonly, nonatomic, assign) NSString *name;
@property(readonly, nonatomic, assign) NSString *url;
@property(readonly, nonatomic, assign) NSString *hostName;
@property(readonly, nonatomic, assign) NSString *avatarURL;

@property(readonly, nonatomic, assign) BOOL needsLoad;

- (void) load;
- (void) cancel;
- (BOOL) isLoading;

@end


