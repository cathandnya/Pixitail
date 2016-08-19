//
//  fgPagingMatrixViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 12/01/02.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "fgPagingMatrixViewController.h"
#import "ScrapingService.h"


@implementation fgPagingMatrixViewController

- (NSString *) urlString {
	NSString *str;
	if (loadedPage_ == 0) {
		str = [NSString stringWithFormat:@"%@%@", [self.service.constants valueForKeyPath:@"urls.base"], self.method];
	} else {
		NSString *m = self.method;
		if (![m hasSuffix:@"/"]) {
			m = [m stringByAppendingString:@"/"];
		}
		str = [NSString stringWithFormat:@"%@%@%@", [self.service.constants valueForKeyPath:@"urls.base"], m, [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"constants.page_param"], loadedPage_ + 1]];
	}
	return str;
}

@end


@implementation fgRescentMatrixViewController

- (NSString *) urlString {
	NSString *str;
	if (loadedPage_ == 0) {
		str = [NSString stringWithFormat:@"%@%@", [self.service.constants valueForKeyPath:@"urls.base"], self.method];
	} else {
		str = [NSString stringWithFormat:@"%@%@%d", [self.service.constants valueForKeyPath:@"urls.base"], self.method, loadedPage_ + 1];
	}
	return str;
}

@end


@implementation fgMatrixViewController

@end
