//
//  DropBox.h
//  Tumbltail
//
//  Created by nya on 10/11/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBSession.h"
#import "DBRestClient.h"
#import "PostQueue.h"


#define ESCAPE_CHARS		@"\\/*?|<>:,;'\"　"


@interface DropBox : NSObject<DBRestClientDelegate> {
	DBRestClient *restClient;
	id<PostQueueTargetHandlerProtocol> uploadHandler;
	void (^linkFinishedBlock)(NSURL *);
}

- (void) link:(UIViewController *)vc completionBlock:(void (^)(NSURL *))block;
- (void) unlink;
- (void) handleOpenURL:(NSURL *)url completionBlock:(void (^)(NSError *))block;
- (BOOL) linked;

- (void) upload:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj;
- (void) uploadCancel;

- (UIViewController *) currentViewController;

@end
