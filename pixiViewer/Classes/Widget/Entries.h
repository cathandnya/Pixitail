//
//  Entries.h
//  pview
//
//  Created by Naomoto nya on 12/03/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <NotificationCenter/NotificationCenter.h>


@class Service;


@interface Entries : NSObject {
	NSMutableArray *list;
}

@property(readwrite, nonatomic, retain) NSString *name;
@property(readonly, nonatomic, assign) NSArray *list;
@property(readwrite, nonatomic, assign) BOOL isLoading;
@property(readwrite, nonatomic, assign) BOOL canLoadMore;
@property(readwrite, nonatomic, retain) Service *service;

- (void) refresh:(void (^)(NSError *))completionBlock;
- (void) more:(void (^)(NSError *))completionBlock;
- (NCUpdateResult) refresh;

+ (Entries *) entriesWithInfo:(NSDictionary *)dic;
- (id) initWithInfo:(NSDictionary *)dic;
- (NSMutableDictionary *) info;

- (void) save;
- (void) load;

@end


@interface MatrixEntries : Entries {
	NSMutableArray *tmpList;
}

@property(readwrite, nonatomic, assign) int currentPage;
@property(readwrite, nonatomic, retain) NSString *method;
@property(readwrite, nonatomic, retain) NSString *scrapingInfoKey;

@end


@interface StaccEntries : Entries {
}

@property(readwrite, nonatomic, retain) NSString *method;
@property(readwrite, nonatomic, retain) NSString *scrapingInfoKey;
@property(readwrite, nonatomic, retain) NSString *nextMaxSID;

@end
	
