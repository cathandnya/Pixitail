//
//  BigURLDownloader.h
//  pixiViewer
//
//  Created by nya on 11/01/19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHHtmlParserConnection.h"


@class BigParser;
@interface BigURLDownloader : NSObject<CHHtmlParserConnectionDelegate> {
	NSString *parserClassName;
	NSString *bigSourceURL;
	NSString *referer;
	id object;

	id delegate;
	BigParser *parser;
	CHHtmlParserConnection *connection;
	
	NSArray *imageURLs;
}

@property(readwrite, nonatomic, retain) NSString *parserClassName;
@property(readwrite, nonatomic, retain) NSString *bigSourceURL;
@property(readwrite, nonatomic, retain) NSString *referer;
@property(readwrite, nonatomic, retain) id object;
@property(readwrite, nonatomic, assign) id delegate;

@property(readonly, nonatomic, assign) NSArray *imageURLs;

/// - (void) bigURLDownloader:(BigImageDownloader *)sender finished:(NSError *)err;
- (void) download;
- (void) cancel;

@end
