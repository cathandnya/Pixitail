//
//  AccountManager.h
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
#define AccountType_Tinami			(0)
#define AccountType_Pixiv			(1)
#define AccountType_Pixa			(2)
#define AccountType_Tumblr			(3)
#define AccountType_Danbooru		(4)
#define AccountType_Seiga			(5)
#define AccountType_Count			([PixAccount services].count)

typedef int AccountType;
*/


@class PixListThumbnail;

@interface PixAccount : NSObject {
	NSString *serviceName;
	NSString *username;
	NSString *password;
	PixListThumbnail *thumbnail;
}

@property(retain, nonatomic, readwrite) NSString *serviceName;
@property(retain, nonatomic, readwrite) NSString *username;
@property(retain, nonatomic, readwrite) NSString *password;
@property(retain, nonatomic, readwrite) NSDictionary *otherInfo;

@property(assign, nonatomic, readonly) NSString *typeString;
@property(assign, nonatomic, readonly) NSString *identifier;
@property(assign, nonatomic, readonly) BOOL anonymous;

@property(assign, nonatomic, readonly) PixListThumbnail *thumbnail;

//+ (AccountType) typeFromString:(NSString *)obj;
//+ (NSString *) stringFromType:(AccountType)type;

+ (NSArray *) services;
//+ (NSDictionary *) serviceWithType:(int)type;
+ (NSDictionary *) serviceWithName:(NSString *)name;

+ (PixAccount *) accountWithInfo:(NSDictionary *)info;
- (id) initWithInfo:(NSDictionary *)info;
- (NSDictionary *)info;

@end


@interface PixAccount(Danbooru)
@property(retain, nonatomic, readwrite) NSString *hostname;
@end


@interface AccountManager : NSObject {
	NSMutableArray *accounts;
}

@property(readonly, assign, nonatomic) NSArray *accounts;

+ (AccountManager *) sharedInstance;

- (NSArray *) accountsForServiceName:(NSString *)n;

- (void) save;

- (void) addAccount:(PixAccount *)acc original:(PixAccount *)orig;
- (void) removeAccount:(PixAccount *)acc;
- (void) moveIndex:(NSUInteger)fromIndex toIndex:(NSInteger)toIndex;

- (PixAccount *) defaultAccount:(NSString *)serviceName;

#ifdef PIXITAIL
- (PixAccount *) tumblrAccount;
- (void) setTumblrUser:(NSString *)user andPass:(NSString *)pass;
#endif

- (PixAccount *) accountWithInfo:(NSDictionary *)info;

+ (void) encryptoAccounts;

@end
