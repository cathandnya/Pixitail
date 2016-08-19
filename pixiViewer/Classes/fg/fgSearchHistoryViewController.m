//
//  fgSearchHistoryViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import "fgSearchHistoryViewController.h"
#import "ScrapingService.h"
#import "ScrapingConstants.h"
#import "ScrapingMatrixViewController.h"


@interface fgSearchHistoryResultViewController : ScrapingMatrixViewController

@property(readwrite, nonatomic, retain) NSString *searchTerm;

@end


@implementation fgSearchHistoryResultViewController

@synthesize searchTerm;

- (void) dealloc {
	self.searchTerm = nil;
	[super dealloc];
}

- (NSString *) urlString {
	return [[self.service.constants valueForKeyPath:@"urls.base"] stringByAppendingFormat:[self.service.constants valueForKeyPath:@"urls.search"], loadedPage_ + 1, encodeURIComponent(searchTerm)];
}

@end


@implementation fgSearchHistoryViewController

- (NSString *) methodForTerm:(NSString *)str {
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.search"], 1, encodeURIComponent(str)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = [self list];
	if (indexPath.row < [list count]) {
		NSDictionary *info = [list objectAtIndex:indexPath.row];
		
		fgSearchHistoryResultViewController *controller = [[fgSearchHistoryResultViewController alloc] init];
		controller.method = [self methodForTerm:[info objectForKey:@"Term"]];
		controller.searchTerm = [info objectForKey:@"Term"];
		controller.account = self.account;
		controller.serviceName = self.serviceName;
		controller.title = [info objectForKey:@"Term"];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

@end
