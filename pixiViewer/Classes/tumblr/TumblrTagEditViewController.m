//
//  TumblrTagEditViewController.m
//  pixiViewer
//
//  Created by nya on 10/05/30.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrTagEditViewController.h"
#import "TumblrTagCloudViewController.h"
#import "Tag.h"
#import "Tumblr.h"


@interface TumblrTagEditCloudViewController : TumblrTagCloudViewController {
	NSArray *originalTags;
	NSMutableArray *tags;
	id delegate;
}

@property(readwrite, nonatomic, copy) NSArray *originalTags;
@property(readwrite, nonatomic, copy) NSArray *tags;
@property(readwrite, nonatomic, assign) id delegate;

@end


@implementation TumblrTagEditCloudViewController

@synthesize originalTags, tags, delegate;

- (void) dealloc {
	[originalTags release];
	[tags release];
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"タグクラウド";
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cloudDone:)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cloudCancel:)] autorelease];
	
	[tags release];
	if (originalTags) {
		tags = [originalTags mutableCopy];
	} else {
		tags = [[NSMutableArray alloc] init];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	Tag *tag = [list objectAtIndex:indexPath.row];
	cell.accessoryType = ([tags containsObject:tag.name] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];

	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	Tag *tag = [list objectAtIndex:indexPath.row];
	if ([tags indexOfObject:tag.name] != NSNotFound) {
		[tags removeObjectAtIndex:[tags indexOfObject:tag.name]];
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		[tags addObject:tag.name];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
}

- (void) cloudDone:(id)sender {
	[delegate performSelector:@selector(cloudDone:) withObject:self];
}

- (void) cloudCancel:(id)sender {
	[delegate performSelector:@selector(cloudCancel:) withObject:self];
}

@end


@implementation TumblrTagEditViewController

@synthesize tags, delegate, account;

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"タグの編集";
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.tableView.allowsSelection = YES;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
	
	if (tags) {
		list = [tags mutableCopy];
	} else {
		list = [[NSMutableArray alloc] init];
	}
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.tableView reloadData];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return [list count];
	} else {
		return 2;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	if (indexPath.section == 0) {
		cell.textLabel.text = [list objectAtIndex:indexPath.row];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if (indexPath.row == 0) {
			cell.textLabel.text = @"追加";
		} else {
			cell.textLabel.text = @"タグクラウドから追加";
		}
	}
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	if (indexPath.section == 0) {
		return YES;
	} else {
		return NO;
	}
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		[list removeObjectAtIndex:indexPath.row];
		
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 1) {
		if (indexPath.row == 0) {
			// 追加
			PixivTagAddViewController *vc = [[[PixivTagAddViewController alloc] initWithNibName:@"PixivTagAddViewController" bundle:nil] autorelease];
			vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
			vc.delegate = self;
			vc.type = @"TagAdd";
			vc.titleString = @"タグの追加";
			vc.maxCount = -1;
			[self.navigationController pushViewController:vc animated:YES];
		} else {
			// タグクラウド
			TumblrTagEditCloudViewController *vc = [[[TumblrTagEditCloudViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
			vc.delegate = self;
			vc.originalTags = list;
			vc.account = account;
			vc.name = [Tumblr instance].name;
			[self.navigationController pushViewController:vc animated:YES];
		}
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc {
	[tags release];
	[list release];
	[account release];
    [super dealloc];
}

- (void) done {
	self.tags = list;
	[delegate tagEditView:self done:YES];
}

- (void) cancel {
	[delegate tagEditView:self done:NO];
}

- (void) tagAddViewCancel:(PixivTagAddViewController *)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) tagAddView:(PixivTagAddViewController *)sender done:(NSDictionary *)info {
	NSString *str = [info objectForKey:@"Tag"];	
	if ([str length] > 0 && [list containsObject:str] == NO) {
		[list addObject:str];
	}
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) cloudDone:(TumblrTagEditCloudViewController *)sender {
	TumblrTagEditCloudViewController *vc = sender;
	
	for (NSString *str in vc.originalTags) {
		if ([vc.tags containsObject:str] == NO && [list indexOfObject:str] != NSNotFound) {
			[list removeObjectAtIndex:[list indexOfObject:str]];
		}
	}
	
	for (NSString *str in vc.tags) {
		if ([list containsObject:str] == NO) {
			[list addObject:str];
		}
	}
	
	[self.navigationController popViewControllerAnimated:YES];	
}

- (void) cloudCancel:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];

}

@end

