//
//  ConstantsManager.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface ConstantsManager : NSObject {
	NSDictionary *constants;
}

@property(readonly, nonatomic, assign) NSInteger vers;

+ (ConstantsManager *) sharedInstance;

- (void) reload:(id)handler;
- (void) reloadSync;

- (id) valueForKey:(NSString *)key;
- (id) valueForKeyPath:(NSString *)keyPath;

- (void) setConstants:(NSDictionary *)dic;
- (void) setVers:(NSInteger)v;

@end
