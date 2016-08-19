//
//  PixivMangaParser.h
//  pixiViewer
//
//  Created by nya on 09/09/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


#import "ScrapingParser.h"


@interface PixivMangaParser : ScrapingParser {
	NSMutableArray	*urlStrings;
}

@property(retain, nonatomic, readwrite) NSArray *urlStrings;

@end
