//
//  AccountManager.h
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TumblrAccount.h"


@interface TumblrAccountManager : NSObject {
	NSMutableArray *accounts;
	TumblrAccount *currentAccount;
}

@property(readonly, assign, nonatomic) NSArray *accounts;
@property(readwrite, retain, nonatomic) TumblrAccount *currentAccount;

+ (TumblrAccountManager *) sharedInstance;

- (void) save;

- (void) addAccount:(TumblrAccount *)acc original:(TumblrAccount *)orig;
- (void) removeAccount:(TumblrAccount *)acc;
- (void) moveIndex:(NSUInteger)fromIndex toIndex:(NSInteger)toIndex;

- (TumblrAccount *) accountWithInfo:(NSDictionary *)info;

@end
