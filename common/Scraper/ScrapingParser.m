//
//  ScrapingParser.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import "ScrapingParser.h"
#import "ScrapingMetadata.h"
#import "RegexKitLite.h"


@implementation ScrapingParser

@synthesize rootTag, results;
@dynamic resultRoot;

- (void) dealloc {
	self.rootTag = nil;
	[results release];
	[super dealloc];
}

#pragma mark-

- (ScrapingResult *) resultRoot {
	if (results.count > 0) {
		return [results objectAtIndex:0];
	}
	return nil;
}

- (void) startDocument {
	matchedTag = nil;
	results = [[NSMutableArray alloc] init];
	currentResult = nil;
}

- (NSDictionary *) evalResult:(NSDictionary *)evals {
	for (ScrapingResult *r in results) {
		DLog(@"%@", [r description]);
	}
	
	NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
	for (NSString *key in [evals allKeys]) {
		NSDictionary *d = [evals objectForKey:key];
		ScrapingEvaluator *eval = [[[ScrapingEvaluator alloc] initWithDictionary:d] autorelease];
		eval.resultRoot = self.resultRoot;
		DLog(@"eval %@", key);
		id ret = [eval eval];
		DLog(@" -> %@", ret);
		if (ret) {
			[mdic setObject:ret forKey:key];
		}
	}
	return mdic;
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if (matchedTag) {		
		assert(currentResult);
		
		BOOL matched = NO;
		for (ScrapingTag *tag in matchedTag.children) {
			if ([tag matchStart:name attributes:attributes]) {
				DLog(@"match: %@", tag.ID);
				ScrapingResult *r = [[[ScrapingResult alloc] init] autorelease];
				r.ID = tag.ID;
				r.scrapedAttributes = [tag scrapedAttributes:attributes];
				if (tag.needsReadBody) {
					r.stringBuffer = [[[NSMutableString alloc] init] autorelease];
				}
				[currentResult addChild:r];				
				
				matchedTag = tag;
				currentResult = r;
				matched = YES;
				break;
			}
		}
		
		if (!matched) {
			[matchedTag matchStart:name attributes:attributes];
		}
	} else {
		ScrapingTag *tag = self.rootTag;
		if ([tag matchStart:name attributes:attributes]) {
			DLog(@"match: %@", tag.ID);
			ScrapingResult *r = [[[ScrapingResult alloc] init] autorelease];
			r.ID = tag.ID;
			r.scrapedAttributes = [tag scrapedAttributes:attributes];
			if (tag.needsReadBody) {
				r.stringBuffer = [[[NSMutableString alloc] init] autorelease];
			}
			[results addObject:r];				
			
			matchedTag = tag;
			currentResult = r;
		}
	}
    
    if (currentResult.stringBuffer && [name caseInsensitiveCompare:@"br"] == NSOrderedSame) {
        [currentResult.stringBuffer appendString:@"\n"];
    }
}

- (void) endElementName:(NSString *)name {
	ScrapingTag *tag = matchedTag;
	//DLog(@"end: %@ %@ %@", name, tag.name, currentResult.ID);
	if ([tag matchEnd:name]) {
		ScrapingResult *r = currentResult;
		if (tag.needsReadBody) {
			r.scrapedBodys = [tag scrapedBodys:r.stringBuffer];
		}
		r.stringBuffer = nil;
		DLog(@"end: %@", [r description]);
		
		matchedTag = matchedTag.parent;
		currentResult = currentResult.parent;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	ScrapingResult *r = currentResult;
	if (r.stringBuffer) {
		NSString *str = [[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease];
		str = [str stringByReplacingOccurrencesOfRegex:@"[\n\r]" withString:@""];
		DLog(@"%@", str);
		[r.stringBuffer appendString:str];
	}
}

@end
