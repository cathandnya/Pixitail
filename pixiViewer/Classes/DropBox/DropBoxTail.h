//
//  DropBoxTail.h
//  Tumbltail
//
//  Created by nya on 10/11/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DropBox.h"


@class BigURLDownloader;
@class ImageDownloader;
@interface DropBoxTail : DropBox<UIAlertViewDelegate> {
	NSDictionary *uploadingInfo;
	
	BigURLDownloader *urlDownloader;
	id urlDownloadHandler;
	ImageDownloader *imageDownloader;
	id imageDownloadHandler;
}

+ (DropBoxTail *) sharedInstance;

- (void) upload:(NSDictionary *)info;

@end
