//
//  AccountManager.m
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrAccountManager.h"


@implementation TumblrAccountManager

@synthesize accounts, currentAccount;

+ (TumblrAccountManager *) sharedInstance {
	static TumblrAccountManager *obj = nil;
	if (!obj) {
		obj = [[TumblrAccountManager alloc] init];
	}
	return obj;
}

- (TumblrAccountManager *) init {
	self = [super init];
	if (self) {
		accounts = [[NSMutableArray alloc] init];
		
		NSArray *ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"TumblrAccounts"];
		for (NSDictionary *info in ary) {
			TumblrAccount *acc = [[TumblrAccount alloc] initWithInfo:info];
			if (acc && [accounts containsObject:acc] == NO) {
				[accounts addObject:acc];
			}
			[acc release];
		}
		
		NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentTumblrAccount"];
		if (info) {
			NSInteger idx = [accounts indexOfObject:[[[TumblrAccount alloc] initWithInfo:info] autorelease]];
			if (idx >= 0 && idx < accounts.count) {
				self.currentAccount = [accounts objectAtIndex:idx];
			}
		}
		if (self.currentAccount == nil &&  accounts.count > 0) {
			self.currentAccount = [accounts objectAtIndex:0];
		}

		[self save];
	}
	return self;
}

- (void) dealloc {
	[currentAccount release];
	[accounts release];
	[super dealloc];
}

#pragma mark-

- (void) save {
	NSMutableArray *ary = [NSMutableArray array];
	for (TumblrAccount *acc in self.accounts) {
		[ary addObject:[acc info]];
	}
	
	if (self.currentAccount) {
		[[NSUserDefaults standardUserDefaults] setObject:[self.currentAccount info] forKey:@"CurrentTumblrAccount"];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:@"TumblrAccounts"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) addAccount:(TumblrAccount *)acc original:(TumblrAccount *)orig {
	if (orig) {
		orig.userID	= acc.userID;
		orig.userInfo = acc.userInfo;
		orig.token = acc.token;
	} else {
		[accounts addObject:acc];
	}
	[self save];
}

- (void) removeAccount:(TumblrAccount *)acc {
	[accounts removeObject:acc];
	[self save];
}

- (void) moveIndex:(NSUInteger)fromIndex toIndex:(NSInteger)toIndex {
	id from = [[[accounts objectAtIndex:fromIndex] retain] autorelease];	
	[accounts removeObjectAtIndex:fromIndex];
	[accounts insertObject:from atIndex:toIndex];
	[self save];
}

- (TumblrAccount *) accountWithInfo:(NSDictionary *)info {
	if (info == nil) {
		return nil;
	}

	TumblrAccount *tmp = [[[TumblrAccount alloc] initWithInfo:info] autorelease];
	TumblrAccount *acc;
	for (acc in [TumblrAccountManager sharedInstance].accounts) {
		if ([acc isEqual:tmp]) {
			break;
		}
	}
	return acc;
}

- (void) setCurrentAccount:(TumblrAccount *)acc {
	NSInteger idx = [accounts indexOfObject:acc];
	if (idx >= 0 && idx < [accounts count]) {
		[currentAccount release];
		currentAccount = [[accounts objectAtIndex:idx] retain];
	} else {
		[currentAccount release];
		currentAccount = nil;
	}
}

@end
