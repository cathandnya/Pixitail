//
//  PixivTagListController.m
//  pixiViewer
//
//  Created by nya on 09/10/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivTagListController.h"
#import "PixivMatrixViewController.h"
#import "PixListThumbnail.h"
#import "AccountManager.h"
#import "PixService.h"


@implementation PixivTagListController

@synthesize account;

- (NSString *) saveName {
	return @"SavedTags";
}

- (Class) matrixClass {
	return [PixivMatrixViewController class];
}

- (NSString *) methodWithTag:(NSString *)tag {
	NSData				*data = [tag dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*method = [NSMutableString stringWithString:@"tags.php?tag="];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[method appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	[method appendString:@"&"];
	
	return method;
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void) dealloc {
	[tags_ release];
	[account release];
	
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.rowHeight = 44;
	
	if (tags_ == nil) {
		tags_ = [[[NSUserDefaults standardUserDefaults] objectForKey:[self saveName]] mutableCopy];
		if (tags_ == nil) {
			tags_ = [[NSMutableArray alloc] init];
		}
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	UIBarButtonItem	*right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
	[right setEnabled:YES];
	self.navigationItem.rightBarButtonItem = right;
	[right release];

    [super viewWillAppear:animated];

	[self.navigationController setToolbarHidden:YES animated:YES];
	[((UITableView *)self.view) reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	//[self.navigationController setToolbarHidden:YES animated:NO];
	//[((UITableView *)self.view) reloadData];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tags_ count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TagCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	if (indexPath.row < [tags_ count]) {
		cell.textLabel.text = [tags_ objectAtIndex:indexPath.row];
		cell.imageView.image = [self.account.thumbnail imageWithMethod:[self methodWithTag:[tags_ objectAtIndex:indexPath.row]]];
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row >= [tags_ count]) {
		return;
	}

	PixivMatrixViewController *controller = [[[self matrixClass] alloc] init];
	controller.method = [self methodWithTag:[tags_ objectAtIndex:indexPath.row]];
	controller.navigationItem.title = [tags_ objectAtIndex:indexPath.row];
	controller.account = self.account;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		[tags_ removeObjectAtIndex:indexPath.row];

		[[NSUserDefaults standardUserDefaults] setObject:tags_ forKey:[self saveName]];
		[[NSUserDefaults standardUserDefaults] synchronize];

		[tableView reloadData];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	id	obj = [[tags_ objectAtIndex:fromIndexPath.row] retain];
	[tags_ insertObject:obj atIndex:toIndexPath.row];
	[tags_ removeObjectAtIndex:fromIndexPath.row];
	[obj release];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

- (void) add {
	PixivTagAddViewController	*controller = [[PixivTagAddViewController alloc] initWithNibName:@"PixivTagAddViewController" bundle:nil];
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
	NSArray		*ary = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	for (NSString *s in ary) {
		if ([s length] > 0) {
			if ([tags_ containsObject:s]) {
				[tags_ removeObject:s];
			}
			[tags_ insertObject:s atIndex:0];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:tags_ forKey:[self saveName]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[(UITableView *)self.view reloadData];
	[self dismissModalViewControllerAnimated:YES];	
}

#pragma mark-

/*
- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[self hideProgress];
	if (err) {
		// もいっかい
		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			[self.navigationController popToRootViewControllerAnimated:YES];
			return;
		}
	}
}
*/

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:[account info] forKey:@"Account"];

	return info;
}

- (BOOL) needsStore {
	return YES;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
	obj = [info objectForKey:@"Account"];
	PixAccount *acc = [[AccountManager sharedInstance] accountWithInfo:obj];
	if (acc == nil) {
		return NO;
	}	
	self.account = acc;

	return YES;
}

@end

