//
//  JsonObject.m
//
//  Created by nya on 11/02/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JsonObject.h"
#import "JSON.h"


@implementation JsonObject

@synthesize json;

- (id) initWithJson:(id)obj {
	self = [super init];
	if (self) {
		json = [obj retain];
	}
	return self;
}

- (id) initWithContentsOfFile:(NSString *)path {
	NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	if (str) {
		return [self initWithJson:[str JSONValue]];
	}
	return nil;
}

- (void) dealloc {
	[json release];
	[super dealloc];
}

- (void) writeToFile:(NSString *)path {
	[[self data] writeToFile:path atomically:YES];
}

- (NSData *) data {
	return [[json JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
}

- (id) valueForKey:(NSString *)key {
	return [json valueForKey:key];
}

- (void) merge:(NSDictionary *)d {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:json];
	[mdic addEntriesFromDictionary:d];
	[json release];
	json = [mdic retain];
}

@end
