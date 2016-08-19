//
//  NijieLoginFormParser.h
//  pixiViewer
//
//  Created by Naomoto nya on 12/06/23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHHtmlParser.h"

@interface NijieLoginFormParser : CHHtmlParser {
	BOOL inForm;
}

@property(readwrite, nonatomic, retain) NSString *action;
@property(readwrite, nonatomic, retain) NSMutableDictionary *hiddenInputs;

@end
