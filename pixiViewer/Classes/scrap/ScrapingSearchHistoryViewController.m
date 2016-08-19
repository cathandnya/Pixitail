//
//  SeigaSearchHistoryViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/23.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingSearchHistoryViewController.h"
#import "ScrapingMatrixViewController.h"
#import "PixListThumbnail.h"
#import "AccountManager.h"
#import "ScrapingService.h"
#import "ScrapingConstants.h"


@implementation ScrapingSearchHistoryViewController

@synthesize serviceName;
@dynamic service;

- (void) dealloc {
	self.serviceName = nil;
	[super dealloc];
}

- (PixService *) pixiv {
	return [ScrapingService serviceFromName:serviceName];
}

- (ScrapingService *) service {
	return (ScrapingService *)[self pixiv];
}

- (NSString *) defaultName {
	return [NSString stringWithFormat:@"%@SerchHistory", self.serviceName];
}

- (NSString *) methodForTerm:(NSString *)str {
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.search"], encodeURIComponent(str)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SearchHistoryCell";
    NSArray *list = [self list];
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	    
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	if (indexPath.row < [list count]) {
		NSDictionary *info = [list objectAtIndex:indexPath.row];
		cell.textLabel.text = [info objectForKey:@"Term"];
		cell.imageView.image = [self.account.thumbnail imageWithMethod:[self methodForTerm:cell.textLabel.text]];
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = [self list];
	if (indexPath.row < [list count]) {
		NSDictionary *info = [list objectAtIndex:indexPath.row];
		
		Class class = NSClassFromString([NSString stringWithFormat:@"%@MatrixViewController", serviceName]);
		if (!class) {
			class = [ScrapingMatrixViewController class];
		}
		ScrapingMatrixViewController *controller = [[class alloc] init];
		controller.method = [self methodForTerm:[info objectForKey:@"Term"]];
		controller.account = self.account;
		controller.serviceName = self.serviceName;
		controller.title = [info objectForKey:@"Term"];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

@end
