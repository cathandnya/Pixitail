//
//  fgSearchViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "fgSearchViewController.h"
#import "ScrapingService.h"
#import "ScrapingConstants.h"


@implementation fgSearchViewController

- (id) init {
	self = [super initWithNibName:@"ScrapingSearchViewController" bundle:nil];
	if (self) {
	}
	return self;
}

- (NSString *) methodString {
	if (searchTerm.length == 0) {
		return nil;
	}
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.search"], loadedPage_ + 1, encodeURIComponent(searchTerm)];
}

- (NSString *) urlString {
	NSString *str =  [NSString stringWithFormat:@"%@%@", [self.service.constants valueForKeyPath:@"urls.base"], [self methodString]];
	return str;
}

@end
