//
//  PixService.h
//  pixiViewer
//
//  Created by nya on 09/09/24.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PostQueue.h"


@class Reachability;


@class PixService;
@protocol PixServiceLoginHandler
- (void) pixService:(PixService *)sender loginFinished:(long)err;
@end

@protocol PixServiceAddBookmarkHandler
- (void) pixService:(PixService *)sender addBookmarkFinished:(long)err;
@end

@protocol PixServiceRatingHandler
- (void) pixService:(PixService *)sender ratingFinished:(long)err;
@end

@protocol PixServiceCommentHandler
- (void) pixService:(PixService *)sender commentFinished:(long)err;
@end


@interface PixService : NSObject<PixServiceAddBookmarkHandler, PixServiceCommentHandler, PixServiceRatingHandler, UIAlertViewDelegate> {
	NSString	*username;
	NSString	*password;
	BOOL		logined;
	NSDate		*loginDate;
	
	Reachability *_reachability;
	BOOL reachable;
	
	NSMutableDictionary		*illustStorage_;
	
	id<PixServiceLoginHandler>	loginHandler_;
	NSURLConnection				*logoutConnection_;
	NSURLConnection				*loginConnection_;
	NSMutableData				*loginRet_;

	id<PixServiceAddBookmarkHandler>	addBookmarkHandler_;
	NSURLConnection						*addBookmarkConnection_;
	id<PostQueueTargetHandlerProtocol>	addBookmarkQueueHandler;
	NSMutableArray *bookmarkAddingIDs;

	id<PixServiceRatingHandler>			ratingHandler_;
	NSURLConnection						*ratingConnection_;
	id<PostQueueTargetHandlerProtocol>	ratingQueueHandler;
	NSMutableArray *ratingIDs;

	id<PixServiceCommentHandler>		commentHandler_;
	NSURLConnection						*commentConnection_;
	id<PostQueueTargetHandlerProtocol>	commentQueueHandler;
	NSMutableArray *commentingIDs;
}

@property(nonatomic, readwrite, retain) NSString *username;
@property(nonatomic, readwrite, retain) NSString *password;
@property(nonatomic, readwrite, assign) BOOL logined;
@property(nonatomic, readwrite, assign) BOOL reachable;
@property(nonatomic, readwrite, assign) BOOL needsLogin;
@property(nonatomic, readonly, assign) NSDate *expireDate;
@property(nonatomic, readonly, assign) BOOL hasExpireDate;

+ (BOOL) useAPI;

- (NSString *) hostName;

- (long) login:(id<PixServiceLoginHandler>)handler;
- (long) loginCancel;

- (long) addToBookmark:(NSString *)illustID withInfo:(NSDictionary *)info handler:(id<PixServiceAddBookmarkHandler>)handler;
- (long) addToBookmarkCancel;

- (long) removeFromBookmark:(NSString *)illustID;

- (long) rating:(NSInteger)val withInfo:(NSDictionary *)info handler:(id<PixServiceRatingHandler>)handler;
- (void) ratingCancel;

- (long) comment:(NSString *)str withInfo:(NSDictionary *)info handler:(id<PixServiceCommentHandler>)handler;
- (void) commentCancel;

- (long) allertReachability;

- (void) addEntries:(NSDictionary *)info forIllustID:(NSString *)iid;
- (void) removeEntriesForIllustID:(NSString *)iid;
- (NSMutableDictionary *) infoForIllustID:(NSString *)iid;
- (void) removeAllEntries;

- (void) addToBookmark:(NSString *)illustID withInfo:(NSDictionary *)info;
- (BOOL) isBookmarking:(NSString *)ID;
- (void) rating:(NSInteger)val withInfo:(NSDictionary *)info;
- (BOOL) isRating:(NSString *)ID;
- (void) comment:(NSString *)str withInfo:(NSDictionary *)info;
- (BOOL) isCommenting:(NSString *)ID;

+ (PixService *) serviceWithName:(NSString *)name;

@end


NSString* encodeURIComponent(NSString* s);
