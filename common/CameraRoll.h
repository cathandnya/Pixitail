//
//  CameraRoll.h
//  pixiViewer
//
//  Created by nya on 11/01/19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PostQueue.h"


@class BigURLDownloader;
@class ImageDownloader;
@interface CameraRoll : NSObject<UIAlertViewDelegate> {
	NSDictionary *saveInfo;
	BigURLDownloader *urlDownloader;
	ImageDownloader *imageDownloader;
	
	id<PostQueueTargetHandlerProtocol> postHandler;
}

+ (CameraRoll *) sharedInstance;

- (void) save:(NSDictionary *)info;
- (void) cancel;

@end
