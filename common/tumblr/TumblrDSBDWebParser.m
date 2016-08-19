//
//  TumblrDSBDWebParser.m
//  pixiViewer
//
//  Created by nya on 10/08/15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrDSBDWebParser.h"


typedef enum {
	TumblrDSBDWebParserState_Initial		= 0x0001,
	TumblrDSBDWebParserState_Posts			= 0x0002,
	TumblrDSBDWebParserState_Post			= 0x0004,
	TumblrDSBDWebParserState_PostCtrl		= 0x0008,
	TumblrDSBDWebParserState_PostInfo		= 0x0010,
} TumblrDSBDWebParserState;


@implementation TumblrDSBDWebParser

- (void) dealloc {
	[super dealloc];
}

- (void) startDocument {
	state_ = TumblrDSBDWebParserState_Initial;
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	NSString *ID = [attributes objectForKey:@"id"];
	
	if (state_ & TumblrDSBDWebParserState_PostInfo) {
		if ([name isEqual:@"a"]) {
		}
	} else if (state_ & TumblrDSBDWebParserState_PostCtrl) {
		if ([name isEqual:@"a"]) {
			NSString *href = [attributes objectForKey:@"href"];
			NSArray *comps = [href pathComponents];
			if ([comps count] == 3 && [[comps objectAtIndex:0] isEqual:@"reblog"]) {
				// reblog link
				[curInfo setObject:[comps objectAtIndex:1] forKey:@"PostID"];
				
				NSArray *ary = [[comps objectAtIndex:2] componentsSeparatedByString:@"?"];
				if ([ary count] == 2) {
					[curInfo setObject:[ary objectAtIndex:0] forKey:@"ReblogKey"];
				}
			}
		}
	} else if (state_ & TumblrDSBDWebParserState_Post) {
		if ([name isEqual:@"div"]) {
			NSString *cls = [attributes objectForKey:@"class"];
			if ([cls isEqual:@"post_controls"]) {
				state_ |= TumblrDSBDWebParserState_PostCtrl;			
			} else if ([cls isEqual:@"post_info"]) {
				state_ |= TumblrDSBDWebParserState_PostInfo;			
			}
		}
	} else if (state_ & TumblrDSBDWebParserState_Posts) {
		if ([name isEqual:@"li"]) {
			NSString *cls = [attributes objectForKey:@"class"];
			NSArray *ary = [cls componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			if ([ary containsObject:@"photo"]) {
				// post開始
				state_ |= TumblrDSBDWebParserState_Post;
				curInfo = [[NSMutableDictionary alloc] init];
			}
		}
	} else if (state_ & TumblrDSBDWebParserState_Initial) {
		if ([name isEqual:@"ol"]) {
			if ([ID isEqual:@"posts"]) {
				state_ |= TumblrDSBDWebParserState_Posts;
			}
		}
	}
}


- (void) endElementName:(NSString *)name {
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end
