//
//  DanbooruPostsParser.h
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHJsonParser.h"
#import "MatrixParser.h"


@interface DanbooruPostsParser : CHJsonParser {
	id<MatrixParserDelegate> delegate;
	int maxPage;
}

@property(readwrite, nonatomic, retain) NSString *urlBase;
@property(nonatomic, readwrite, assign) id<MatrixParserDelegate> delegate;

@end
