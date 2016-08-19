//
//  PixaLoginParser.h
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHHtmlParser.h"


@interface PixaLoginParser : CHHtmlParser {
	UInt32			state_;
	NSMutableArray	*inputs;
}

@property(assign, readonly, nonatomic) NSArray *inputs;

@end
