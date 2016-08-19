//
//  DanbooruTagBookmarkViewController.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DanbooruTagBookmarkViewController.h"
#import "DanbooruMatrixViewController.h"
#import "Danbooru.h"
#import "AccountManager.h"

@implementation DanbooruTagBookmarkViewController

- (NSString *) saveName {
	return @"SavedTagsDanbooru";
}

- (Class) matrixClass {
	return [DanbooruMatrixViewController class];
}

- (NSString *) methodWithTag:(NSString *)tag {
	NSData				*data = [tag dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*method = [NSMutableString stringWithFormat:@"http://%@/post/index.json?tags=", account.hostname];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[method appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	[method appendString:@"&"];
	
	return method;
}

@end
