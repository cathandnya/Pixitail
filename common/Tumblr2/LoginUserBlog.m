//
//  LoginUserBlog.m
//  Tumbltail
//
//  Created by nya on 11/09/20.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "LoginUserBlog.h"

@implementation LoginUserBlog

@dynamic isPrimary;

- (BOOL) isPrimary {
	return [[self valueForKey:@"primary"] boolValue];
}

@end
