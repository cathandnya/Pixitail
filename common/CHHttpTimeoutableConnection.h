//
//  CHHttpTimeoutableConnection.h
//  pixiViewer
//
//  Created by nya on 09/09/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CHHttpTimeoutableConnection : NSObject {
	NSURLConnection	*connection_;
	NSMutableData	*data_;
	pthread_cond_t	cond_;
	pthread_mutex_t	mutex_;
	BOOL			finished_;
	BOOL			completed_;
}

- (id) initWithRequest:(NSURLRequest *)req;

- (NSData *) startWithTimeout:(NSTimeInterval)ti;

@end
