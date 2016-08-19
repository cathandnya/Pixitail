//
//  CHHtmlParserConnectionNoScript.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHHtmlParserConnection.h"


@interface CHHtmlParserConnectionNoScript : CHHtmlParserConnectionOnce
@property(retain) NSMutableArray *scripts;
@end
