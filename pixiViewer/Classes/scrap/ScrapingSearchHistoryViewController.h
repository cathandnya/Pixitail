//
//  SeigaSearchHistoryViewController.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/23.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "PixivSearchHistoryViewController.h"


@class ScrapingService;


@interface ScrapingSearchHistoryViewController : PixivSearchHistoryViewController

@property(readwrite, nonatomic, retain) NSString *serviceName;
@property(readonly, nonatomic, assign) ScrapingService *service;

@end
