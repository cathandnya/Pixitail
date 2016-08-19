//
//  ScrapingBigViewController.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixivBigViewController.h"


@class ScrapingService;


@interface ScrapingBigViewController : PixivBigViewController

@property(readwrite, nonatomic, retain) NSString *serviceName;
@property(readonly, nonatomic, assign) ScrapingService *service;

@end
