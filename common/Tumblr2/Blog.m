//
//  Blog.m
//  Tumbltail
//
//  Created by nya on 11/09/19.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "Blog.h"
#import "Requests.h"


@implementation Blog

@dynamic name, title, url, hostName, avatarURL, needsLoad;

- (id) init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) dealloc {
	[self cancel];
	[super dealloc];
}

- (BOOL) isEqual:(id)object {
	if ([object isKindOfClass:[Blog class]]) {
		return [self.name isEqual:((Blog *)object).name];
	} else {
		return NO;
	}
}

- (NSString *) name {
	return [self valueForKey:@"name"];
}

- (NSString *) title {
	return [self valueForKey:@"title"];
}

- (NSString *) url {
	NSString *str = [self valueForKey:@"url"];
	if (!str) {
		str = [NSString stringWithFormat:@"http://%@.tumblr.com/", self.name];
	}
	return str;
}

- (NSString *) hostName {
	NSURL *u = [NSURL URLWithString:self.url];
	return u.host;
}

- (NSString *) avatarURL {
	return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/avatar/128", self.hostName];
}

#pragma mark-

- (void) load {
	if (!request) {
		request = [[BlogInfoRequest alloc] init];
		request.delegate = self;
		request.blogHostName = self.hostName;
		[request start];
	}
}

- (void) cancel {
	[request cancel];
	[request release];
	request = nil;
}

- (BOOL) needsLoad {
	return [self valueForKey:@"posts"] == nil;
}

- (BOOL) isLoading {
	return request != nil;
}

- (void) blogInfoRequest:(id)sender finished:(NSDictionary *)dic {
	if (![dic objectForKey:@"Error"]) {
		NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:json];
		[mdic addEntriesFromDictionary:[dic valueForKeyPath:@"Result.blog"]];
		[json release];
		json = [mdic retain];
	}
	
	[self cancel];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogUpdatedNotification" object:self userInfo:dic];
}

@end


