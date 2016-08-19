//
//  AccountManager.m
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AccountManager.h"
#import "PixListThumbnail.h"
#import "NSData+Crypto.h"


@implementation PixAccount

@synthesize serviceName, username, password, thumbnail, otherInfo;
@dynamic typeString, identifier, anonymous;

+ (NSDictionary *) serviceWithType:(int)type {
	for (NSDictionary *d in [self services]) {
		if ([[d objectForKey:@"type"] intValue] == type) {
			return d;
		}
	}
	return nil;
}

+ (NSDictionary *) serviceWithName:(NSString *)name {
	for (NSDictionary *d in [self services]) {
		if ([[d objectForKey:@"name"] isEqual:name]) {
			return d;
		}
	}
	return nil;
}
/*
+ (AccountType) typeFromString:(NSString *)obj {
	return [[[self serviceWithName:obj] objectForKey:@"type"] intValue];
}

+ (NSString *) stringFromType:(AccountType)type {
	return [[self serviceWithType:type] objectForKey:@"name"];
}
*/
+ (NSArray *) services {
	static NSArray *ary = nil;
	if (!ary) {
		ary = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"services" ofType:@"plist"]];
	}
	return ary;
}

- (id) init {
	self = [super init];
	if (self) {
		thumbnail = [[PixListThumbnail alloc] initWithAccount:self];
	}
	return self;
}

+ (PixAccount *) accountWithInfo:(NSDictionary *)info {
	return [[[PixAccount alloc] initWithInfo:info] autorelease];
}

- (id) initWithInfo:(NSDictionary *)info {
	self = [super init];
	if (self) {
		NSString *obj;
		
		obj = [info objectForKey:@"Username"];
		self.username = obj;
		obj = [info objectForKey:@"Password"];
		obj = [obj decryptedString];
		self.password = obj;
		obj = [info objectForKey:@"TypeString"];
		self.serviceName = obj;
		self.otherInfo = [info objectForKey:@"otherInfo"];
		if ([self.serviceName isEqualToString:@"Danbooru"] && self.hostname.length == 0) {
			self.hostname = @"danbooru.donmai.us";
		}
		
		if ([self.serviceName isEqualToString:@"Tumblr"]) {
			[self release];
			return nil;
		}
		
		thumbnail = [[PixListThumbnail alloc] initWithAccount:self];
	}
	return self;
}

- (NSDictionary *)info {
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	
	if (username) {
		[ret setObject:username forKey:@"Username"];
	}
	if (password) {
		NSString *pass = password;
		pass = [pass cryptedString];
		[ret setObject:pass forKey:@"Password"];
	}
	if (self.typeString) {
		[ret setObject:self.typeString forKey:@"TypeString"];
	}
	if (self.otherInfo) {
		[ret setObject:self.otherInfo forKey:@"otherInfo"];
	}
	return ret;
}

- (void) dealloc {
	[username release];
	[password release];
	[thumbnail release];
	[otherInfo release];
	[serviceName release];

	[super dealloc];
}

- (NSString *) typeString {
	return self.serviceName;
}

- (id)copyWithZone:(NSZone *)zone {
	PixAccount *acc = [[PixAccount alloc] init];
	acc.serviceName = self.serviceName;
	acc.username = self.username;
	acc.password = self.password;
	acc.otherInfo = self.otherInfo;
	return acc;
}

- (BOOL) isEqual:(PixAccount *)other {
	return [self.identifier isEqual:other.identifier];
}

- (NSString *) identifier {
	if ([self.serviceName isEqualToString:@"Danbooru"]) {
		return [NSString stringWithFormat:@"%@_%@_%@", self.typeString, self.hostname, self.username];
	} else {
		return [NSString stringWithFormat:@"%@_%@", self.typeString, self.username];
	}
}

- (BOOL) anonymous {
	return [self.username length] == 0;
}

@end


@implementation PixAccount(Danbooru)

@dynamic hostname;

- (NSString *) hostname {
	return [self.otherInfo objectForKey:@"hostname"];
}

- (void) setHostname:(NSString *)hostname {
	NSMutableDictionary *mdic = (self.otherInfo ? [NSMutableDictionary dictionaryWithDictionary:self.otherInfo] : [NSMutableDictionary dictionary]);
	[mdic setObject:hostname forKey:@"hostname"];
	self.otherInfo = mdic;
}

@end


@implementation AccountManager

@synthesize accounts;

+ (AccountManager *) sharedInstance {
	static AccountManager *obj = nil;
	if (!obj) {
		obj = [[AccountManager alloc] init];
	}
	return obj;
}

+ (NSDictionary *) encryptoInfo:(NSDictionary *)info {
	NSString *pass = [info objectForKey:@"Password"];
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:info];
	[mdic setObject:[pass cryptedString] forKey:@"Password"];
	return mdic;
}

