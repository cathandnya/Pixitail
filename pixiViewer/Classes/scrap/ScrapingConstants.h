//
//  ScrapingConstants.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/25.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConstantsManager.h"


@interface ScrapingConstants : ConstantsManager

@property(readwrite, nonatomic, retain) NSString *versURL;
@property(readwrite, nonatomic, retain) NSString *constantsURL;
@property(readwrite, nonatomic, retain) NSString *defaultConstantsPath;
@property(readwrite, nonatomic, retain) NSString *constantsPath;
@property(readwrite, nonatomic, retain) NSString *serviceName;

- (id) initWithInfo:(NSDictionary *)info;

@end
