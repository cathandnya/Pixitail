//
//  AccountListViewController.m
//  pixiViewer
//
//  Created by nya on 09/12/16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AccountListViewController.h"
#import "AccountManager.h"
#import "SettingViewController.h"
#import "PixivTopViewController.h"
#import "PixaTopViewController.h"
#import <GoogleMobileAds/GADBannerView.h>
#import "TinamiTopViewController.h"
#import "AdmobHeaderView.h"
#import "DanbooruTopViewController.h"
#import "AccountsViewController.h"
#import "PixiViewerAppDelegate.h"
#import "SeigaTopViewController.h"
#import "ScrapingTopViewController.h"


@implementation AccountListViewController

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (id) init {
	self = [super init];
	if (self) {
		initial = YES;
	}
	return self;
}

- (void) goLastService {
	if (initial) {
		NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastAccount"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastAccount"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		if (info) {
			PixAccount *acc = [PixAccount accountWithInfo:info];
			NSUInteger idx = [[AccountManager sharedInstance].accounts indexOfObject:acc];
			if (idx != NSNotFound) {
				[self didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:YES];
				//[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
			}
		}
	}
	initial = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	//self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(add)] autorelease];

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationController.navigationBar.translucent = YES;
	self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationController.toolbar.translucent = YES;
	
#ifndef PIXITAIL
	UIImage *logo = [UIImage imageNamed:@"top.png"];
	UIImageView *logoView = [[[UIImageView alloc] initWithImage:logo] autorelease];
	CGRect r = logoView.frame;
	logoView.contentMode = UIViewContentModeBottom;
	r.size.height += 5;
	logoView.frame = r;
	self.navigationItem.titleView = logoView;
#else
	self.title = @"Pixitail";
	CGRect r;
#endif

#ifndef NDEBUG
	//[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DisableAd"];
	//[[NSUserDefaults standardUserDefaults] synchronize];
#endif
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisableAd"] == NO) {
		UIViewController *adroot;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			adroot = (UIViewController *)((PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate).alwaysSplitViewController;
		} else {
			adroot = self;
		}
		
		UIView *header = [[[AdmobHeaderView alloc] initWithViewController:adroot] autorelease];
		r = header.frame;
		r.size.width = self.view.frame.size.width;
		header.frame = r;
		self.tableView.tableHeaderView = header;//[[[AdmobHeaderBGView alloc] init] autorelease];
	}
	
	if (initial) {
		if ([[AccountManager sharedInstance].accounts count] == 0 || ([[AccountManager sharedInstance].accounts count] == 1 && ((PixAccount *)[[AccountManager sharedInstance].accounts objectAtIndex:0]).anonymous && [((PixAccount *)[[AccountManager sharedInstance].accounts objectAtIndex:0]).serviceName isEqualToString:@"TINAMI"])) {
			[self performSelector:@selector(editAction:) withObject:nil afterDelay:0.1];
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDisplay:) name:@"AccountListViewNeedsUpdateNotification" object:nil];
}

- (void) updateDisplay:(NSNotification *)notif {
	[self.tableView reloadData];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisableAd"]) {
		self.tableView.tableHeaderView = nil;
	}
	
	[self.navigationController setToolbarHidden:YES animated:NO];
	//[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController setNavigationBarHidden:NO animated:NO];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	
	//[UIApplication sharedApplication].statusBarHidden = YES;
	//[UIApplication sharedApplication].statusBarHidden = NO;
	
	//[self.view.superview.superview setNeedsLayout];

	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(add)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"アカウント" style:UIBarButtonItemStyleBordered target:self action:@selector(editAction:)] autorelease];
	
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	[self.tableView reloadData];	
	
	//[self.navigationController setNavigationBarHidden:NO animated:NO];
	//[self performSelector:@selector(goLastService) withObject:nil afterDelay:0.2];

	//[adView requestFreshAd];
	//[self.tableView.tableHeaderView addSubview:[AdmobHeaderView sharedInstance]];

	//self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(add)] autorelease];

	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastAccount"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewWillDisappear:(BOOL)animated {
	//[[AdmobHeaderView sharedInstance] removeFromSuperview];
	[super viewWillDisappear:animated];
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

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
    return [[AccountManager sharedInstance].accounts count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
	if (indexPath.row < 0 || [[AccountManager sharedInstance].accounts count] <= indexPath.row) {
		return nil;
	}

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	PixAccount *acc = [[AccountManager sharedInstance].accounts objectAtIndex:indexPath.row];
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	//cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.textLabel.text = NSLocalizedString(acc.typeString, nil);
	if ([acc.serviceName isEqualToString:@"Danbooru"]) {
		cell.detailTextLabel.text = acc.hostname;
	} else {
		cell.detailTextLabel.text = acc.anonymous ? @"ゲスト" : acc.username;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)b {
	PixAccount *acc = [[AccountManager sharedInstance].accounts objectAtIndex:indexPath.row];
	
	UIViewController *controller = nil;
	if ([acc.serviceName isEqualToString:@"pixiv"]) {
		PixivTopViewController *vc = [[PixivTopViewController alloc] init];
		vc.account = acc;
		controller = vc;
	} else if ([acc.serviceName isEqualToString:@"PiXA"]) {
		PixivTopViewController *vc = [[PixaTopViewController alloc] init];
		vc.account = acc;
		controller = vc;
	} else if ([acc.serviceName isEqualToString:@"TINAMI"]) {
		TinamiTopViewController *vc = [[TinamiTopViewController alloc] init];
		vc.account = acc;
		controller = vc;
#ifndef PIXITAIL
	} else if ([acc.serviceName isEqualToString:@"Danbooru"]) {
		DanbooruTopViewController *vc = [[DanbooruTopViewController alloc] init];
		vc.account = acc;
		controller = vc;
	} else if ([acc.serviceName isEqualToString:@"Seiga"]) {
		SeigaTopViewController *vc = [[SeigaTopViewController alloc] init];
		vc.account = acc;
		controller = vc;
	} else {
		NSString *serviceName = [[PixAccount serviceWithName:acc.serviceName] objectForKey:@"name"];
		Class class = NSClassFromString([NSString stringWithFormat:@"%@TopViewController", serviceName]);
		if (!class) {
			class = [ScrapingTopViewController class];
		}
		ScrapingTopViewController *vc = nil;
		vc = [[class alloc] init];
		vc.account = acc;
		vc.serviceName = serviceName;
		controller = vc;
#endif
	}
		
	[self.navigationController pushViewController:controller animated:b];

	PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
	[app login:(PixivTopViewController *)controller];

	[controller release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self didSelectRowAtIndexPath:indexPath animated:YES];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


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


- (void)dealloc {
    [super dealloc];
}


- (void) add {
	SettingViewController *vc = [[SettingViewController alloc] init];
	UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		nv.modalPresentationStyle = UIModalPresentationFormSheet;
		UINavigationController *app = (UINavigationController *)[UIApplication sharedApplication].delegate;
		[app presentModalViewController:nv animated:YES];
	} else {
		[self presentModalViewController:nv animated:YES];
	}
	[nv release];
	[vc release];
}

- (void) editAction:(id)sender {
	AccountsViewController *vc = [[AccountsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		nv.modalPresentationStyle = UIModalPresentationFormSheet;
		UINavigationController *app = (UINavigationController *)[UIApplication sharedApplication].delegate;
		[app presentModalViewController:nv animated:YES];
	} else {
		[self presentModalViewController:nv animated:YES];
	}
	[nv release];
	[vc release];
}

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	return [super storeInfo];
}

- (BOOL) needsStore {
	return YES;
}

@end

