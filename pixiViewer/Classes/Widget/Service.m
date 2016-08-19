//
//  Service.m
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

#import "Service.h"

@implementation Service

@dynamic needsLogin;

+ (Service *) serviceWithName:(NSString *)n username:(NSString *)un password:(NSString *)pass {
	Class cls;
	if ([n isEqualToString:@"pixiv"]) {
		cls = NSClassFromString(@"PixivService");
	} else if ([n isEqualToString:@"TINAMI"]) {
		cls = NSClassFromString(@"TinamiService");
	} else {
		cls = NSClassFromString([n stringByAppendingString:@"Service"]);
	}
	Service *ret = [[cls alloc] initWithUsername:un password:pass];
	ret.name = n;
	return ret;
}

- (id) initWithUsername:(NSString *)un password:(NSString *)pass {
	self = [super init];
	if (self) {
		self.username = un;
		self.password = pass;
	}
	return self;
}


- (NSTimeInterval) loginExpiredTimeInterval {
	return DBL_MAX;
}

- (BOOL) needsLogin {
	if (self.loginDate) {
		return -[self.loginDate timeIntervalSinceNow] > [self loginExpiredTimeInterval] - 3 * 60;
	} else {
		return YES;
	}
}

- (NSError *) login {
	return nil;
}

- (PixivMatrixParser *) makeParser:(NSString *)key method:(NSString *)method {
	return nil;
}

- (CHHtmlParserConnection *) makeConnection:(NSString *)method page:(int)page {
	return nil;
}

@end


NSString* encodeURIComponent(NSString* s) {
	return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																(CFStringRef)s,
																NULL,
																(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																kCFStringEncodingUTF8));
}


