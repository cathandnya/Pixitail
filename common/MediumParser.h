//
//  MediumParser.h
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHHtmlParser.h"


@interface MediumParser : CHHtmlParser {
	NSMutableDictionary	*info;
	UInt32				state_;
}

@property(readonly, assign, nonatomic) NSMutableDictionary *info;

@end
