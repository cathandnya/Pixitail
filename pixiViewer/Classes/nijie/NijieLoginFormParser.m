//
//  NijieLoginFormParser.m
//  pixiViewer
//
//  Created by Naomoto nya on 12/06/23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NijieLoginFormParser.h"

@implementation NijieLoginFormParser

@synthesize action, hiddenInputs;

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
	}
	return self;
}

- (void) dealloc {
	self.action = nil;
	self.hiddenInputs = nil;
	[super dealloc];
}

- (void) startDocument {
	self.hiddenInputs = [NSMutableDictionary dictionary];
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	DLog(@"%@: %@", name, [attributes description]);
	if (!inForm && [name caseInsensitiveCompare:@"form"] == NSOrderedSame) {
		NSString *str = [attributes objectForKey:@"action"];
		if ([str hasPrefix:@"login"]) {
			self.action = str;
			inForm = YES;
		}
	} else if (inForm && [name caseInsensitiveCompare:@"input"] == NSOrderedSame) {
		NSString *type = [attributes objectForKey:@"type"];
		NSString *name = [attributes objectForKey:@"name"];
		NSString *value = [attributes objectForKey:@"value"];
		if ([type isEqual:@"hidden"]) {
			[hiddenInputs setObject:value forKey:name];
		}
	}
}

- (void) endElementName:(NSString *)name {
	if (inForm && [name caseInsensitiveCompare:@"form"] == NSOrderedSame) {
		inForm = NO;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end
