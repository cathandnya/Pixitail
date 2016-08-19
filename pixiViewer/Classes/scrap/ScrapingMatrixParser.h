//
//  ScrapingMatrixParser.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScrapingParser.h"
#import "MatrixParser.h"


@interface ScrapingMatrixParser : ScrapingParser

@property(nonatomic, readwrite, assign) id<MatrixParserDelegate> delegate;
@property(nonatomic, readwrite, assign) int maxPage;
@property(nonatomic, readwrite, assign) NSDictionary *scrapingInfo;

@end
