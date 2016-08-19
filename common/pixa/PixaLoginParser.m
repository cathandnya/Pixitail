//
//  PixaLoginParser.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaLoginParser.h"


typedef enum {
	PixaLoginParserState_Initial			= 0x0000,
	PixaLoginParserState_Body				= 0x0001,
	PixaLoginParserState_Form				= 0x0002,
} PixaLoginParserState;


@implementation PixaLoginParser

@synthesize inputs;

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {	
		inputs = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[inputs release];
	inputs = nil;
	
	[super dealloc];
}

- (void) startDocument {
	state_ = PixaLoginParserState_Initial;
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ((state_ == PixaLoginParserState_Initial) && [name isEqualToString:@"body"]) {
		state_ |= PixaLoginParserState_Body;
	} else if ((state_ & PixaLoginParserState_Body) && [name isEqualToString:@"form"]) {
		NSString	*action = [attributes objectForKey:@"action"];
		if ([action isEqualToString:@"/session"]) {
			state_ |= PixaLoginParserState_Form;
		}
	} else if ((state_ & PixaLoginParserState_Form) && [name isEqualToString:@"input"]) {
		[inputs addObject:attributes];
	}
}


- (void) endElementName:(NSString *)name {
	if ((state_ & PixaLoginParserState_Body) && [name isEqualToString:@"body"]) {
		state_ &= ~PixaLoginParserState_Body;
	} else if ((state_ & PixaLoginParserState_Body) && [name isEqualToString:@"form"]) {
		state_ &= ~PixaLoginParserState_Body;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end
