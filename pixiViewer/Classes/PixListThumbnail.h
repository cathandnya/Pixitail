//
//  PixListThumbnail.h
//  pixiViewer
//
//  Created by nya on 09/10/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class PixAccount;

@interface PixListThumbnail : NSObject {
	NSMutableDictionary	*thumbnail_;
	NSString *name;
}

+ (PixListThumbnail *) sharedInstance;
- (UIImage *) imageWithMethod:(NSString *)method;
- (id) initWithAccount:(PixAccount *)acc;

@end
