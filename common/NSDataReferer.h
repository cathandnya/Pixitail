//
//  NSDataReferer.h
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData(Referer)
+ (id) dataWithContentsOfURL:(NSURL *)url fromReferer:(NSString *)ref;
+ (id) dataWithContentsOfURL:(NSURL *)url fromReferer:(NSString *)ref timeout:(NSTimeInterval)ti;
@end

