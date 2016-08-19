//
//  ScrapingMangaViewController.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixivMangaViewController.h"


@class ScrapingService;


@interface ScrapingMangaViewController : PixivMangaViewController

@property(readwrite, nonatomic, retain) NSString *serviceName;
@property(readonly, nonatomic, assign) ScrapingService *service;

@end
