//
//  CHURLUtil.h
//  Echo
//
//  Created by Naomoto nya on 12/05/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(CHURLUtil)

- (NSString *) urlEncode;
+ (NSString *) stringWithURLParameter:(NSDictionary *)dic;
+ (NSString *) stringWithURL:(NSString *)urlStr withParameter:(NSDictionary *)dic;

@end

@interface NSData(CHURLUtil)

+ (NSData *) multipartBodyData:(NSDictionary *)dic boundary:(NSString *)boundary;
+ (NSData *) multipartBodyData:(NSDictionary *)dic;
+ (NSString *) multipartBoundary;

@end
