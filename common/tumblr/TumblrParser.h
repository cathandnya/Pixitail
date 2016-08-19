//
//  TumblrParser.h
//  pixiViewer
//
//  Created by nya on 10/01/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"
#import "MatrixParser.h"


@interface TumblrParser : CHXmlParser {
	id<MatrixParserDelegate>	delegate;
	int state_;
	NSMutableString *buf_;
	NSMutableDictionary *info;
	NSString *imageKey_;
	BOOL finished_;
	int maxPage;
}

@property(nonatomic, readwrite, retain) NSDictionary *info;
@property(nonatomic, readwrite, assign) id<MatrixParserDelegate> delegate;
@property(nonatomic, readwrite, assign) int maxPage;
@property(nonatomic, readwrite, assign) BOOL finished;

@end
