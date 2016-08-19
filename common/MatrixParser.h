//
//  MatrixParser.h
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHHtmlParser.h"


@class MatrixParser;
@protocol MatrixParserDelegate
- (void) matrixParser:(id)parser foundPicture:(NSDictionary *)pic;
- (void) matrixParser:(id)parser finished:(long)err;
@end


@interface MatrixParser : CHHtmlParser {
	id<MatrixParserDelegate>	delegate;
	int							maxPage;
	UInt32						state_;
}

@property(nonatomic, readwrite, assign) id<MatrixParserDelegate> delegate;
@property(nonatomic, readwrite, assign) int maxPage;

@end
