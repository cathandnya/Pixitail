//
//  Tumblr.h
//  pixiViewer
//
//  Created by nya on 09/12/12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixService.h"
#import "PostQueue.h"


//#define USE_TWITTER_API_DASHBOARD
@class ImageDownloader;
@class BigURLDownloader;


@class Tumblr;
@protocol TumblrDelegate
- (void) tumblr:(Tumblr *)sender writePhotoProgress:(int)percent;
- (void) tumblr:(Tumblr *)sender writePhotoFinished:(long)err withInfo:(NSDictionary *)info;
@end

@protocol TumblrReblogDelegate
- (void) tumblr:(Tumblr *)sender reblogFinished:(long)err;
@end

@protocol TumblrLikeDelegate
- (void) tumblr:(Tumblr *)sender likeFinished:(long)err;
@end

@protocol TumblrDeleteDelegate
- (void) tumblr:(Tumblr *)sender deleteFinished:(long)err;
@end



@interface Tumblr : PixService<TumblrDelegate, TumblrReblogDelegate> {
	NSURLConnection *writePhotoConnection_;
	id<TumblrDelegate> delegate_;
	int lastResponce_;
	NSString *name;

	NSURLConnection *reblogConnection_;
	id<TumblrReblogDelegate> reblogDelegate_;
	NSDictionary *reblogingInfo;
	NSURLConnection *reblogTaggingConnection_;
	NSMutableData *reblogRet;
	
	NSURLConnection *likeConnection_;
	id<TumblrLikeDelegate> likeDelegate_;

	NSURLConnection *deleteConnection_;
	id<TumblrDeleteDelegate> deleteDelegate_;
	
	NSMutableArray *writePhotoQueue_;
	NSMutableArray *reblogQueue_;

	id<PostQueueTargetHandlerProtocol> uploadHandler;
	NSDictionary *uploadingInfo;
	BigURLDownloader *urlDownloader;
	id urlDownloadHandler;
	ImageDownloader *imageDownloader;
	id imageDownloadHandler;
}

@property(readonly, assign, nonatomic) BOOL available;
@property(readonly, assign, nonatomic) BOOL sending;
@property(readwrite, nonatomic, retain) NSString *name;

+ (Tumblr *) instance;
+ (Tumblr *) sharedInstance;

- (void) setup;

//- (long) writePhoto:(NSData *)data withInfo:(NSDictionary *)info handler:(id<TumblrDelegate>)delegate;
- (void) writePhotoCancel;
- (void) writePhotoInBackground:(NSData *)data withInfo:(NSDictionary *)info;

- (long) reblog:(NSDictionary *)info handler:(id<TumblrReblogDelegate>)obj;
- (void) reblogInBackground:(NSDictionary *)info;
- (long) like:(NSDictionary *)info handler:(id<TumblrLikeDelegate>)obj;

- (long) reblogAPI:(NSDictionary *)info handler:(id<TumblrReblogDelegate>)obj;
- (long) likeAPI:(NSDictionary *)info handler:(id<TumblrLikeDelegate>)obj;

- (void) reblogCancel;
- (void) likeCancel;

- (long) deletePost:(NSString *)postID handler:(id<TumblrDeleteDelegate>)obj;
- (void) deletePostCancel;

- (void) upload:(NSDictionary *)info;

@end
