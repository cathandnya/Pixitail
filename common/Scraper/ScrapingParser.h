//
//  ScrapingParser.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHHtmlParser.h"


@class ScrapingTag;
@class ScrapingResult;


@interface ScrapingParser : CHHtmlParser {
	ScrapingTag *matchedTag;
	NSMutableArray *results;
	ScrapingResult *currentResult;
}

@property(readwrite, nonatomic, retain) ScrapingTag *rootTag;
@property(readonly, nonatomic, assign) NSArray *results;
@property(readonly, nonatomic, assign) ScrapingResult *resultRoot;

- (NSDictionary *) evalResult:(NSDictionary *)evals;

@end
