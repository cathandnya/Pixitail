//
//  TwitterParser.h
//  pixiViewer
//
//  Created by nya on 10/01/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"
#import "MatrixParser.h"


@interface TwitterParser : CHXmlParser {
	id<MatrixParserDelegate>	delegate;
	int state_;
	NSMutableString *buf_;
	NSMutableDictionary *info_;
	NSMutableDictionary *user_;
	NSString *key_;
	BOOL finished_;
}

@property(nonatomic, readwrite, assign) id<MatrixParserDelegate> delegate;
@property(nonatomic, readwrite, assign) int maxPage;

@end
