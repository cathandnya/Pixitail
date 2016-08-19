//
//  ScrapingConstants.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/25.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingConstants.h"

@implementation ScrapingConstants

@synthesize versURL, constantsURL, defaultConstantsPath, constantsPath;

- (id) initWithInfo:(NSDictionary *)info {
	self = [super init];
	if (self) {
		NSString *name = [info objectForKey:@"name"];
		self.serviceName = name;
		self.versURL = [info objectForKey:@"vers_url"];
#ifndef NDEBUG
		//self.versURL = nil;
#endif
		self.constantsURL = [info objectForKey:@"const_url"];
		self.defaultConstantsPath = [[NSBundle mainBundle] pathForResource:[info objectForKey:@"default_name"] ofType:@"plist"];
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
		if (a_paths.count > 0) {
			self.constantsPath = [[[a_paths objectAtIndex:0] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"];
		}

		if ([[NSFileManager defaultManager] fileExistsAtPath:[self constantsPath]]) {
			constants = [[NSDictionary alloc] initWithContentsOfFile:[self constantsPath]];
		}
		if (!constants) {
			[self setConstants:[NSDictionary dictionaryWithContentsOfFile:[self defaultConstantsPath]]];
			[self setVers:0];
		}
		
		int vers = [[info objectForKey:@"version"] intValue];
		if (vers > self.vers) {
			[self setConstants:[NSDictionary dictionaryWithContentsOfFile:[self defaultConstantsPath]]];
			[self setVers:vers];
		}
	}
	return self;
}

- (void) dealloc {
	self.serviceName = nil;
	self.versURL = nil;
	self.constantsURL = nil;
	self.defaultConstantsPath = nil;
	self.constantsPath = nil;
	[super dealloc];
}

- (NSString *) defaultKey {
	return [NSString stringWithFormat:@"%@_vers", self.serviceName];
}

@end
