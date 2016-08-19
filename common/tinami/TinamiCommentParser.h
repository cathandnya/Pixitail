//
//  TinamiCommentParser.h
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"


@interface TinamiCommentParser : CHXmlParser {
	NSMutableArray *comments;
	NSMutableString *tmpString;
}

@property(readonly, assign, nonatomic) NSArray *comments;

@end
