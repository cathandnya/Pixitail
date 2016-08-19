//
//  TumblrLoginParser.h
//  pixiViewer
//
//  Created by nya on 10/05/05.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"


@interface TumblrLoginParser : CHXmlParser {
	NSString *name;
}

@property(readwrite, nonatomic, retain) NSString *name;

@end
