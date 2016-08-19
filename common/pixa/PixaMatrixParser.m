//
//  PixaMatrixParser.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaMatrixParser.h"


typedef enum {
	PixaMatrixParserState_Initial		= 0x0000,
	PixaMatrixParserState_Body			= 0x0001,
	PixaMatrixParserState_InA			= 0x0002
} PixaMatrixParserState;


@implementation PixaMatrixParser

@synthesize method;

- (NSString *) pageLink {
	NSArray	*comp = [self.method componentsSeparatedByString:@"?"];
	if ([comp count] > 1) {
		return [@"/" stringByAppendingPathComponent:[comp objectAtIndex:0]];
	} else {
		return [@"/" stringByAppendingPathComponent:self.method];
	}
}

- (void) startDocument {
	maxPage = 0;
	state_ = PixaMatrixParserState_Initial;
}

- (void) endDocument {
	[delegate matrixParser:self finished:0];
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	//DLog(@"%@: %@", name, [attributes description]);
	if ((state_ == PixaMatrixParserState_Initial) && [name isEqualToString:@"body"]) {
		state_ |= PixaMatrixParserState_Body;
	} else if ((state_ & PixaMatrixParserState_Body) && [name isEqualToString:@"a"]) {
		NSString	*href = [attributes objectForKey:@"href"];
		DLog(@"a: %@", href);
		if (href && [href hasPrefix:@"/illustrations/show/"]) {
			state_ |= PixaMatrixParserState_InA;
		} else if (href && [href hasPrefix:[self pageLink]]) {
			NSArray			*ary = [href componentsSeparatedByString:@"?"];
			NSDictionary	*info = nil;
			NSString		*page = nil;
				
			if ([ary count] == 2) {
				info = CHHtmlParserParseParam([ary objectAtIndex:1]);
			}
			page = [info objectForKey:@"page"];
			if (page) {
				int	p = [page intValue];
				if (maxPage < p) {
					maxPage = p;
				}
			}
		}
	} else if ((state_ & PixaMatrixParserState_InA) && [name isEqualToString:@"img"]) {
		NSString	*src = [attributes objectForKey:@"src"];
		NSString	*alt = [attributes objectForKey:@"alt"];
		if (src && alt) {
			//src = [src stringByPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			//src = [src stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[self.delegate matrixParser:self foundPicture:[NSDictionary dictionaryWithObjectsAndKeys:
				src,		@"ThumbnailURLString",
				alt,		@"IllustID",
				nil]];
		}
	}
}


- (void) endElementName:(NSString *)name {
	if ((state_ & PixaMatrixParserState_Body) && [name isEqualToString:@"body"]) {
		//[self.delegate matrixParser:self finished:0];
		state_ &= ~PixaMatrixParserState_Body;
	} else if ((state_ & PixaMatrixParserState_InA) && [name isEqualToString:@"a"]) {
		state_ &= ~PixaMatrixParserState_InA;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {

}

@end
