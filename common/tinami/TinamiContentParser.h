//
//  TinamiContentParser.h
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"


@interface TinamiContentParser : CHXmlParser {
	NSMutableDictionary *info;
	NSMutableString *string_;
}

@property(readonly, assign, nonatomic) NSMutableDictionary *info;

@end
