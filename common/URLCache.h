//
//  URLCache.h
//  EchoPro
//
//  Created by nya on 09/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface URLCache : NSObject {
	NSMutableDictionary	*cache;
	
	NSMutableArray		*queue_;
	pthread_mutex_t		queueMutex_;
	pthread_cond_t		queueCond_;
	BOOL				pause_;
}

+ (URLCache *) sharedInstance;

- (void) pause;
- (void) resume;

- (id) objectForURL:(NSString *)url;
- (id) objectForURLPriory:(NSString *)url;

- (void) clearQueue;
- (void) setObject:(id)obj forURL:(NSString *)url;
- (void) removeObjectForURL:(NSString *)url;

@end


