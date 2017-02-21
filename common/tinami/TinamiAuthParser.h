//
//  TinamiAuthParser.h
//  pixiViewer
//
//  Created by nya on 10/02/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"


@interface TinamiAuthParser : CHXmlParser {
	NSString *status;
	NSString *errorMessage;
	NSString *creatorID;
    NSMutableString *stringBuffer;
}

@property(readwrite, retain, nonatomic) NSString *status;
@property(readwrite, retain, nonatomic) NSString *errorMessage;
@property(readwrite, retain, nonatomic) NSString *creatorID;
@property(readwrite, retain, nonatomic) NSString *authKey;

@end
