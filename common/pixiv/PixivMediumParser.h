//
//  PixivMediumParser.h
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


#import "ScrapingParser.h"


@interface PixivMediumParser : ScrapingParser 

@property(readwrite, retain, nonatomic) NSMutableDictionary *info;
@property(readwrite, nonatomic, assign) BOOL noComments;

@end
