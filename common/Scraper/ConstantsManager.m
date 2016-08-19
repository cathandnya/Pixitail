//
//  ConstantsManager.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import "ConstantsManager.h"


@implementation ConstantsManager

@synthesize vers;

+ (ConstantsManager *) sharedInstance {
	static ConstantsManager *obj = nil;
	if (obj == nil) {
		obj = [[ConstantsManager alloc] init];
	}
	return obj;
}

- (NSString *) versURL {
	return nil;
}

- (NSString *) constantsURL {
	return nil;
}

- (NSString *) defaultConstantsPath {
	return nil;
}

- (NSString *) defaultKey {
	return [NSString stringWithFormat:@"%@_vers", NSStringFromClass([self class])];
}

- (NSInteger) vers {
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:[self defaultKey]];
	if (obj) {
		return [obj integerValue];
	} else {
		return 0;
	}
}

- (void) setVers:(NSInteger)v {
	[[NSUserDefaults standardUserDefaults] setInteger:v forKey:[self defaultKey]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *) constantsPath {
	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
	if (a_paths.count > 0) {
		return [[[a_paths objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass([self class])] stringByAppendingPathExtension:@"plist"];
	} else {
		return nil;
	}
}

- (void) setConstants:(NSDictionary *)dic {
	if (constants != dic) {
		[dic writeToFile:[self constantsPath] atomically:YES];
		[constants release];
		constants = [dic retain];
	}
}

- (id) init {
	self = [super init];
	if (self) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:[self constantsPath]]) {
			constants = [[NSDictionary alloc] initWithContentsOfFile:[self constantsPath]];
		}
		if (!constants) {
			[self setConstants:[NSDictionary dictionaryWithContentsOfFile:[self defaultConstantsPath]]];
			[self setVers:0];
		}
	}
	return self;
}

- (void) dealloc {
	[constants release];
	[super dealloc];
}

- (void) reloadSync {
	NSError *err = nil;
	
	if (constants == nil) {
		[self setConstants:[NSDictionary dictionaryWithContentsOfFile:[self defaultConstantsPath]]];
	}
	
	if (![self versURL]) {
		[self setConstants:[NSDictionary dictionaryWithContentsOfFile:[self defaultConstantsPath]]];
		return;
	}
	
	NSString *str = [NSString stringWithContentsOfURL:[NSURL URLWithString:[self versURL]] encoding:NSUTF8StringEncoding error:&err];
	if (err || !str) {
		return;
	}
	int v = [str intValue];
	if (v <= [self vers]) {
		return;
	}
	
	NSDictionary *dic = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[self constantsURL]]];
	if (dic) {
		[self setConstants:dic];
		[self setVers:v];
	}
}

- (void) reload:(id)handler {	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self reloadSync];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[handler performSelector:@selector(constantsManager:finishLoading:) withObject:self withObject:nil];
		});	
	});
}

- (id) valueForKey:(NSString *)key {
	return [constants valueForKey:key];
}

- (id) valueForKeyPath:(NSString *)keyPath {
	return [constants valueForKeyPath:keyPath];
}

@end
