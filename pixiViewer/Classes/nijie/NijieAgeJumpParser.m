//
//  NijieAgeJumpParser.m
//  pixiViewer
//
//  Created by nya on 2012/09/29.
//
//

#import "NijieAgeJumpParser.h"

@implementation NijieAgeJumpParser

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
	self.url = nil;
	[super dealloc];
}

- (void) startDocument {
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	DLog(@"%@: %@", name, [attributes description]);
	if (self.url == nil && [name caseInsensitiveCompare:@"a"] == NSOrderedSame) {
		NSString *str = [attributes objectForKey:@"href"];
		if ([str hasPrefix:self.urlPrefix]) {
			self.url = str;
		}
	}
}

- (void) endElementName:(NSString *)name {
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end
