//
//  ScrapingService.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixService.h"


@class ConstantsManager;


@interface ScrapingService : PixService {
	NSMutableArray *favoriteUserAddingIDs;
}

@property(readwrite, nonatomic, retain) ConstantsManager *constants;
@property(readwrite, nonatomic, retain) NSString *serviceName;
@property(readonly, nonatomic, assign) BOOL ratingIsEnabled;
@property(readonly, nonatomic, assign) BOOL commentIsEnabled;
@property(readonly, nonatomic, assign) BOOL bookmarkIsEnabled;
@property(readonly, nonatomic, assign) BOOL favoriteUserIsEnabled;

+ (ScrapingService *) serviceFromName:(NSString *)name;

- (void) loginFinished:(id)obj handler:(id<PixServiceLoginHandler>)handler;

- (void) addToBookmark:(NSDictionary *)info;
- (void) addToFavoriteUser:(NSDictionary *)info;
- (void) rating:(NSInteger)val withInfo:(NSDictionary *)info;
- (void) comment:(NSString *)str withInfo:(NSDictionary *)info;

@end
