//
//  CHURLImageLoader.h
//  pixiViewer
//
//  Created by nya on 09/12/21.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class CHURLImageLoader;
@protocol CHURLImageLoaderDelegate
- (void) loader:(CHURLImageLoader *)loader progress:(NSInteger)percent;
- (void) loader:(CHURLImageLoader *)loader finished:(NSData *)data;
@end


@interface CHURLImageLoader : NSObject {
	NSURLConnection		*imageConnection_;
	NSMutableData		*imageData_;
	long long			imageDataLength_;
	
	int retryCount;
	NSURL *url;
	NSString *referer;
	id object;
	id<CHURLImageLoaderDelegate> delegate;

	NSInteger percent;
}

@property(readwrite, nonatomic, assign) int retryCount;
@property(readwrite, nonatomic, retain) NSURL *url;
@property(readwrite, nonatomic, retain) NSString *referer;
@property(readwrite, nonatomic, retain) id object;
@property(readwrite, nonatomic, assign) id<CHURLImageLoaderDelegate> delegate;
@property(readonly, nonatomic, assign) NSInteger percent;

- (void) load;
- (void) cancel;

- (CHURLImageLoader *) copy;

@end
