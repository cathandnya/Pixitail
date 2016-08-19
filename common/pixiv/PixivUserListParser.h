//
//  PixivUserListParser.h
//  pixiViewer
//
//  Created by nya on 09/10/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ScrapingParser.h"


@interface PixivUserListParser : ScrapingParser {
	NSMutableArray	*list;
}

@property(readwrite, retain, nonatomic) NSString *method;
@property(readonly, assign, nonatomic) NSArray *list;
@property(nonatomic, readwrite, assign) int maxPage;
@property(nonatomic, readwrite, assign) NSDictionary *scrapingInfo;

@end
