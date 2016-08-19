//
//  Danbooru.h
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixService.h"


@class PixAccount;


@interface Danbooru : PixService {
	
}

@property(readwrite, nonatomic, retain) PixAccount *account;

+ (Danbooru *) sharedInstance;
+ (NSString *) hashedPassword:(NSString *)pass;

@end
