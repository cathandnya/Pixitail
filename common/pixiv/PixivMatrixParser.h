//
//  PixivMatrixParser.h
//  pixiViewer
//
//  Created by nya on 09/08/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MatrixParser.h"
#import "ScrapingParser.h"


@interface PixivMatrixParser : ScrapingParser 

@property(nonatomic, readwrite, assign) id<MatrixParserDelegate> delegate;
@property(nonatomic, readwrite, assign) int maxPage;
@property(nonatomic, readwrite, assign) NSDictionary *scrapingInfo;

@end
