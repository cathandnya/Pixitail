//
//  ScrapingTopViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingTopViewController.h"
#import "ScrapingService.h"
#import "ConstantsManager.h"
#import "PixListThumbnail.h"
#import "AccountManager.h"
#import "ScrapingMatrixViewController.h"


@implementation ScrapingTopViewController

@synthesize serviceName;
@dynamic service;

- (void) dealloc {
	self.serviceName = nil;
	[super dealloc];
}

- (PixService *) pixiv {
	return [ScrapingService serviceFromName:self.serviceName];
}

- (ScrapingService *) service {
	return (ScrapingService *)[self pixiv];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[[self service].constants valueForKeyPath:@"menu"] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDictionary *dic = [[[self service].constants valueForKeyPath:@"menu"] objectAtIndex:section];
	return [[dic objectForKey:@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDictionary *dic = [[[self service].constants valueForKeyPath:@"menu"] objectAtIndex:section];
	return [dic objectForKey:@"title"];
}

- (NSUInteger) indexForIndexPath:(NSIndexPath *)path {
	NSUInteger idx = 0;
	
	for (NSUInteger i = 0; i < path.section; i++) {
		idx += [self tableView:self.tableView numberOfRowsInSection:i];
	}
	idx += path.row;
	
	return idx;
}

- (NSString *) searchMethodForTerm:(NSString *)str {
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.search"], encodeURIComponent(str)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	UIImage			*img = nil;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSDictionary *sec = [[[self service].constants valueForKeyPath:@"menu"] objectAtIndex:indexPath.section];
	NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:indexPath.row];
	
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.textLabel.text = [row objectForKey:@"name"];
	
	NSString *method = [row objectForKey:@"method"];
	if ([method isEqual:@"search_history"]) {
		NSArray *ary = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@SerchHistory", self.serviceName]];
		if ([ary count] > 0) {
			NSDictionary *info = [ary objectAtIndex:0];
			method = [self searchMethodForTerm:[info objectForKey:@"Term"]];
		} else {
			method = nil;
		}
	}
	img = [self.account.thumbnail imageWithMethod:method];
	cell.imageView.contentMode = UIViewContentModeScaleToFill;
	cell.imageView.image = img;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UIViewController		*controller = nil;
	
	NSDictionary *sec = [[[self service].constants valueForKeyPath:@"menu"] objectAtIndex:indexPath.section];
	NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:indexPath.row];
	
	PixivMatrixViewController	*pixiv = nil;
	NSString *className = [row objectForKey:@"class"];
	if (className) {
		NSString *nibName = nil;
		if (![[row objectForKey:@"no_nib"] boolValue]) {
			nibName = [row objectForKey:@"nib"];
			if (!nibName) {
				nibName = className;
			}
		}
		
		Class matrixClass = NSClassFromString(className);
		if (matrixClass) {
			if (nibName) {
				pixiv = [[[matrixClass alloc] initWithNibName:nibName bundle:nil] autorelease];
			} else {
				pixiv = [[[matrixClass alloc] init] autorelease];
			}
		}
	} else {
		Class matrixClass = NSClassFromString([NSString stringWithFormat:@"%@MatrixViewController", self.serviceName]);
		if (!matrixClass) {
			matrixClass = [ScrapingMatrixViewController class];
		}
		pixiv = [[[matrixClass alloc] init] autorelease];
	}
	if ([pixiv respondsToSelector:@selector(setMethod:)]) {
		[pixiv performSelector:@selector(setMethod:) withObject:[row objectForKey:@"method"]];
	}
	if ([pixiv respondsToSelector:@selector(setScrapingInfoKey:)]) {
		[pixiv performSelector:@selector(setScrapingInfoKey:) withObject:[row objectForKey:@"parser"]];
	}
	if ([pixiv respondsToSelector:@selector(setServiceName:)]) {
		[pixiv performSelector:@selector(setServiceName:) withObject:self.serviceName];
	}
	
	if ([pixiv isKindOfClass:[UIViewController class]]) {
		pixiv.navigationItem.title = [row objectForKey:@"name"];
		controller = pixiv;
	}
	pixiv.account = self.account;
	
	if (controller) {
		[self.navigationController pushViewController:controller animated:YES];
	}
}

@end
