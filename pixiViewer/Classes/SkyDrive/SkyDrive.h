//
//  SkyDrive.h
//  pixiViewer
//
//  Created by Naomoto nya on 12/07/13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveAuthDelegate.h"
#import "LiveOperationDelegate.h"
#import "LiveUploadOperationDelegate.h"


@class LiveConnectClient;
@class SkyDrive;
@class LiveOperation;
@class BigURLDownloader;
@class ImageDownloader;


@protocol SkyDriveLoginHandler <NSObject>
- (void) skyDrive:(SkyDrive *)sender loginFinished:(NSError *)err;
@end


@interface SkyDrive : NSObject<LiveAuthDelegate, LiveOperationDelegate, LiveUploadOperationDelegate> {
	LiveConnectClient *client;
	id<SkyDriveLoginHandler> loginDelegate;
	
	LiveOperation *listOperation;
	LiveOperation *createAlbumOperation;
	LiveOperation *getAlbumInfoOperation;
	LiveOperation *uploadOperation;
	
	BigURLDownloader *urlDownloader;
	id urlDownloadHandler;
	ImageDownloader *imageDownloader;
	id imageDownloadHandler;
	
	id postQueue;
	id uploadingInfo;
	
	int state;
	NSData *upData;
	NSString *upName;
}

@property(readonly, nonatomic, assign) BOOL available;

+ (SkyDrive *) sharedInstance;

- (void) login:(UIViewController *)viewController withDelegate:(id<SkyDriveLoginHandler>)del;
- (void) logout;

- (void) upload:(NSDictionary *)info;

@end
