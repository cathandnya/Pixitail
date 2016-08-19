//
//  TumblrParser.m
//  pixiViewer
//
//  Created by nya on 10/01/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrParser.h"


static NSString *removeHTML(NSString *str) {
	NSMutableString *ret = [NSMutableString string];
	NSScanner *scan = [NSScanner scannerWithString:str];
	NSString *tmp = nil;
	BOOL b;
	BOOL searchTerm = NO;
	
	while (1) {
		if (searchTerm == NO) {
			if ([[str substringFromIndex:[scan scanLocation]] hasPrefix:@"<"]) {
				searchTerm = YES;
			} else {
				b = [scan scanUpToString:@"<" intoString:&tmp];
				if (b && tmp) {
					[ret appendString:tmp];
					
					b = [scan scanString:@"<" intoString:nil];
					if (b) {
						searchTerm = YES;
					} else {
						break;
					}
				} else {
					break;
				}
			}
		} else {
			b = [scan scanUpToString:@">" intoString:&tmp];
			if (b) {
				b = [scan scanString:@">" intoString:nil];
				if (!b) {
					break;
				} else {
					searchTerm = NO;
				}
			} else {
				break;
			}
		}
	}
	
	return ret;
}


typedef enum {
	TumblrParserState_Initial		= 0x0001,
	TumblrParserState_Posts			= 0x0002,
	TumblrParserState_Post			= 0x0004,
	TumblrParserState_Caption		= 0x0008,
	TumblrParserState_Image			= 0x0010,
	TumblrParserState_ImageLink		= 0x0020,
	TumblrParserState_ImageTag		= 0x0040,
} TumblrParserState;


@implementation TumblrParser

@synthesize delegate, info;
@synthesize maxPage;
@synthesize finished = finished_;

- (void) dealloc {
	[info release];
	info = nil;
	
	[super dealloc];
}

- (void) startDocument {
	state_ = TumblrParserState_Initial;
	finished_ = NO;
}

- (void) endDocument {
	[delegate matrixParser:self finished:0];
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	DLog(@"start[%@]: %@", name, [attributes description]);
	if ((state_ == TumblrParserState_Initial) && [name isEqualToString:@"posts"]) {
		state_ |= TumblrParserState_Posts;
		
		if ([attributes objectForKey:@"total"]) {
			maxPage = [[attributes objectForKey:@"total"] intValue];
		} else {
			maxPage = 250;
		}
	} else if ((state_ & TumblrParserState_Posts) && [name isEqualToString:@"post"] && [[attributes objectForKey:@"type"] isEqualToString:@"photo"]) {
		state_ |= TumblrParserState_Post;
		
		[info release];
		info = [[NSMutableDictionary alloc] initWithDictionary:attributes];

		if ([attributes objectForKey:@"id"] && [attributes objectForKey:@"tumblelog"]) {
			[info setObject:[NSString stringWithFormat:@"%@_%@", [attributes objectForKey:@"tumblelog"], [attributes objectForKey:@"id"]] forKey:@"IllustID"];						
		} else if ([attributes objectForKey:@"id"]) {
			[info setObject:[attributes objectForKey:@"id"] forKey:@"IllustID"];						
		}
		[info setObject:[attributes objectForKey:@"id"] forKey:@"PostID"];						
		[info setObject:[attributes objectForKey:@"reblog-key"] forKey:@"ReblogKey"];						
		[info removeObjectForKey:@"id"];
		if ([attributes objectForKey:@"liked"]) {
			[info setObject:[attributes objectForKey:@"liked"] forKey:@"Liked"];
		}
	} else if ((state_ & TumblrParserState_Post) && [name isEqualToString:@"photo-caption"]) {
		state_ |= TumblrParserState_Caption;
		buf_ = [[NSMutableString alloc] init];
	} else if ((state_ & TumblrParserState_Post) && [name isEqualToString:@"photo-url"]) {
		state_ |= TumblrParserState_Image;
		buf_ = [[NSMutableString alloc] init];
		if ([attributes objectForKey:@"max-width"]) {
			imageKey_ = [[NSString stringWithFormat:@"Image_%@", [attributes objectForKey:@"max-width"]] retain];
		}
	} else if ((state_ & TumblrParserState_Post) && [name isEqualToString:@"photo-link-url"]) {
		state_ |= TumblrParserState_ImageLink;
		buf_ = [[NSMutableString alloc] init];
	} else if ((state_ & TumblrParserState_Post) && [name isEqualToString:@"tag"]) {
		state_ |= TumblrParserState_ImageTag;
		buf_ = [[NSMutableString alloc] init];
	}
}


