//
//  LoginUserBlog.h
//  Tumbltail
//
//  Created by nya on 11/09/20.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tumblog.h"


@interface LoginUserBlog : Tumblog

@property(readonly, nonatomic, assign) BOOL isPrimary;

@end
