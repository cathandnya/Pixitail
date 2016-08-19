//
//  Requests.h
//  Tumbltail
//
//  Created by nya on 11/09/17.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OAAsynchronousDataFetcher;
@class Request;
@class OAToken;
@class OAConsumer;
@class Reachability;


@interface RequestPool : NSObject {
	Reachability *reachability;
	NSMutableDictionary *requests;
	NSMutableSet *pendingRequestIDs;
}

+ (RequestPool *) sharedObject;

- (void) addAndStart:(Request *)req;
- (void) remove:(NSString *)ID;
- (BOOL) isRunning:(NSString *)ID;
- (Request *) requestForID:(NSString *)ID;
- (void) retry:(Request *)req;
- (BOOL) reachable;

@end


@interface Request : NSObject {
	OAAsynchronousDataFetcher *fetcher;
	NSURLConnection *connection;
	NSMutableData *responseData;
	
	NSString *url;
	NSDictionary *param;
	OAToken *token;
	OAConsumer *consumer;
	
	UIBackgroundTaskIdentifier bgTaskID;
	BOOL asyncLoading;
}

@property(readonly, nonatomic, assign) BOOL isLoading;
@property(weak) id delegate;
@property(weak) RequestPool *pool;
@property(readonly, nonatomic, assign) NSString *ID;
@property(readwrite, nonatomic, retain) NSString *url;
@property(readwrite, nonatomic, retain) NSDictionary *param;
@property(readwrite, nonatomic, retain) OAToken *token;
@property(readwrite, nonatomic, retain) OAConsumer *consumer;

- (void) start;
- (void) cancel;

- (void) start:(void (^)(NSDictionary *))block;

//- (void) startInBackground;

- (id) load;

- (NSString *) notificationName;

@end


@interface JsonRequest : Request
@end


#pragma mark-


@interface LoginRequest : Request

- (void) startWithUsername:(NSString *)uname password:(NSString *)pass;

@end


@interface TumblrRequest : JsonRequest
@end


@interface TumblrBlogRequest : TumblrRequest {
	NSString *blogHostName;
}

@property(readwrite, nonatomic, retain) NSString *blogHostName;

@end


@interface UserInfoRequest : TumblrRequest
@end


@interface PostLoadRequest : TumblrRequest
@end


@interface BlogPostLoadRequest : TumblrBlogRequest {
	NSString *type;
}

@property(readwrite, nonatomic, retain) NSString *type;

@end


@interface ReblogRequest : TumblrBlogRequest
@end


@interface DeleteRequest : TumblrBlogRequest
@end


@interface EditRequest : TumblrBlogRequest
@end


@interface LikeRequest : TumblrRequest
@end


@interface UnlikeRequest : TumblrRequest
@end


@interface FollowRequest : TumblrRequest

+ (BOOL) isLoading:(NSString *)url;

@end


@interface UnfollowRequest : TumblrRequest

+ (BOOL) isLoading:(NSString *)url;

@end


@interface BlogInfoRequest : TumblrBlogRequest
@end


@interface FollowerListRequest : TumblrBlogRequest
@end


@interface FollowingListRequest : TumblrRequest
@end


@interface PostRequest : TumblrBlogRequest {
	NSString *uuid;
	BOOL sendToTwitter;
}

@property(readwrite, nonatomic, retain) NSString *uuid;
@property(readwrite, nonatomic, assign) BOOL sendToTwitter;
@property(readwrite, nonatomic, retain) NSString *postID;

@end


@interface PostDataRequest : PostRequest {
}

@property(strong) NSArray *dataList;
@property(strong) NSString *caption;
@property(strong) NSString *tags;
@property(strong) NSString *type;

@end


@interface PostPhotoRequest : PostDataRequest  {
	NSString *link;
}

@property(readwrite, nonatomic, retain) NSString *link;

@end


@interface PostLoadRequestDashboardMore : PostLoadRequest {
	long long sinceID;
}

@property(readwrite, nonatomic, assign) long long lastPostID;
@property(readwrite, nonatomic, assign) long long periodOfpostID;

@end

