//
//  SeigaSearchHistoryViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/23.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaSearchHistoryViewController.h"
#import "SeigaMatixViewController.h"
#import "SeigaConstants.h"
#import "Seiga.h"
#import "PixListThumbnail.h"
#import "AccountManager.h"


@implementation SeigaSearchHistoryViewController

- (NSString *) defaultName {
	return @"SeigaSerchHistory";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SearchHistoryCell";
    NSArray *list = [self list];
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	    
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	if (indexPath.row < [list count]) {
		NSDictionary *info = [list objectAtIndex:indexPath.row];
		cell.textLabel.text = [info objectForKey:@"Term"];
		cell.imageView.image = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:[info objectForKey:@"Scope"]], encodeURIComponent([info objectForKey:@"Term"])]];
		if ([[info objectForKey:@"Scope"] isEqual:@"urls.tag"]) {
			cell.detailTextLabel.text = NSLocalizedString(@"Tags", nil);
		} else if ([[info objectForKey:@"Scope"] isEqual:@"urls.search"]) {
			cell.detailTextLabel.text = NSLocalizedString(@"All", nil);
		}
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = [self list];
	if (indexPath.row < [list count]) {
		NSDictionary *info = [list objectAtIndex:indexPath.row];
		
		SeigaMatixViewController * controller = [[SeigaMatixViewController alloc] init];
		controller.method = [NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:[info objectForKey:@"Scope"]], encodeURIComponent([info objectForKey:@"Term"])];
		controller.account = self.account;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

@end
