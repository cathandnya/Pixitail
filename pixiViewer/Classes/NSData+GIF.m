//
//  NSData+GIF.m
//  Tumbltail
//
//  Created by nya on 2013/11/02.
//
//

#import "NSData+GIF.h"

@implementation NSData(GIF)

- (BOOL) isGIF {
	char *bytes = (char *)[self bytes];
	return [self length] >= 6 && (strncmp(bytes, "GIF87a", 6) == 0 || strncmp(bytes, "GIF89a", 6) == 0);
}

@end
