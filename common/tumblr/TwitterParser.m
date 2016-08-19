//
//  TwitterParser.m
//  pixiViewer
//
//  Created by nya on 10/01/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TwitterParser.h"


typedef enum {
	TwitterParserState_Initial		= 0x0001,
	TwitterParserState_Statuses		= 0x0002,
	TwitterParserState_Status		= 0x0004,
	TwitterParserState_User			= 0x0008,
} TwitterParserState;


@implementation TwitterParser

@synthesize delegate;
@dynamic maxPage;

- (int) maxPage {
	return INT_MAX;
}

- (void) startDocument {
	state_ = TwitterParserState_Initial;
	finished_ = NO;
}

- (void) endDocument {
	[delegate matrixParser:self finished:0];
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ((state_ == TwitterParserState_Initial) && [name isEqualToString:@"statuses"]) {
		state_ |= TwitterParserState_Statuses;
	} else if ((state_ & TwitterParserState_Statuses) && [name isEqualToString:@"status"]) {
		state_ |= TwitterParserState_Status;
		info_ = [[NSMutableDictionary alloc] init];
	} else if (state_ & TwitterParserState_Status) {
		if ([name isEqualToString:@"user"]) {
			state_ |= TwitterParserState_User;
			user_ = [[NSMutableDictionary alloc] init];
		} else if (key_ == nil) {
			buf_ = [[NSMutableString alloc] init];
			key_ = [name retain];
		}
	}
}


- (void) endElementName:(NSString *)name {
	if ((state_ & TwitterParserState_Statuses) && [name isEqualToString:@"statuses"]) {
		state_ &= ~TwitterParserState_Statuses;
		//[delegate matrixParser:self finished:0];
		finished_ = YES;
	} else if ((state_ & TwitterParserState_Status) && [name isEqualToString:@"status"]) {
		state_ &= ~TwitterParserState_Status;
		
		if ([info_ objectForKey:@"id"]) {
			[info_ setObject:[NSString stringWithFormat:@"%lld", atoll([[info_ objectForKey:@"id"] cStringUsingEncoding:NSASCIIStringEncoding]) >> 16] forKey:@"PostID"];
			[info_ setObject:[info_ objectForKey:@"id"] forKey:@"StatusID"];
		}
		if ([[info_ objectForKey:@"user"] objectForKey:@"screen_name"]) {
			[info_ setObject:[[info_ objectForKey:@"user"] objectForKey:@"screen_name"] forKey:@"User"];
			[info_ setObject:[info_ objectForKey:@"User"] forKey:@"UserName"];
		}
		if ([info_ objectForKey:@"PostID"] && [info_ objectForKey:@"User"]) {
			[info_ setObject:[NSString stringWithFormat:@"%@_%@", [info_ objectForKey:@"User"], [info_ objectForKey:@"PostID"]] forKey:@"IllustID"];
		}
		//NSLog([info_ description]);

		[delegate matrixParser:self foundPicture:info_];
		[info_ release];
		info_ = nil;
	} else if ((state_ & TwitterParserState_User) && [name isEqualToString:@"user"]) {
		state_ &= ~TwitterParserState_User;
		[info_ setObject:user_ forKey:@"user"];
		[user_ release];
		user_ = nil;
	} else if ((state_ & TwitterParserState_User) && [key_ isEqualToString:name]) {
		[user_ setObject:buf_ forKey:name];
		[buf_ release];
		buf_ = nil;
		[key_ release];
		key_ = nil;
	} else if ((state_ & TwitterParserState_Status) && [key_ isEqualToString:name]) {
		[info_ setObject:buf_ forKey:name];
		[buf_ release];
		buf_ = nil;
		[key_ release];
		key_ = nil;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (buf_) {
		[buf_ appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:NSUTF8StringEncoding] autorelease]];
	}
}

@end
