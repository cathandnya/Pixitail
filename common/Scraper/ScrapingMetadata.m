//
//  ScrapingMetadata.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingMetadata.h"
#import "RegexKitLite.h"


@implementation ScrapingTag

@synthesize ID, name, attributes, needsScrapBodys, needsScrapAttributes, parent, children, depth;
@dynamic needsReadBody;

- (id) init {
	self = [super init];
	if (self) {
		children = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id) initWithDictionary:(NSDictionary *)dic {
	self = [super init];
	if (self) {
		children = [[NSMutableArray alloc] init];
		
		self.ID = [dic objectForKey:@"id"];
		self.name = [dic objectForKey:@"name"];
		if (!self.ID) {
			self.ID = self.name;
		}
		self.attributes = [dic objectForKey:@"attributes"];
		self.needsScrapAttributes = [dic objectForKey:@"needsScrapAttributes"];
		self.needsScrapBodys = [dic objectForKey:@"needsScrapBodys"];
		for (NSDictionary *d in [dic objectForKey:@"children"]) {
			ScrapingTag *tag = [[[ScrapingTag alloc] initWithDictionary:d] autorelease];
			if (tag) {
				[self addChild:tag];
			}
		}
	}
	return self;
}

- (void) dealloc {
	self.ID = nil;
	self.name = nil;
	self.attributes = nil;
	self.needsScrapAttributes = nil;
	self.needsScrapBodys = nil;
	self.children = nil;
	[super dealloc];
}

- (void) addChild:(ScrapingTag *)c {
	c.parent = self;
	[self.children addObject:c];
}

- (BOOL) matchStart:(NSString *)n attributes:(NSDictionary *)attr {
	//DLog(@"matchStart: %@", n);
	if ([n isEqualToString:self.name]) {
		DLog(@"matchStart: %@ [%d] %@", n, depth, [attr description]);
		if (self.depth == 0) {
			for (NSString *key in self.attributes) {
				NSString *val = [self.attributes objectForKey:key];
				NSString *v = [attr objectForKey:key];
				if (![v isMatchedByRegex:val]) {
					return NO;
				}
			}
			self.depth++;
			return YES;
		} else {
			self.depth++;
		}
	}
	return NO;
}

- (BOOL) matchEnd:(NSString *)n {
	if ([n isEqualToString:self.name]) {
		depth--;
		DLog(@"matchEnd: %@ [%d]", self.ID, depth);
		return depth == 0;
	}
	return NO;
}

- (BOOL) needsReadBody {
	return self.needsScrapBodys.count > 0;
}

- (NSDictionary *) scrapedAttributes:(NSDictionary *)attr {
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	for (NSString *key in self.needsScrapAttributes) {
		NSString *v = [attr objectForKey:key];
		NSArray *ary = [v captureComponentsMatchedByRegex:[self.needsScrapAttributes objectForKey:key]];
		if (ary) {
			[ret setObject:ary forKey:key];
		}
	}
	return ret;
}

- (NSArray *) scrapedBodys:(NSString *)body {
	NSMutableArray *ret = [NSMutableArray array];
	body = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	for (NSString *s in self.needsScrapBodys) {
		NSArray *ary = [body captureComponentsMatchedByRegex:s options:RKLDotAll range:NSMakeRange(0, body.length) error:nil];
		if (ary.count > 0) {
			[ret addObject:ary];
		}
	}
	return ret;
}

@end


@implementation ScrapingResult

@synthesize scrapedAttributes, scrapedBodys, parent, children, stringBuffer, ID;

- (id) init {
	self = [super init];
	if (self) {
		children = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	self.scrapedBodys = nil;
	self.scrapedAttributes = nil;
	self.children = nil;
	self.stringBuffer = nil;
	self.ID = nil;
	[super dealloc];
}

- (void) addChild:(ScrapingResult *)c {
	c.parent = self;
	[self.children addObject:c];
}

- (NSString *) aryDescription:(NSArray *)ary {
	NSMutableString *mstr = [NSMutableString string];
	[mstr appendString:@"("];
	int i = 0;
	for (NSString *s in ary) {
		[mstr appendString:s];
		if (++i < ary.count) {
			[mstr appendString:@","];
		}
	}
	[mstr appendString:@")"];
	return mstr;
}

- (void) descriptionWithString:(NSMutableString *)mstr depth:(NSString *)depthString {
	[mstr appendFormat:@"\n%@[%@]", depthString, self.ID];
	for (NSArray *s in scrapedBodys) {
		[mstr appendFormat:@" body:%@", [self aryDescription:s]];
	}
	for (NSString *s in [scrapedAttributes allKeys]) {
		NSArray *v = [scrapedAttributes objectForKey:s];
		[mstr appendFormat:@" %@:%@", s, [self aryDescription:v]];
	}
	
	if (self.children.count > 0) {
		[mstr appendString:@"\n"];
		depthString = [depthString stringByAppendingString:@"-"];
		
		for (ScrapingResult *r in self.children) {
			[r descriptionWithString:mstr depth:depthString];
		}
	}
}

- (NSString *) description {
	NSMutableString *mstr = [NSMutableString stringWithString:@""];
	[self descriptionWithString:mstr depth:@""];
	return mstr;
}

- (ScrapingResult *) childForPath:(NSString *)path {
	ScrapingResult *res = self;
	for (NSString *n in [path componentsSeparatedByString:@"."]) {
		//DLog(@"evel: %@", n);
		for (ScrapingResult *r in res.children) {
			if ([r.ID isEqual:n]) {
				res = r;
				break;
			}
		}
	}
	return res;
}

@end


@implementation ScrapingEvaluator

@synthesize regexIndex, resultRoot, path, attrName, isList, bodyIndex, children, replacing, resultIndex, strict;

- (id) initWithDictionary:(NSDictionary *)dic {
	self = [super init];
	if (self) {
		self.path = [[dic objectForKey:@"path"] componentsSeparatedByString:@"."];
		self.attrName = [dic objectForKey:@"attr_name"];
		if ([dic objectForKey:@"regex_idx"]) {
			self.regexIndex = [[dic objectForKey:@"regex_idx"] intValue];
		} else {
			self.regexIndex = -1;
		}
		self.bodyIndex = [[dic objectForKey:@"body_idx"] intValue];
		self.resultIndex = [[dic objectForKey:@"result_idx"] intValue];
		self.isList = [[dic objectForKey:@"is_list"] boolValue];
		self.children = [dic objectForKey:@"children"];
		self.replacing = [dic objectForKey:@"replacing"];
		self.strict = [[dic objectForKey:@"strict"] boolValue];
	}
	return self;
}

- (void) dealloc {
	self.path = nil;
	self.attrName = nil;
	self.children = nil;
	self.replacing = nil;
	[super dealloc];
}

- (id) evalResult:(ScrapingResult *)res {
	id ret = nil;
	NSArray *retArray = nil;
	if (self.attrName) {
		retArray = [res.scrapedAttributes objectForKey:self.attrName];
	} else {
		if (bodyIndex < res.scrapedBodys.count) {
			retArray = [res.scrapedBodys objectAtIndex:bodyIndex];
		}
	}
	if (regexIndex >= 0) {
		ret = [retArray objectAtIndex:regexIndex];
	} else {
		ret = [retArray lastObject];
	}
	if ([ret isKindOfClass:[NSString class]]) {
		for (NSDictionary *d in self.replacing) {
			ret = [ret stringByReplacingOccurrencesOfRegex:[d objectForKey:@"regex"] withString:[d objectForKey:@"replacing"]];
		}
	}
	return ret;
}

- (id) eval {
	id ret = nil;
	ScrapingResult *res = nil;
	if (strict) {
		ScrapingResult *root = self.resultRoot;
		if (self.path.count == 1 && [[self.path objectAtIndex:0] length] == 1) {
			res = root;
		} else if (self.path.count > 0) {
			if ([root.ID isEqual:[self.path objectAtIndex:0]]) {
				for (int i = 1; i < self.path.count; i++) {
					NSString *n = [self.path objectAtIndex:i];
					//DLog(@"evel: %@", n);
					ScrapingResult *tmp = nil;
					for (ScrapingResult *r in root.children) {
						if ([r.ID isEqual:n]) {
							tmp = r;	
							break;
						}
					}
					if (!tmp) {
						break;
					} else {
						root = tmp;
						if (i == self.path.count - 1) {
							res = tmp;
						}
					}
				}
			}
		}
	} else {
		res = self.resultRoot;
		for (int i = 0; i < self.path.count; i++) {
			NSString *n = [self.path objectAtIndex:i];
			//DLog(@"evel: %@", n);
			for (ScrapingResult *r in res.children) {
				if ([r.ID isEqual:n]) {
					res = r;	
					break;
				}
			}
		}
	}

	if (resultIndex > 0) {
		ScrapingResult *p = res.parent;
		for (int i = 0, j = 0; i < p.children.count; i++) {
			ScrapingResult *r = [p.children objectAtIndex:i];
			if (![r.ID isEqual:res.ID]) {
				continue;
			}
			
			if (j == resultIndex) {
				res = r;
				break;
			}
			j++;
		}
		/*
		if (resultIndex < p.children.count) {
			res = [p.children objectAtIndex:resultIndex];
		}
		 */
	}
	
	if (self.children) {
		if (self.isList) {
			NSMutableArray *mary = [NSMutableArray array];
			for (ScrapingResult *r in res.children) {
				NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
				for (NSDictionary *d in self.children) {
					NSDictionary *key = [d objectForKey:@"key"];
					NSDictionary *val = [d objectForKey:@"value"];
					NSString *k = nil, *v = nil;
					
					if ([key objectForKey:@"name"]) {
						k = [key objectForKey:@"name"];
					} else {
						ScrapingEvaluator *e = [[[ScrapingEvaluator alloc] initWithDictionary:key] autorelease];
						e.resultRoot = r;
						k = [e eval];
					}
					{
						ScrapingEvaluator *e = [[[ScrapingEvaluator alloc] initWithDictionary:val] autorelease];
						e.resultRoot = r;
						v = [e eval];
					}
					if (k && v) {
						[mdic setObject:v forKey:k];
					}
				}
				[mary addObject:mdic];
			}		
			
			NSMutableArray *a = [NSMutableArray array];
			for (NSDictionary *t in mary) {
				BOOL append = YES;
				for (NSDictionary *d in self.children) {
					NSDictionary *key = [d objectForKey:@"key"];
					if ([key objectForKey:@"name"]) {
						if (![t objectForKey:[key objectForKey:@"name"]]) {
							append = NO;
							break;
						}
					}
				}
				if (append) {
					[a addObject:t];
				}
			}
			ret = a;
		} else {
			NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
			for (ScrapingResult *r in res.children) {
				for (NSDictionary *d in self.children) {
					NSDictionary *key = [d objectForKey:@"key"];
					NSDictionary *val = [d objectForKey:@"value"];
					NSString *k = nil, *v = nil;
					
					if ([key objectForKey:@"name"]) {
						k = [key objectForKey:@"name"];
					} else {
						ScrapingEvaluator *e = [[[ScrapingEvaluator alloc] initWithDictionary:key] autorelease];
						e.resultRoot = r;
						k = [e eval];
					}
					{
						ScrapingEvaluator *e = [[[ScrapingEvaluator alloc] initWithDictionary:val] autorelease];
						e.resultRoot = r;
						v = [e eval];
					}
					if (k && v) {
						[mdic setObject:v forKey:k];
					}
				}
			}		
			ret = mdic;
		}
	} else if (self.isList) {
		ret = [NSMutableArray array];
		if (strict) {
			for (ScrapingResult *r in res.parent.children) {
				if ([r.ID isEqual:[self.path lastObject]]) {
					id obj = [self evalResult:r];
					if (obj) {
						[ret addObject:obj];
					}
				}
			}
		} else {
			for (ScrapingResult *r in res.children) {
				id obj = [self evalResult:r];
				if (obj) {
					[ret addObject:obj];
				}
			}
		}
	} else {
		ret = [self evalResult:res];
	}
	
	return ret;
}

@end
