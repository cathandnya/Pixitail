//
//  SeigaBigParser.m
//  pixiViewer
//
//  Created by nya on 2014/10/02.
//
//

#import "SeigaBigParser.h"
#import "SeigaConstants.h"
#import "ScrapingMetadata.h"

@implementation SeigaBigParser

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
		self.rootTag = [[ScrapingTag alloc] initWithDictionary:[[SeigaConstants sharedInstance] valueForKeyPath:@"big.scrap"]];
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
		self.rootTag = [[ScrapingTag alloc] initWithDictionary:[[SeigaConstants sharedInstance] valueForKeyPath:@"big.scrap"]];
	}
	return self;
}

#pragma mark-

- (void) startDocument {
	[super startDocument];
}

- (void) dealloc {
}

- (void) endDocument {
	NSMutableDictionary *mdic = (NSMutableDictionary *)[super evalResult:[[SeigaConstants sharedInstance] valueForKeyPath:@"big.eval"]];
	self.urlString = mdic[@"image"];
}

@end
