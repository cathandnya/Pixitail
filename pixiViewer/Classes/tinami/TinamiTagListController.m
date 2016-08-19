//
//  TinamiTagListController.m
//  pixiViewer
//
//  Created by nya on 10/02/28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiTagListController.h"
#import "TinamiMatrixViewController.h"
#import "PixListThumbnail.h"
#import "TinamiTagAddViewController.h"
#import "AccountManager.h"


@implementation TinamiTagListController

- (NSString *) saveName {
	return @"SavedTagsTinami";
}

- (Class) matrixClass {
	return [TinamiMatrixViewController class];
}

+ (NSString *) methodWithTag:(NSDictionary *)info {
	NSString *tag = [info objectForKey:@"Tag"];
	NSString *type = [info objectForKey:@"Type"];

	NSData				*data = [tag dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*method = [NSMutableString stringWithString:@"content/search?tags="];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[method appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	if (type) {
		[method appendFormat:@"&cont_type[]=%@", type];
	}
	
	return method;
}

+ (NSString *) firstTagMethod {
	NSArray *ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedTagsTinami"];
	if ([ary count] > 0) {
		return [TinamiTagListController methodWithTag:[ary objectAtIndex:0]];
	} else {
		return @"";
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TagCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	if (indexPath.row < [tags_ count]) {
		NSDictionary *tag = [tags_ objectAtIndex:indexPath.row];
		NSString *tagName = [tag objectForKey:@"Tag"];

		NSString *t = nil;
		switch ([[tag objectForKey:@"Type"] intValue]) {
		case 1:
			t = @"illust";
			break;
		case 2:
			t = @"manga";
			break;
		case 3:
			t = @"model";
			break;
		case 4:
			t = @"novel";
			break;
		case 5:
			t = @"cosplay";
			break;
		default:
			break;
		}
		NSString *typeName = t ? NSLocalizedString(t, nil) : @"全て";

		cell.textLabel.text = tagName;
		cell.detailTextLabel.text = typeName;
		cell.imageView.image = [self.account.thumbnail imageWithMethod:[[self class] methodWithTag:[tags_ objectAtIndex:indexPath.row]]];
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row >= [tags_ count]) {
		return;
	}

	PixivMatrixViewController *controller = [[[self matrixClass] alloc] init];
	controller.method = [[self class] methodWithTag:[tags_ objectAtIndex:indexPath.row]];
	controller.navigationItem.title = [[tags_ objectAtIndex:indexPath.row] objectForKey:@"Tag"];
	controller.account = self.account;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void) add {
	TinamiTagAddViewController	*controller = [[TinamiTagAddViewController alloc] initWithNibName:@"TinamiTagAddViewController" bundle:nil];
	controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	controller.delegate = self;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) controller.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:controller animated:YES];
	[controller release];
}

- (void) tagAddViewCancel:(PixivTagAddViewController *)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) tagAddView:(PixivTagAddViewController *)sender done:(NSDictionary *)info {
	NSString	*str = [info objectForKey:@"Tag"];
	NSString	*type = [info objectForKey:@"Type"];
	NSArray		*ary = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	for (NSString *s in ary) {
		if ([s length] > 0) {
			NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
				str,	@"Tag",
				type,	@"Type",
				nil];
			if ([tags_ containsObject:dic]) {
				[tags_ removeObject:dic];
			}
			[tags_ insertObject:dic atIndex:0];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:tags_ forKey:[self saveName]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[(UITableView *)self.view reloadData];
	[self dismissModalViewControllerAnimated:YES];	
}

@end
