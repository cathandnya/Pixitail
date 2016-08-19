//
//  BigParser.h
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHHtmlParser.h"


@interface BigParser : CHHtmlParser {
	UInt32		state_;
	NSString	*urlString;
}

@property(retain, nonatomic, readwrite) NSString *urlString;

@end
