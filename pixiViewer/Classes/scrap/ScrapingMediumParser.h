//
//  ScrapMediumParser.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScrapingParser.h"


@interface ScrapingMediumParser : ScrapingParser

@property(readwrite, retain, nonatomic) NSMutableDictionary *scrapingInfo;
@property(readwrite, retain, nonatomic) NSMutableDictionary *info;

@end
