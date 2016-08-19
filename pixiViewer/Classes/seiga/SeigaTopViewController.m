//
//  SeigaTopViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/22.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaTopViewController.h"
#import "Seiga.h"
#import "AccountManager.h"
#import "SeigaConstants.h"
#import "PixListThumbnail.h"
#import "SeigaMatixViewController.h"


static NSString *searchHistoryMethod() {
	NSArray *ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"SeigaSerchHistory"];
	if ([ary count] > 0) {
		NSDictionary *info = [ary objectAtIndex:0];
		return [NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:[info objectForKey:@"Scope"]], encodeURIComponent([info objectForKey:@"Term"])];
	}
	return nil;
}


@implementation SeigaTopViewController

- (PixService *) pixiv {
	return [Seiga sharedInstance];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[[SeigaConstants sharedInstance] valueForKeyPath:@"menu"] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDictionary *dic = [[[SeigaConstants sharedInstance] valueForKeyPath:@"menu"] objectAtIndex:section];
	return [[dic objectForKey:@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDictionary *dic = [[[SeigaConstants sharedInstance] valueForKeyPath:@"menu"] objectAtIndex:section];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	UIImage			*img = nil;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSDictionary *sec = [[[SeigaConstants sharedInstance] valueForKeyPath:@"menu"] objectAtIndex:indexPath.section];
	NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:indexPath.row];
	
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.textLabel.text = [row objectForKey:@"name"];
	
	NSString *method = [row objectForKey:@"method"];
	if ([method isEqual:@"search_history"]) {
		method = searchHistoryMethod();
	}
	img = [self.account.thumbnail imageWithMethod:method];
	cell.imageView.contentMode = UIViewContentModeScaleToFill;
	cell.imageView.image = img;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController		*controller = nil;
	
	NSDictionary *sec = [[[SeigaConstants sharedInstance] valueForKeyPath:@"menu"] objectAtIndex:indexPath.section];
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
		if (nibName) {
			pixiv = [[[NSClassFromString(className) alloc] initWithNibName:nibName bundle:nil] autorelease];
		} else {
			pixiv = [[[NSClassFromString(className) alloc] init] autorelease];
		}
	} else {
		pixiv = [[[SeigaMatixViewController alloc] init] autorelease];
	}
	if ([pixiv respondsToSelector:@selector(setMethod:)]) {
		[pixiv performSelector:@selector(setMethod:) withObject:[row objectForKey:@"method"]];
	}
	if ([pixiv respondsToSelector:@selector(setScrapingInfoKey:)]) {
		[pixiv performSelector:@selector(setScrapingInfoKey:) withObject:[row objectForKey:@"parser"]];
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
