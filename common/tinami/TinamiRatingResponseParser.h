//
//  TinamiRatingResponseParser.h
//  pixiViewer
//
//  Created by nya on 10/03/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"


@interface TinamiRatingResponseParser : CHXmlParser {
	int rate;
}

@property(readwrite, assign, nonatomic) int rate;

@end
