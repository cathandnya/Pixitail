//
//  PixivMediumCommentParser.h
//  pixiViewer
//
//  Created by nya on 10/08/31.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScrapingParser.h"


@interface PixivMediumCommentParser : ScrapingParser {
	NSMutableArray *comments;
}

@property(readonly, nonatomic, assign) NSMutableArray *comments;

@end