+ (void) encryptoAccounts {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PasswordIsCryopted"]) {
		return;
	}	
	
	NSArray *ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"Accounts"];
	NSMutableArray *mary = [NSMutableArray array];
	for (NSDictionary *info in ary) {
		[mary addObject:[self encryptoInfo:info]];
	}
	[[NSUserDefaults standardUserDefaults] setObject:mary forKey:@"Accounts"];
	
	NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastAccount"];
	if (info) {
		[[NSUserDefaults standardUserDefaults] setObject:[self encryptoInfo:info] forKey:@"LastAccount"];
	}
	
	NSString *pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"EvernotePassword"];
	if (pass.length > 0) {
		[[NSUserDefaults standardUserDefaults] setObject:[pass cryptedString] forKey:@"EvernotePassword"];
	}
	
//#ifdef PIXITAIL
	pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"TumblrPassword"];
	if (pass.length > 0) {
		[[NSUserDefaults standardUserDefaults] setObject:[pass cryptedString] forKey:@"TumblrPassword"];
	}
//#endif
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PasswordIsCryopted"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (AccountManager *) init {
	self = [super init];
	if (self) {
		//NSString *user, *pass;
		BOOL add = NO;
		
		PixAccount *tinamiAnon = [[[PixAccount alloc] init] autorelease];
		tinamiAnon.serviceName = @"TINAMI";
		tinamiAnon.username = @"";
		tinamiAnon.password = @"";

		accounts = [[NSMutableArray alloc] init];
		
		NSArray *ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"Accounts"];
		for (NSDictionary *info in ary) {
			PixAccount *acc = [PixAccount accountWithInfo:info];
			if (!acc) {
				continue;
			}
#ifdef PIXITAIL
			if ([accounts containsObject:acc] == NO) {
				acc.serviceName = @"pixiv";
#else
			if ([accounts containsObject:acc] == NO && ![acc.serviceName isEqualToString:@"pixiv"] && (![acc.serviceName isEqualToString:@"Danbooru"] || acc.username.length > 0)) {
#endif
				[accounts addObject:acc];
			}
			if ([tinamiAnon isEqual:acc]) {
				add = NO;
			}
		}
		if (ary == nil) {
			add = YES;
		}

#ifndef PIXITAIL
		if (add) {
			[accounts addObject:tinamiAnon];
		}
#endif

		[self save];
	}
	return self;
}

- (void) dealloc {
	[accounts release];
	[super dealloc];
}

#pragma mark-

- (void) save {
	NSMutableArray *ary = [NSMutableArray array];
	for (PixAccount *acc in self.accounts) {
		[ary addObject:[acc info]];
	}

	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:@"Accounts"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *) accountsForServiceName:(NSString *)n {
	NSMutableArray *ary = [NSMutableArray array];
	for (PixAccount *acc in accounts) {
		if ([acc.typeString isEqualToString:n]) {
			[ary addObject:acc];
		}
	}
	return ary;
}

- (void) addAccount:(PixAccount *)acc original:(PixAccount *)orig {
	if (orig) {
		orig.serviceName = acc.serviceName;
		orig.username = acc.username;
		orig.password = acc.password;
	} else {
		[accounts addObject:acc];
	}
	[self save];
}

- (void) removeAccount:(PixAccount *)acc {
	[accounts removeObject:acc];
	[self save];
}

- (void) moveIndex:(NSUInteger)fromIndex toIndex:(NSInteger)toIndex {
	id from = [[[accounts objectAtIndex:fromIndex] retain] autorelease];	
	[accounts removeObjectAtIndex:fromIndex];
	[accounts insertObject:from atIndex:toIndex];
	[self save];
}

- (PixAccount *) defaultAccount:(NSString *)serviceName {
#ifdef PIXITAIL
	if ([serviceName isEqualToString:@"Tumblr"]) {
		return [self tumblrAccount];
	}
#endif
	PixAccount *acc = nil;
	for (acc in accounts) {
		if ([acc.serviceName isEqualToString:serviceName]) {
			return acc;
		}
	}
	return nil;
}

#ifdef PIXITAIL
- (PixAccount *) tumblrAccount {
	NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"TumblrUsername"];
	NSString *pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"TumblrPassword"];
	if ([user length] > 0 && [pass length] > 0) {
		PixAccount *acc = [[PixAccount alloc] init];
		acc.serviceName = @"Tumblr";
		acc.username = user;
		acc.password = [pass decryptedString];
		return [acc autorelease];
	}
	return nil;
}
- (void) setTumblrUser:(NSString *)user andPass:(NSString *)pass {
	[[NSUserDefaults standardUserDefaults] setObject:user forKey:@"TumblrUsername"];
	[[NSUserDefaults standardUserDefaults] setObject:[pass cryptedString] forKey:@"TumblrPassword"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
#endif

- (PixAccount *) accountWithInfo:(NSDictionary *)info {
	if (info == nil) {
		return nil;
	}

	PixAccount *tmp = [PixAccount accountWithInfo:info];
	PixAccount *acc;
	for (acc in [AccountManager sharedInstance].accounts) {
		if ([acc isEqual:tmp]) {
			break;
		}
	}
	return acc;
}

@end