- (void) endElementName:(NSString *)name {
	if ((state_ & TumblrParserState_Posts) && [name isEqualToString:@"posts"]) {
		state_ &= ~TumblrParserState_Posts;
		//[delegate matrixParser:self finished:0];
		finished_ = YES;
	} else if ((state_ & TumblrParserState_Post) && [name isEqualToString:@"post"]) {
		state_ &= ~TumblrParserState_Post;

	DLog(@"info: %@", [info description]);
	NSMutableArray *keys = [NSMutableArray array];
	for (NSString *key in [info allKeys]) {
		if ([key hasPrefix:@"Image_"]) {
			NSArray *tmp = [key componentsSeparatedByString:@"_"];
			if ([tmp count] == 2) {
				int size = [[tmp objectAtIndex:1] intValue];
				[keys addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					key,							@"Key",
					[NSNumber numberWithInt:size],	@"Size",
					nil]];
			}
		}
	}

	NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"Size" ascending:YES];
	[keys sortUsingDescriptors:[NSArray arrayWithObject:desc]];
	[desc release];
	DLog(@"keys: %@", [keys description]);

	NSString *smallKey = nil;
	NSString *mediumKey = nil;
	NSString *bigKey = [[keys lastObject] objectForKey:@"Key"];
	for (NSDictionary *key in keys) {
		if (smallKey == nil && [[key objectForKey:@"Size"] intValue] >= 100) {
			smallKey = [key objectForKey:@"Key"];
		}
		if (mediumKey == nil && [[key objectForKey:@"Size"] intValue] >= 400) {
			mediumKey = [key objectForKey:@"Key"];
		}
	}
	if (mediumKey == nil) {
		mediumKey = bigKey;
	}
	
	if (smallKey && mediumKey && bigKey) {
		[info setObject:[info objectForKey:smallKey] forKey:@"ThumbnailURLString"];
		[info setObject:[info objectForKey:mediumKey] forKey:@"MediumURLString"];
		[info setObject:[info objectForKey:bigKey] forKey:@"BigURLString"];
	}
	
	if (0 && [info objectForKey:@"retweeted_status"]) {
		[info setObject:removeHTML([info objectForKey:@"retweeted_status"]) forKey:@"Title"];
	} else if ([info objectForKey:@"text"]) {
		[info setObject:removeHTML([info objectForKey:@"text"]) forKey:@"Title"];
	} else if ([info objectForKey:@"Caption"]) {
		[info setObject:removeHTML([info objectForKey:@"Caption"]) forKey:@"Title"];
	}
		
		if (info) {
			[delegate matrixParser:self foundPicture:info];
		}
		//[info release];
		//info = nil;
	} else if ((state_ & TumblrParserState_Caption) && [name isEqualToString:@"photo-caption"]) {
		state_ &= ~TumblrParserState_Caption;
		[info setObject:buf_ forKey:@"Caption"];
		[buf_ release];
		buf_ = nil;
	} else if ((state_ & TumblrParserState_Image) && [name isEqualToString:@"photo-url"]) {
		state_ &= ~TumblrParserState_Image;
		if (imageKey_) {
			[info setObject:buf_ forKey:imageKey_];
			[imageKey_ release];
			imageKey_ = nil;
		}
		[buf_ release];
		buf_ = nil;
	} else if ((state_ & TumblrParserState_ImageLink) && [name isEqualToString:@"photo-link-url"]) {
		state_ &= ~TumblrParserState_ImageLink;
		if ([buf_ hasPrefix:@"http://www.pixiv.net/"]) {
			NSScanner *scanner = [NSScanner scannerWithString:buf_];
			NSString *tmp;
			BOOL b;
			
			b = [scanner scanUpToString:@"illust_id=" intoString:&tmp];
			if (b) {
				[scanner scanString:@"illust_id=" intoString:&tmp];
				b = [scanner scanUpToString:@"&" intoString:&tmp];
				if (tmp) {
					// pixiv link
					[info setObject:@"Pixiv" forKey:@"PhotoType"];
					[info setObject:tmp forKey:@"PhotoLinkIllustID"];
				}
			}
		} else if ([buf_ hasPrefix:@"http://www.pixa.cc/illustrations/show/"]) {
			// pixa link
			[info setObject:@"Pixa" forKey:@"PhotoType"];
			[info setObject:[buf_ lastPathComponent] forKey:@"PhotoLinkIllustID"];
		} else if ([buf_ hasPrefix:@"http://www.tinami.com/view/"]) {
			// tinami link
			[info setObject:@"Tinami" forKey:@"PhotoType"];
			[info setObject:[buf_ lastPathComponent] forKey:@"PhotoLinkIllustID"];
		} else {
			//[info setObject:@"Tumblr" forKey:@"PhotoType"];
		}
		[info setObject:buf_ forKey:@"PhotoLink"];
		[buf_ release];
		buf_ = nil;
	} else if ((state_ & TumblrParserState_ImageTag) && [name isEqualToString:@"tag"]) {
		state_ &= ~TumblrParserState_ImageTag;
		NSMutableArray *ary = [info objectForKey:@"Tags"];
		if (ary == nil) {
			ary = [NSMutableArray array];
			[info setObject:ary forKey:@"Tags"];
		}
		[ary addObject:buf_];
		[buf_ release];
		buf_ = nil;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (buf_) {
		[buf_ appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:NSUTF8StringEncoding] autorelease]];
	}
}

@end
