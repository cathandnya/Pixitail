//
//  CHHtmlParserConnection.h
//  pixiViewerTest
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class CHHtmlParserConnection;
@protocol CHHtmlParserConnectionDelegate
- (void) connection:(CHHtmlParserConnection *)con finished:(long)err;
@end


@class CHHtmlParser;
@interface CHHtmlParserConnection : NSObject {
	NSURLConnection	*connection;
	NSURL			*url;
	NSString		*referer;
	NSString		*method;
	NSData			*postBody;

	NSString		*user;
	NSString		*pass;
	
	CHHtmlParser *parser;
	id<CHHtmlParserConnectionDelegate> delegate;
	
	NSTimeInterval timeout;
	NSTimer *timeoutTimer;
}

@property(readwrite, nonatomic, assign) id<CHHtmlParserConnectionDelegate> delegate;
@property(readwrite, nonatomic, retain) NSString *referer;
@property(readwrite, nonatomic, retain) NSString *method;
@property(readwrite, nonatomic, retain) NSData *postBody;
@property(readwrite, nonatomic, retain) NSString *user;
@property(readwrite, nonatomic, retain) NSString *pass;
@property(readwrite, nonatomic, assign) NSTimeInterval timeout;
@property(readwrite, nonatomic, assign) BOOL noRedirect;
@property(readwrite, nonatomic, retain) NSString *lastUrl;

- (id) initWithURL:(NSURL *)url;

- (void) startWithParser:(CHHtmlParser *)parser;
- (void) cancel;

- (void) connectionDidFinishLoading:(NSURLConnection *)con;

- (NSError *) startWithParserSync:(CHHtmlParser *)p;

@end


@interface CHHtmlParserConnectionOnce : CHHtmlParserConnection {
	NSMutableData *receivedData;
}

@end
