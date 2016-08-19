//
//  DanbooruSearchHistoryViewController.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DanbooruSearchHistoryViewController.h"
#import "PixListThumbnail.h"
#import "AccountManager.h"
#import "Danbooru.h"
#import "DanbooruMatrixViewController.h"


@implementation DanbooruSearchHistoryViewController

- (NSString *) defaultName {
	return @"SerchHistoryDanbooru";
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
		NSString *term = [list objectAtIndex:indexPath.row];
		cell.textLabel.text = term;
		cell.imageView.image = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:@"http://%@/post/index.json?tags=%@", account.hostname, encodeURIComponent(term)]];
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = [self list];
	if (indexPath.row < [list count]) {
		NSString *term = [list objectAtIndex:indexPath.row];		
		DanbooruMatrixViewController * controller = [[DanbooruMatrixViewController alloc] init];
		controller.method = [NSString stringWithFormat:@"http://%@/post/index.json?tags=%@", account.hostname, encodeURIComponent(term)];
		controller.account = self.account;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

@end
