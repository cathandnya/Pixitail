//
//  TinamiSearchHistoryViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiSearchHistoryViewController.h"
#import "PixListThumbnail.h"
#import "TinamiMatrixViewController.h"
#import "AccountManager.h"
#import "PixService.h"


@implementation TinamiSearchHistoryViewController

- (NSString *) defaultName {
	return @"SerchHistoryTinami";
}

// Customize the appearance of table view cells.
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
		NSArray *ary = [[info objectForKey:@"Type"] componentsSeparatedByString:@"="];
		NSArray *sortary = [[info objectForKey:@"Sort"] componentsSeparatedByString:@"="];
		NSMutableString *detail = [NSMutableString string];
		
		cell.textLabel.text = [info objectForKey:@"Term"];
		if ([ary count] == 2) {
			NSString *t = nil;
			switch ([[ary objectAtIndex:1] intValue]) {
			case 1:
				t = @"illust";
				break;
			case 2:
				t = @"manga";
				break;
			case 3:
				t = @"model";
				break;
			case 5:
				t = @"cosplay";
				break;
			default:
				break;
			}
			[detail  appendString:NSLocalizedString(t, nil)];
		}
		if ([sortary count] == 2) {
			if ([detail length] > 0) [detail appendString:@" / "];
			[detail appendString:NSLocalizedString([sortary objectAtIndex:1], nil)];
		}
		cell.detailTextLabel.text = detail;
		cell.imageView.image = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:@"content/search?%@&%@&%@", [NSString stringWithFormat:[info objectForKey:@"Scope"], encodeURIComponent([info objectForKey:@"Term"])], [info objectForKey:@"Type"], [info objectForKey:@"Sort"]]];
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = [self list];
	if (indexPath.row < [list count]) {
		NSDictionary *info = [list objectAtIndex:indexPath.row];
		
		TinamiMatrixViewController * controller = [[TinamiMatrixViewController alloc] init];
		controller.method = [NSString stringWithFormat:@"content/search?%@&%@&%@", [NSString stringWithFormat:[info objectForKey:@"Scope"], encodeURIComponent([info objectForKey:@"Term"])], [info objectForKey:@"Type"], [info objectForKey:@"Sort"]];
		controller.account = self.account;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

@end
