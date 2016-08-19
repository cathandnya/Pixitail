//
//  SugarSync.h
//
//  Created by Naomoto nya on 12/07/06.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BigURLDownloader;
@class ImageDownloader;

@interface SugarSync : NSObject<UIAlertViewDelegate> {
	BigURLDownloader *urlDownloader;
	id urlDownloadHandler;
	ImageDownloader *imageDownloader;
	id imageDownloadHandler;
}

@property(readonly, nonatomic, assign) NSString *username;
@property(readonly, nonatomic, assign) BOOL hasAccount;

+ (SugarSync *) sharedInstance;

- (void) loginWithUsername:(NSString *)username password:(NSString *)password block:(void (^)(NSError *))completionBlock;
- (void) logout;

- (void) upload:(NSDictionary *)info;

@end
