//
//  Tumblr.h
//  pixiViewer
//
//  Created by nya on 09/12/12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PostQueue.h"


//#define USE_XAUTH


@class OAConsumer;
@class BigURLDownloader;
@class ImageDownloader;


@interface Tumblr : NSObject {
	Reachability *_reachability;
	BOOL reachable;

	BigURLDownloader *urlDownloader;
	id urlDownloadHandler;
	ImageDownloader *imageDownloader;
	id imageDownloadHandler;
}

@property(nonatomic, readwrite, assign) BOOL reachable;
@property(readonly, nonatomic, retain) OAConsumer *consumer;

+ (Tumblr *) sharedInstance;

- (void) uploadPhoto:(NSDictionary *)dic block:(void (^)(NSError *))completionBlock;
- (void) upload:(NSDictionary *)info;

@end


//NSString *encodeURIComponent(NSString *string);
