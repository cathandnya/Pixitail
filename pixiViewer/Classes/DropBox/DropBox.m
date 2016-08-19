//
//  DropBox.m
//  Tumbltail
//
//  Created by nya on 10/11/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DropBox.h"
#import "UserDefaults.h"
#import "DropboxCustom.h"


@implementation DropBox

- (void) upload:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	NSString *local = [info objectForKey:@"LocalPath"]; 
	NSString *server = [info objectForKey:@"ServerPath"]; 
	NSString *name = [info objectForKey:@"Name"]; 

	NSString *replacement = ESCAPE_CHARS;
	for (int i = 0; i < replacement.length; i++) {
		NSString *s = [replacement substringWithRange:NSMakeRange(i, 1)];
		name = [name stringByReplacingOccurrencesOfString:s withString:@"#"];
	}
	
	if (!restClient) {
		restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		restClient.delegate = self;
	}
	
	uploadHandler = obj;
	[restClient uploadFile:name toPath:server withParentRev:nil fromPath:local];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
}

- (void) uploadCancel {
	if (uploadHandler) {
		uploadHandler = nil;
		restClient.delegate = nil;
		
		[restClient autorelease];
		restClient = nil;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	}
}

#pragma mark-

- (NSString *) consumerKey {
	assert(0);
	return nil;
}

- (NSString *) consumerSecret {
	assert(0);
	return nil;
}

- (UIViewController *) currentViewController {
	assert(0);
	return nil;
}

- (void) link:(UIViewController *)vc completionBlock:(void (^)(NSURL *))block {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(linkFinished:) name:@"DBConnectControllerCustomOpenURL" object:nil];
	linkFinishedBlock = Block_copy(block);
	[[DBSession sharedSession] linkFromController:vc];
}

- (void) linkFinished:(NSNotification *) notif {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DBConnectControllerCustomOpenURL" object:nil];
	linkFinishedBlock([[notif userInfo] objectForKey:@"URL"]);
	Block_release(linkFinishedBlock);
}

- (void) unlink {
	[[DBSession sharedSession] unlinkAll];
	[restClient release];
	restClient = nil;
}

- (void) handleOpenURL:(NSURL *)url completionBlock:(void (^)(NSError *))block {
	NSString *uid = [(DBSessionCustom *)[DBSession sharedSession] handleOpenURLReturningUserID:url];
	if (uid.length > 0) {
		block(nil);
	} else if (uid != nil) {
		block([NSError errorWithDomain:NSStringFromClass([self class]) code:-2 userInfo:nil]);
	} else {
		block([NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil]);
	}
}

- (BOOL) linked {
	return [[DBSession sharedSession] isLinked];
}

#pragma mark-

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	[uploadHandler post:self finished:0];
	uploadHandler = nil;
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath {

}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	if (error) {
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to Dropbox.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
	}
	[uploadHandler post:self finished:0];
	uploadHandler = nil;
}

@end
