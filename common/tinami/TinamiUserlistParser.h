//
//  TinamiUserlistParser.h
//  pixiViewer
//
//  Created by nya on 10/03/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"


@interface TinamiUserlistParser : CHXmlParser {
	NSMutableDictionary *tmpDic;
	NSMutableString *tmpStr;

	NSMutableArray *list;
	NSString		*method;
	int				maxPage;
}

@property(readwrite, retain, nonatomic) NSString *method;
@property(readonly, assign, nonatomic) NSArray *list;
@property(nonatomic, readwrite, assign) int maxPage;

@end
