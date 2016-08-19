//
//  PostQueue.h
//
//  Created by nya on 10/09/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol PostQueueTargetHandlerProtocol
- (void) post:(id)sender finished:(long)err;
@end


@interface PostQueueItem : NSObject {
	id target;
	SEL postAction;
	SEL cancelAction;
	NSDictionary *object;
	id delegate;
}

@property(readwrite, nonatomic, assign) id target;
@property(readwrite, nonatomic, assign) SEL postAction;
@property(readwrite, nonatomic, assign) SEL cancelAction;
@property(readwrite, nonatomic, retain) NSDictionary *object;
@property(readwrite, nonatomic, assign) id delegate;
@property(readonly, nonatomic, assign) NSDictionary *info;

- (id) initWithInfo:(NSDictionary *)dic;

- (long) post;
- (void) cancel;

@end


@class Reachability;
@interface PostQueue : NSObject<PostQueueTargetHandlerProtocol> {
	Reachability *reachability;
	BOOL reachable;
	NSMutableArray *queue;
	BOOL active;
	NSString *queueName;
}

+ (PostQueue *) sharedInstance;
+ (PostQueue *) evernoteQueue;
+ (PostQueue *) dropboxQueue;
+ (PostQueue *) sugarsyncQueue;
+ (PostQueue *) googleDriveQueue;
+ (PostQueue *) skyDriveQueue;
+ (PostQueue *) pogoplugQueue;

+ (void) clean;
+ (void) cleanEvernote;
+ (void) cleanDropbox;
+ (void) cleanSugarSync;
+ (void) cleanGoogleDrive;
+ (void) cleanSkyDrive;
+ (void) cleanPogoplug;

- (id) initWithName:(NSString *)name;

- (void) pushObject:(NSDictionary *)info toTarget:(id)target action:(SEL)action cancelAction:(SEL)cancel;
- (BOOL) isActive:(id)target action:(SEL)action withObjectKey:(id)key value:(id)val;
- (PostQueueItem *) currentItem;

@end
