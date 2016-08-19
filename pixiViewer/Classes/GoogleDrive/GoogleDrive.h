//
//  GoogleDrive.h
//
//  Created by Naomoto nya on 12/07/08.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class GTMOAuth2Authentication;
@class BigURLDownloader;
@class ImageDownloader;


@interface GoogleDrive : NSObject {
	BigURLDownloader *urlDownloader;
	id urlDownloadHandler;
	ImageDownloader *imageDownloader;
	id imageDownloadHandler;
}

@property(readwrite, nonatomic, retain) GTMOAuth2Authentication *auth;
@property(readonly, nonatomic, assign) BOOL available;
@property(readonly, nonatomic, assign) NSString *username;

+ (GoogleDrive *) sharedInstance;

// - (void) googleAuthFinished:(GoogleDrive *)sender error:(NSError *)err;
- (UIViewController *) authViewControllerWithDelegate:(id)del;
- (void) logout;

- (void) upload:(NSDictionary *)info;

@end
