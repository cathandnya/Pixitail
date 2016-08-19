//
//  Tumblog.h
//  Tumbltail
//
//  Created by nya on 10/09/21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "Blog.h"


@interface Tumblog :  Blog  {
	NSString *accountName;
	NSNumber *following;
}

@property(readwrite, nonatomic, retain) NSString *accountName;
@property(readwrite, nonatomic, retain) NSNumber *following;
	
- (id) initWithPost:(NSDictionary *)dic;
- (id) initWithInfo:(NSDictionary *)dic;
- (NSMutableDictionary *) info;

- (void) setName:(NSString *)str;
- (void) setUrl:(NSString *)str;

@end



