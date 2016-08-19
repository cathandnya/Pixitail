//
//  Danbooru.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "Danbooru.h"
#import "AccountManager.h"
#import <CommonCrypto/CommonDigest.h>


@implementation Danbooru

@synthesize account;

+ (NSString *)sha1:(NSString *)inputString {
    const char *str = [inputString UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(str, (int)strlen(str), result);
    return [NSString 
            stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15],
            result[16], result[17], result[18], result[19]];
}

+ (NSString *) hashedPassword:(NSString *)pass {
	NSString *str = [NSString stringWithFormat:@"choujin-steiner--%@--", pass];
	return [[self class] sha1:str];
}

+ (Danbooru *) sharedInstance {
	static Danbooru *obj =nil;
	if (obj == nil) {
		obj = [[Danbooru alloc] init];
	}
	return obj;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) dealloc {
	self.account = nil;
	[super dealloc];
}

- (long) allertReachability {
	return 0;
}

- (BOOL) needsLogin {
	return NO;
}

- (BOOL) hasExpireDate {
	return NO;
}

@end
