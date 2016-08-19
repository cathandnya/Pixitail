//
//  EvernoteTail.h
//  Tumbltail
//
//  Created by nya on 10/11/26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Evernote.h"
#import "PostQueue.h"
#import "EvernoteSession.h"


@class BigURLDownloader;
@class ImageDownloader;


@interface EvernoteTail : Evernote<UIAlertViewDelegate> {
	id<PostQueueTargetHandlerProtocol> uploadHandler;
	NSDictionary *uploadingInfo;

	BigURLDownloader *urlDownloader;
	id urlDownloadHandler;
	ImageDownloader *imageDownloader;
	id imageDownloadHandler;
}

+ (EvernoteTail *) sharedInstance;

- (void) upload:(NSDictionary *)info;

@end
