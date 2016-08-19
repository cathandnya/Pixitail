//
//  TinamiContentParser.m
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiContentParser.h"


@implementation TinamiContentParser

@synthesize info;

- (void) dealloc {
	[info release];
	[super dealloc];
}

- (void) startDocument {
	info = [[NSMutableDictionary alloc] init];
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqual:@"rsp"]) {
		if ([attributes objectForKey:@"stat"]) {
			[info setObject:[attributes objectForKey:@"stat"] forKey:@"Status"];
		}
	} else if ([name isEqual:@"err"]) {
		if ([attributes objectForKey:@"msg"]) {
			[info setObject:[attributes objectForKey:@"msg"] forKey:@"ErrorMessage"];
		}
	} else if ([name isEqual:@"content"]) {		
		[info setObject:[NSNumber numberWithBool:[[attributes objectForKey:@"issupport"] intValue] == 0] forKey:@"RatingEnable"];
		[info setObject:[NSNumber numberWithBool:[[attributes objectForKey:@"iscollection"] intValue] != 0] forKey:@"IsBookmark"];
		if ([attributes objectForKey:@"type"]) [info setObject:[attributes objectForKey:@"type"] forKey:@"ContentType"];
	} else if ([name isEqual:@"title"]) {
		string_ = [NSMutableString new];
	} else if ([name isEqual:@"creator"]) {
		if ([attributes objectForKey:@"id"]) {
			[info setObject:[attributes objectForKey:@"id"] forKey:@"UserID"];
		}
		if ([attributes objectForKey:@"isbookmark"]) {
			[info setObject:[NSNumber numberWithBool:[[attributes objectForKey:@"isbookmark"] isEqual:@"1"]] forKey:@"IsFavoriteUser"];
		}
	} else if ([name isEqual:@"description"]) {
		string_ = [NSMutableString new];
	} else if ([name isEqual:@"name"]) {
		string_ = [NSMutableString new];
	} else if ([name isEqual:@"url"]) {
		string_ = [NSMutableString new];
	} else if ([name isEqual:@"tag"]) {
		string_ = [NSMutableString new];
		if ([info objectForKey:@"Tags"] == nil) {
			[info setObject:[NSMutableArray array] forKey:@"Tags"];
		}
	} else if ([name isEqual:@"total_view"]) {
		string_ = [NSMutableString new];
	} else if ([name isEqual:@"user_view"]) {
		string_ = [NSMutableString new];
	} else if ([name isEqual:@"valuation"]) {
		string_ = [NSMutableString new];
	} else if ([name isEqual:@"images"]) {
		// マンガ
		[info setObject:[NSMutableArray array] forKey:@"Images"];
	} else if ([name isEqual:@"image"]) {
		NSMutableArray *ary = [info objectForKey:@"Images"];
		[ary addObject:[NSMutableDictionary dictionary]];
	} else if ([name isEqual:@"pages"]) {
		// 小説
		[info setObject:[NSMutableArray array] forKey:@"Pages"];
	} else if ([name isEqual:@"page"]) {
		string_ = [NSMutableString new];
	} else if ([name isEqual:@"dates"]) {
		if ([attributes objectForKey:@"posted"]) {
			[info setObject:[attributes objectForKey:@"posted"] forKey:@"DateString"];
		}
	}
}


- (void) endElementName:(NSString *)name {
	if ([name isEqual:@"title"]) {
		[info setObject:string_ forKey:@"Title"];
		[string_ release];
		string_ = nil;
	} else if ([name isEqual:@"description"]) {
		[info setObject:string_ forKey:@"Comment"];
		[string_ release];
		string_ = nil;
	} else if ([name isEqual:@"name"]) {
		[info setObject:string_ forKey:@"UserName"];
		[string_ release];
		string_ = nil;
	} else if ([name isEqual:@"url"]) {
		NSMutableArray *ary = [info objectForKey:@"Images"];
		if ([ary count] > 0) {
			NSMutableDictionary *img = [ary lastObject];
			[img setObject:string_ forKey:@"URLString"];
		} else {
			[info setObject:string_ forKey:@"MediumURLString"];
			[info setObject:string_ forKey:@"BigURLString"];
		}
		[string_ release];
		string_ = nil;
	} else if ([name isEqual:@"tag"]) {
		NSMutableArray *ary = [info objectForKey:@"Tags"];
		[ary addObject:[NSDictionary dictionaryWithObject:string_ forKey:@"Name"]];
		[string_ release];
		string_ = nil;
	} else if ([name isEqual:@"total_view"]) {
		[info setObject:[NSNumber numberWithInt:[string_ intValue]] forKey:@"total_view"];
		[string_ release];
		string_ = nil;
	} else if ([name isEqual:@"user_view"]) {
		[info setObject:[NSNumber numberWithInt:[string_ intValue]] forKey:@"user_view"];
		[string_ release];
		string_ = nil;
	} else if ([name isEqual:@"valuation"]) {
		[info setObject:[NSNumber numberWithInt:[string_ intValue]] forKey:@"valuation"];
		[string_ release];
		string_ = nil;
	} else if ([name isEqual:@"content"]) {
		if ([self.info objectForKey:@"MediumURLString"] == nil && [[self.info objectForKey:@"Images"]  count] > 0) {
			[self.info setObject:[[[self.info objectForKey:@"Images"] objectAtIndex:0] objectForKey:@"URLString"] forKey:@"MediumURLString"];
		}	
	} else if ([name isEqual:@"page"]) {
		NSMutableArray *ary = [info objectForKey:@"Pages"];
		[ary addObject:string_];
		[string_ release];
		string_ = nil;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (string_) {
		[string_ appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:NSUTF8StringEncoding] autorelease]];
	}
}

@end
