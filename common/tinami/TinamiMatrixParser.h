//
//  TinamiMatrixParser.h
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"
#import "MatrixParser.h"


@interface TinamiMatrixParser : CHXmlParser {
	id<MatrixParserDelegate>	delegate;
	NSMutableDictionary *info_;

	int maxPage;
}

@property(nonatomic, readwrite, assign) id<MatrixParserDelegate> delegate;
@property(nonatomic, readwrite, assign) int maxPage;

@end
