// 
//  Tumblog.m
//  Tumbltail
//
//  Created by nya on 10/09/21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Tumblog.h"


@implementation Tumblog 

@synthesize accountName, following;

- (id) initWithPost:(NSDictionary *)dic {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
	id obj;
	
	obj = [dic objectForKey:@"blog_name"];
	if (obj) {
		[mdic setObject:obj forKey:@"name"];
	}
	obj = [dic objectForKey:@"post_url"];
	if (obj) {
		NSURL *u = [NSURL URLWithString:obj];
		[mdic setObject:[NSString stringWithFormat:@"http://%@/", u.host] forKey:@"url"];
	}
	
	self = [super initWithJson:mdic];
	if (self) {
	}
	return self;
}

- (id) initWithInfo:(NSDictionary *)dic {
	self = [super initWithJson:dic];
	if (self) {
		self.accountName = [dic objectForKey:@"accountName"];
	}
	return self;
}

- (void) dealloc {
	self.accountName = nil;
	self.following = nil;
	[super dealloc];
}

- (NSMutableDictionary *) info {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:json];
	if (self.accountName) [mdic setObject:self.accountName forKey:@"accountName"];
	return mdic;
}

- (void) setName:(NSString *)str {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:json];
	if (str) [mdic setObject:str forKey:@"name"];
	[json release];
	json = [mdic retain];
}

- (void) setUrl:(NSString *)str {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:json];
	if (str) [mdic setObject:str forKey:@"url"];
	[json release];
	json = [mdic retain];
}

@end
