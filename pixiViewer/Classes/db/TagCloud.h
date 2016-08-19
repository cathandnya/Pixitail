//
//  TagCloud.h
//  pixiViewer
//
//  Created by nya on 10/05/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TagCloud : NSObject {
	
}

+ (TagCloud *) sharedInstance;

- (void) add:(NSString *)tag forType:(NSString *)type user:(NSString *)user;
- (void) remove:(NSString *)tag forType:(NSString *)type user:(NSString *)user;
- (void) cleanTagsForType:(NSString *)type user:(NSString *)user;
- (NSArray *) tagsForType:(NSString *)type user:(NSString *)user;

@end
