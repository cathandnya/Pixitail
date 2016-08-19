//
//  SettingViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingViewController.h"
#import "AccountManager.h"
#import "CHGroupTableView.h"
#import "AccountViewController.h"
#import "SlideshowPeriodSettingViewController.h"
#import "SlideshowDisplaySettingViewController.h"
#import "Reachability.h"
#import "TwitterFormatViewController.h"
#import "LicenseViewController.h"
#import "DisableAdViewController.h"
#import "DropBoxTail.h"
#import "UserDefaults.h"
#import "TumblrAccountViewController.h"
#import "MultiSelectionViewController.h"
#import "ImageDiskCache.h"
#import "ImageLoaderManager.h"
#import "PixitailConstants.h"
#import "SeigaConstants.h"
#import "ScrapingService.h"
#import "GoogleDrive.h"
#import "SugarSync.h"
#import "SugarSyncAccountViewController.h"
#import "EvernoteTail.h"
#import "EvernoteSession.h"
#import "SharedAlertView.h"
#import "TumblrAccountManager.h"
#import "WidgetSettingViewController.h"


static void CHShowAlert(NSString *title, NSString *message) {
	UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, title) message:NSLocalizedString(message, message) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}


@implementation SettingViewController

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (disableSleepSwitch) [[NSUserDefaults standardUserDefaults] setBool:disableSleepSwitch.on forKey:@"SlideshowDisableIdleTimer"];
	if (showClockSwitch) [[NSUserDefaults standardUserDefaults] setBool:showClockSwitch.on forKey:@"SlideshowEnableClock"];
	if (autoRotateSwitch) [[NSUserDefaults standardUserDefaults] setBool:autoRotateSwitch.on forKey:@"Autorotate"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[disableSleepSwitch release];
	disableSleepSwitch = nil;
	[showClockSwitch release];
	showClockSwitch = nil;
	[autoRotateSwitch release];
	autoRotateSwitch = nil;
	
	[saveFolderSwitch release];
	saveFolderSwitch = nil;
	[saveTagsSwitch release];
	saveTagsSwitch = nil;

    [super dealloc];	
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	CHGroupTableView *tv = [[CHGroupTableView alloc] initWithFrame:self.tableView.frame style:UITableViewStyleGrouped];
	tv.delegate = self;
	tv.dataSource = self;
	self.tableView = tv;
	[tv release];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	
	self.title = NSLocalizedString(@"Settings", nil);

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDisplay:) name:@"PreferenceChangedNotification" object:nil];
}

- (void) updateDisplay:(NSNotification *)notif {
	[self.tableView reloadData];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[self.tableView reloadData];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (disableSleepSwitch) [[NSUserDefaults standardUserDefaults] setBool:disableSleepSwitch.on forKey:@"SlideshowDisableIdleTimer"];
	if (showClockSwitch) [[NSUserDefaults standardUserDefaults] setBool:showClockSwitch.on forKey:@"SlideshowEnableClock"];
	if (autoRotateSwitch) [[NSUserDefaults standardUserDefaults] setBool:autoRotateSwitch.on forKey:@"Autorotate"];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[disableSleepSwitch release];
	disableSleepSwitch = nil;
	[showClockSwitch release];
	showClockSwitch = nil;
	[autoRotateSwitch release];
	autoRotateSwitch = nil;
	
	[saveFolderSwitch release];
	saveFolderSwitch = nil;
	[saveTagsSwitch release];
	saveTagsSwitch = nil;
	[saveTagsSwitchTumblr release];
	saveTagsSwitchTumblr = nil;
	[tumblrTweetSwitch release];
	tumblrTweetSwitch = nil;
	
	[super viewDidUnload];
}

#pragma mark-

- (void) done {
	[self.tableView setEditing:NO];
	[self dismissModalViewControllerAnimated:YES];
}

- (NSArray *) accounts {
	return [AccountManager sharedInstance].accounts;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 9;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
	case 0:
		return NSLocalizedString(@"Slideshow", nil);
	case 1:
		return @"表示";
	case 2:
		return NSLocalizedString(@"SaveDist", nil);
	case 3:
		return @"保存";
	case 4:
		return @"共有";
	case 5:
		return NSLocalizedString(@"Other", nil);
	case 6:
		return NSLocalizedString(@"Ad", nil);
	case 7:
		return NSLocalizedString(@"Support", nil);
	case 8:
		return nil;
	default:
		return nil;
	}
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
	case 0:
		return 4;
	case 1:
		return 2;
	case 2:
		return 6;
	case 3:
		return 4;
	case 4:
		return 2;
	case 5:
		return [UIDevice currentDevice].systemVersion.floatValue < 8.0 ? 3 : 4;
	case 6:
		return 1;
	case 7:
		return 2;
	case 8:
		return 1;
	default:
		return 0;
	}
}

/*
- (UIView *)tableView:(UITableView *)atableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		CGRect r;
		UIView *header = [[UIView alloc] init];

		UILabel *label = [[UILabel alloc] init];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont boldSystemFontOfSize:17];
		label.textColor = [UIColor colorWithRed:78.0 / 255 green:88.0 / 255 blue:110.0 / 255 alpha:1.0];
		label.shadowColor = [UIColor whiteColor];
		label.shadowOffset = CGSizeMake(1, 1);
		r.origin.x = 20;
		r.origin.y = 10;
		r.size.width = 160;
		r.size.height = 30;
		label.frame = r;
		label.text = NSLocalizedString(@"PixAccount", nil);
		[header addSubview:label];
		[label release];
		
#ifndef PIXITAIL
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		r.size.width = 70;
		r.size.height = 25;
		r.origin.x = self.view.frame.size.width - 20 - r.size.width;
		r.origin.y = 14;
		btn.frame = r;
		btn.tag = 100;
		btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
		//btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[btn setTitle:NSLocalizedString(@"Reorder", nil) forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(reorder:) forControlEvents:UIControlEventTouchUpInside];
		[header addSubview:btn];		
#endif
		
		return [header autorelease];
	} else {
		return nil;
	}
}

- (void) reorder:(UIButton *)sender {
	NSString *str;
	if (!self.tableView.editing) {
		str = NSLocalizedString(@"Done", nil);
	} else {
		str = NSLocalizedString(@"Reorder", nil);
	}
	[sender setTitle:str forState:UIControlStateNormal];
	
	[self.tableView setEditing:!self.tableView.editing animated:YES];
}
*/

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
    switch (indexPath.section) {
		case 0:		
			switch (indexPath.row) {
				case 0:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Subtitle"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Subtitle"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
						cell.selectionStyle = UITableViewCellSelectionStyleBlue;
					}
					cell.textLabel.text = NSLocalizedString(@"Slideshow period", nil);
					
				{
					NSInteger sec = [[NSUserDefaults standardUserDefaults] integerForKey:@"SlideshowInterval"];
					if (sec == 0) sec = 10;
					if (sec < 60) {
						cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d sec", nil), sec];
					} else {
						cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d min", nil), sec / 60];
					}
				}
					break;
				case 1:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Subtitle"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Subtitle"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
						cell.selectionStyle = UITableViewCellSelectionStyleBlue;
					}
					cell.textLabel.text = NSLocalizedString(@"Slideshow display", nil);
					if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SlideshowDisplay"] isEqualToString:@"AspectFill"]) {
						cell.detailTextLabel.text = NSLocalizedString(@"aspect fill", nil);
					} else {
						cell.detailTextLabel.text = NSLocalizedString(@"aspect fit", nil);
					}
					break;
				case 2:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Switch"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Switch"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryNone;
						cell.selectionStyle = UITableViewCellSelectionStyleNone;
					}
					
					cell.textLabel.text = NSLocalizedString(@"Disable sleep", nil);
					[[cell viewWithTag:100] removeFromSuperview];
					if (disableSleepSwitch == nil) {
						disableSleepSwitch = SwitchForCell(cell);
						disableSleepSwitch.tag = 100;
						[disableSleepSwitch retain];
						disableSleepSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"SlideshowDisableIdleTimer"];
					}
					cell.accessoryView = disableSleepSwitch;
					//[cell addSubview:disableSleepSwitch];
					break;
				case 3:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Switch"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Switch"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryNone;
						cell.selectionStyle = UITableViewCellSelectionStyleNone;
					}
					
					cell.textLabel.text = NSLocalizedString(@"Show clock", nil);
					[[cell viewWithTag:100] removeFromSuperview];
					if (showClockSwitch == nil) {
						showClockSwitch = SwitchForCell(cell);
						showClockSwitch.tag = 100;
						[showClockSwitch retain];
						showClockSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"SlideshowEnableClock"];
					}
					cell.accessoryView = showClockSwitch;
					//[cell addSubview:showClockSwitch];
					break;
				default:
					break;
			}
			break;
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:@"Subtitle"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Subtitle"] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			if (indexPath.row == 0) {
				cell.textLabel.text = @"サムネイルのサイズ";
				NSInteger col = [[NSUserDefaults standardUserDefaults] integerForKey:@"MatrixViewColumnCount"];
				if (col < 2 || 4 < col) {
					col = 4;
				}
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@列", @(col)];
			} else if (indexPath.row == 1) {
				cell.textLabel.text = @"サムネイルの表示";
				if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MatrixViewThumbnailFit"]) {
					cell.detailTextLabel.text = @"拡大して表示";
				} else {
					cell.detailTextLabel.text = @"全体を表示";
				}
			}
			break;
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:@"CheckCell"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CheckCell"] autorelease];
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			if (indexPath.row == 0) {
				cell.textLabel.text = NSLocalizedString(@"SaveToDropBox", nil);
				if ([[DropBoxTail sharedInstance] linked]) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 1) {
				cell.textLabel.text = NSLocalizedString(@"SaveToEvernote", nil);
				if (UDBoolWithDefault(@"SaveToEvernote", NO)) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 2) {
				cell.textLabel.text = @"Tumblr";
				if ([TumblrAccountManager sharedInstance].currentAccount != nil) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 3) {
				cell.textLabel.text = @"SugarSync";
				if (UDBoolWithDefault(@"SaveToSugarSync", NO)) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 4) {
				cell.textLabel.text = @"Googleドライブ";
				if ([GoogleDrive sharedInstance].available) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 5) {
				cell.textLabel.text = @"SkyDrive";
				if (UDBoolWithDefault(@"SaveToSkyDrive", NO)) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			}
			break;
		case 3:
			switch (indexPath.row) {
				case 0:
					if (saveFolderSwitch == nil) {
						saveFolderSwitch = [[UISwitch alloc] init];
						[saveFolderSwitch addTarget:self action:@selector(saveFolderAction:) forControlEvents:UIControlEventValueChanged];
					}
					if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SaveFolder"]) {
						saveFolderSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"SaveFolder"];
					} else {
						saveFolderSwitch.on = YES;
					}
					
					cell = [tableView dequeueReusableCellWithIdentifier:@"SaveFolder"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SaveFolder"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					}
					
					cell.textLabel.text = @"作者名で整理";
					cell.detailTextLabel.text = @"Dropbox保存時に有効です";
					cell.accessoryView = saveFolderSwitch;
					break;
				case 1:
					if (saveTagsSwitch == nil) {
						saveTagsSwitch = [[UISwitch alloc] init];
						[saveTagsSwitch addTarget:self action:@selector(saveTagsAction:) forControlEvents:UIControlEventValueChanged];
					}
					if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SaveTags"]) {
						saveTagsSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"SaveTags"];
					} else {
						saveTagsSwitch.on = YES;
					}
					
					cell = [tableView dequeueReusableCellWithIdentifier:@"SaveTags"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SaveTags"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					}
					
					cell.textLabel.text = @"タグを保存";
					cell.detailTextLabel.text = @"Evernote保存時に有効です";
					cell.accessoryView = saveTagsSwitch;
					break;
				case 2:
					if (saveTagsSwitchTumblr == nil) {
						saveTagsSwitchTumblr = [[UISwitch alloc] init];
						[saveTagsSwitchTumblr addTarget:self action:@selector(saveTagsTumblrAction:) forControlEvents:UIControlEventValueChanged];
					}
					if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SaveTagsTumblr"]) {
						saveTagsSwitchTumblr.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"SaveTagsTumblr"];
					} else {
						saveTagsSwitchTumblr.on = YES;
					}
					
					cell = [tableView dequeueReusableCellWithIdentifier:@"SaveTagsTumblr"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SaveTagsTumblr"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					}
					
					cell.textLabel.text = @"タグを保存";
					cell.detailTextLabel.text = @"Tumblr投稿時に有効です";
					cell.accessoryView = saveTagsSwitchTumblr;
					break;
				case 3:
					if (tumblrTweetSwitch == nil) {
						tumblrTweetSwitch = [[UISwitch alloc] init];
						[tumblrTweetSwitch addTarget:self action:@selector(tumblrTweetSwitchAction:) forControlEvents:UIControlEventValueChanged];
					}
					if ([[NSUserDefaults standardUserDefaults] objectForKey:@"TumblrTweet"]) {
						tumblrTweetSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"TumblrTweet"];
					} else {
						tumblrTweetSwitch.on = NO;
					}
					
					cell = [tableView dequeueReusableCellWithIdentifier:@"TumblrTweet"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TumblrTweet"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					}
					
					cell.textLabel.text = @"投稿時にツイート";
					cell.detailTextLabel.text = @"Tumblrで設定が必要";
					cell.accessoryView = tumblrTweetSwitch;
					break;
				default:
					break;
			}
			break;
		case 4:
			switch (indexPath.row) {
				case 0:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Default"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Default"] autorelease];
					}
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					
					cell.textLabel.text = @"ツイートのフォーマット";
					break;
				case 1:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Default"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Default"] autorelease];
					}
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					
					cell.textLabel.text = @"Tumblr投稿のフォーマット";
			}
			break;
		case 5:
			switch (indexPath.row) {
				case 0:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Default"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Default"] autorelease];
					}
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.textLabel.text = @"キャッシュのクリア";
					break;
				case 1:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Switch"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Switch"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryNone;
						cell.selectionStyle = UITableViewCellSelectionStyleNone;
					}
					cell.textLabel.text = NSLocalizedString(@"Auto rotate", nil);
					[[cell viewWithTag:100] removeFromSuperview];
					if (autoRotateSwitch == nil) {
						autoRotateSwitch = SwitchForCell(cell);
						autoRotateSwitch.tag = 100;
						[autoRotateSwitch retain];
						if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Autorotate"]) {
							autoRotateSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"Autorotate"];
						} else {
							autoRotateSwitch.on = YES;
						}
					}
					cell.accessoryView = autoRotateSwitch;
					//[cell addSubview:autoRotateSwitch];
					break;
					
				case 2:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Switch"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Switch"] autorelease];
						cell.accessoryType = UITableViewCellAccessoryNone;
						cell.selectionStyle = UITableViewCellSelectionStyleNone;
					}
					cell = [tableView dequeueReusableCellWithIdentifier:@"Subtitle"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Subtitle"] autorelease];
					}
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.textLabel.text = NSLocalizedString(@"Passcode lock", nil);
					if (UDStringWithDefault(@"Passcode", nil).length == 4) {
						cell.detailTextLabel.text = NSLocalizedString(@"Passcode lock is enable", nil);
					} else {
						cell.detailTextLabel.text = NSLocalizedString(@"Passcode lock is disable", nil);
					}
					break;
					
				case 3:
					cell = [tableView dequeueReusableCellWithIdentifier:@"Default"];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Default"] autorelease];
					}
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.text = @"ウィジェット";
					break;
				default:
					break;
			}
			break;
		case 6:
			cell = [tableView dequeueReusableCellWithIdentifier:@"Subtitle"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Subtitle"] autorelease];
			}
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = NSLocalizedString(@"DisableAd", nil);
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisableAd"] == NO) {
				cell.detailTextLabel.text = NSLocalizedString(@"DisableAd_Disabled", nil);
			} else {
				cell.detailTextLabel.text = NSLocalizedString(@"DisableAd_Enabled", nil);
			}
			break;
		case 7:
			cell = [tableView dequeueReusableCellWithIdentifier:@"Default"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Default"] autorelease];
			}
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = @"CatHandのアプリ";
					break;
				case 1:
					cell.textLabel.text = NSLocalizedString(@"Application support", nil);
					break;
				default:
					break;
			}
			break;
			
		case 8:
			cell = [tableView dequeueReusableCellWithIdentifier:@"Default"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Default"] autorelease];
			}
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = @"ライセンス";
			break;
			
		default:
			break;
	}
	
    return cell;
}

- (void) goMultiselectionViewWithKey:(NSString *)key count:(int)count {
	MultiSelectionViewController *vc = [[[MultiSelectionViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	
	if ([key isEqualToString:@"MatrixViewColumnCount"]) {
		vc.titles = [NSArray arrayWithObjects:@"2列", @"3列", @"4列", nil];
		NSInteger col = [[NSUserDefaults standardUserDefaults] integerForKey:@"MatrixViewColumnCount"];
		if (col < 2 || 4 < col) {
			col = 4;
		}
		vc.selectedIndexes = [NSMutableIndexSet indexSetWithIndex:col - 2];
	} else if ([key isEqualToString:@"MatrixViewThumbnailFit"]) {
		vc.titles = [NSArray arrayWithObjects:@"拡大して表示", @"全体を表示", nil];
		vc.selectedIndexes = [NSMutableIndexSet indexSetWithIndex:[[NSUserDefaults standardUserDefaults] boolForKey:@"MatrixViewThumbnailFit"] ? 1 : 0];
	}
	
	vc.delegate = self;
	vc.object = key;
	vc.allowEmptySelection = NO;
	vc.allowMultipleSelection = NO;	
	
	[self.navigationController pushViewController:vc animated:YES];
}

- (void) multiSelectionView:(MultiSelectionViewController *)mview done:(BOOL)complete {
	if (complete == NO) {
		return;
	}
	
	if ([mview.object isEqualToString:@"MatrixViewColumnCount"]) {
		[[NSUserDefaults standardUserDefaults] setInteger:[mview.selectedIndexes firstIndex] + 2 forKey:@"MatrixViewColumnCount"];
	} else if ([mview.object isEqualToString:@"MatrixViewThumbnailFit"]) {
		[[NSUserDefaults standardUserDefaults] setBool:[mview.selectedIndexes firstIndex] != 0 forKey:@"MatrixViewThumbnailFit"];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self.tableView reloadData];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"PreferenceChangedNotification" object:self userInfo:[NSDictionary dictionaryWithObject:mview.object forKey:@"Key"]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
				{
					SlideshowPeriodSettingViewController *vc = [[SlideshowPeriodSettingViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:vc animated:YES];
					[vc release];
				}
					break;
				case 1:
				{
					SlideshowDisplaySettingViewController *vc = [[SlideshowDisplaySettingViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:vc animated:YES];
					[vc release];
				}
					break;
				default:
					break;
			}
			break;
		case 1:
			if (indexPath.row == 0) {
				[self goMultiselectionViewWithKey:@"MatrixViewColumnCount" count:3];
			} else if (indexPath.row == 1) {
				[self goMultiselectionViewWithKey:@"MatrixViewThumbnailFit" count:2];
			}
			break;
		case 2:
		{
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			if (indexPath.row == 0) {
                if (DISABLE_DROPBOX) {
                    [[SharedAlertView sharedInstance] showWithTitle:@"Not available." message:nil cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
                    return;
                }
                
				if (![[DropBoxTail sharedInstance] linked]) {
					[[DropBoxTail sharedInstance] link:self completionBlock:^(NSURL *url) {
						[self showProgress:YES withTitle:@"" tag:0];
						[[DropBoxTail sharedInstance] handleOpenURL:url completionBlock:^(NSError *error) {
							[self hideProgress];
							
							if (error != nil && [error code] != -2) {
								[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Login failed.", nil) message:[error localizedDescription] cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
							}
							[self.tableView reloadData];
						}];
					}];
				} else {
					[[DropBoxTail sharedInstance] unlink];
				}
				cell.accessoryType = ([[DropBoxTail sharedInstance] linked] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
			} else if (indexPath.row == 1) {
                if (DISABLE_EVERNOTE) {
                    [[SharedAlertView sharedInstance] showWithTitle:@"Not available." message:nil cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
                    return;
                }
                
				BOOL b = UDBoolWithDefault(@"SaveToEvernote", NO);
				if (!b) {
					[[EvernoteTail sharedInstance].session authenticateWithViewController:self completionHandler:^(NSError *error) {
						if (error) {
							[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
						} else if ([EvernoteTail sharedInstance].logined) {
							UDSetBool(YES, @"SaveToEvernote");
							[[NSUserDefaults standardUserDefaults] synchronize];
							[[NSNotificationCenter defaultCenter] postNotificationName:@"PreferenceChangedNotification" object:self userInfo:[NSDictionary dictionaryWithObject:@"SaveToEvernote" forKey:@"Key"]];
						}
					}];
				} else {
					[[EvernoteTail sharedInstance].session logout];
					UDSetBool(NO, @"SaveToEvernote");
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 2) {
                if (DISABLE_TUMBLR) {
                    [[SharedAlertView sharedInstance] showWithTitle:@"Not available." message:nil cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
                    return;
                }
                
				BOOL b = ([TumblrAccountManager sharedInstance].currentAccount != nil);
				if (!b) {
					TumblrAccountViewController *vc = [[[TumblrAccountViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
					UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
					if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
						nc.modalPresentationStyle = UIModalPresentationFormSheet;
					}
					[self presentModalViewController:nc animated:YES];
				} else {
					[TumblrAccountManager sharedInstance].currentAccount = nil;
					
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 3) {
                if (DISABLE_SUGARSYNC) {
                    [[SharedAlertView sharedInstance] showWithTitle:@"Not available." message:nil cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
                    return;
                }
                
				BOOL b = UDBoolWithDefault(@"SaveToSugarSync", NO);
				if (!b) {
					SugarSyncAccountViewController *vc = [[[SugarSyncAccountViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
					UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
					if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
						nc.modalPresentationStyle = UIModalPresentationFormSheet;
					}
					[self presentModalViewController:nc animated:YES];
				} else {
					UDSetBool(NO, @"SaveToSugarSync");
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 4) {
                if (DISABLE_GOOGLEDRIVE) {
                    [[SharedAlertView sharedInstance] showWithTitle:@"Not available." message:nil cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
                    return;
                }
                
				BOOL b = [GoogleDrive sharedInstance].available;
				if (!b) {
					UIViewController *vc = [[GoogleDrive sharedInstance] authViewControllerWithDelegate:self];
					vc.title = NSLocalizedString(@"GoogleDrive", nil);
					UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
					if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
						nc.modalPresentationStyle = UIModalPresentationFormSheet;
					}
					[self presentModalViewController:nc animated:YES];
					
					vc.navigationItem.rightBarButtonItem = nil;
					vc.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(googleDriveCancel:)] autorelease];
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			} else if (indexPath.row == 5) {
                if (DISABLE_SKYDRIVE) {
                    [[SharedAlertView sharedInstance] showWithTitle:@"Not available." message:nil cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
                    return;
                }
                
				BOOL b = UDBoolWithDefault(@"SaveToSkyDrive", NO);
				if (!b) {
					[[SkyDrive sharedInstance] login:self.navigationController withDelegate:self];
				} else {
					[[SkyDrive sharedInstance] logout];
					UDSetBool(NO, @"SaveToSkyDrive");
					cell.accessoryType = UITableViewCellAccessoryNone;
				}
			}
		}
			break;
		case 3:
			break;
		case 4:
			if (indexPath.row == 0) {
				TwitterFormatViewController *vc = [[TwitterFormatViewController alloc] initWithNibName:@"TwitterFormatViewController" bundle:nil];
				[self.navigationController pushViewController:vc animated:YES];
				[vc release];
			} else if (indexPath.row == 1) {
				TwitterFormatViewController *vc = [[TumblrFormatViewController alloc] initWithNibName:@"TwitterFormatViewController" bundle:nil];
				[self.navigationController pushViewController:vc animated:YES];
				[vc release];
			}
			break;
		case 5:
			if (indexPath.row == 0) {
				[self performSelectorInBackground:@selector(cleanUpCacheThread) withObject:nil];
				
				activityController = [[ActivitySheetViewController activityController] retain];
				[activityController present];
				[activityController.activityView startAnimating];
				activityController.label.text = @"キャッシュの削除中";
			} else if (indexPath.row == 2) {
				if (UDStringWithDefault(@"Passcode", nil).length == 4) {
					UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Do you want to turn passcode off?", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
					alert.tag = 2;
					[alert show];
				} else {
					UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Do you want to turn passcode on?", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
					alert.tag = 2;
					[alert show];
				}
			} else if (indexPath.row == 3) {
				WidgetSettingViewController *vc = [[[WidgetSettingViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
				[self.navigationController pushViewController:vc animated:YES];
			}
			break;
		case 6:
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisableAd"]) {
				[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Already purchased.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
			} else {
				DisableAdViewController *vc = [[[DisableAdViewController alloc] init] autorelease];
				[self.navigationController pushViewController:vc animated:YES];
			}
			break;
		case 7:
		{
            NSURL *url = nil;
			switch (indexPath.row) {
				case 0:
                    url = [NSURL URLWithString:@"http://appstore.com/cathandorg"];
                    break;
				case 1:
#ifdef PIXITAIL
                    url = [NSURL URLWithString:@"http://cathand.org/pixitail/"];
#else
                    url = [NSURL URLWithString:@"http://cathand.org/illustail/"];
#endif
					break;
				default:
					return;
			}
            [[UIApplication sharedApplication] openURL:url];
		}
			break;
		case 8:
		{
			UIViewController *controller = nil;
			controller = [[LicenseViewController alloc] initWithNibName:@"LicenseViewController" bundle:nil];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];		
		}
			break;
		default:
			break;
	}
}

- (void) cleanUpCacheThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *ary = [[[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] retain] autorelease];
	for (NSHTTPCookie *c in ary) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:c];
	}
	
	[PixitailConstants sharedInstance].vers = 0;
	[SeigaConstants sharedInstance].vers = 0;
	for (PixAccount *a in [AccountManager sharedInstance].accounts) {
		if ([a respondsToSelector:@selector(service)]) {
			ScrapingService *s = [a performSelector:@selector(service)];
			if ([s isKindOfClass:[ScrapingService class]]) {
				s.constants.vers = 0;
			}
		}

		PixService *service = [PixService serviceWithName:a.serviceName];
		service.logined = NO;
	}

	[ImageDiskCache removeAllCache];
	
	[self performSelectorOnMainThread:@selector(cleanUpCacheFinishedMain) withObject:nil waitUntilDone:YES];
	[pool release];
}

- (void) cleanUpCacheFinishedMain {
	[activityController dismiss];
	[activityController release];
	activityController = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Dismiss the keyboard when the view outside the text field is touched.
    // Revert the text field to the previous value.
    //textField.text = self.string; 
    [super touchesBegan:touches withEvent:event];
}

- (BOOL) authorizeWithURL:(NSURL *)url {
	OAuthViewController	*oauthController = [[OAuthViewController alloc] initWithNibName:@"OAuthViewController" bundle:nil];
	oauthController.url = url;
	[oauthController setDelegate:self];
	[self.navigationController pushViewController:oauthController animated:YES];
	[oauthController release];
	return YES;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	//if ([viewController isKindOfClass:[OAuthViewController class]]) {
	//	[(OAuthViewController *)viewController didShow];
	//}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 2 && buttonIndex != alertView.cancelButtonIndex) {
		if (UDStringWithDefault(@"Passcode", nil).length == 4) {
			UDSetString(@"", @"Passcode");
			[self.tableView reloadData];
		} else {
			PasscodeLockViewController *lockViewController = [[[PasscodeLockViewController alloc] init] autorelease];
			lockViewController.password = nil;
			lockViewController.delegate = self;
			[self presentModalViewController:lockViewController animated:NO];
		}
	}
}

- (void) passcodeLockViewControllerFinished:(PasscodeLockViewController *)sender {	
	UDSetString(sender.password, @"Passcode");
	[self.tableView reloadData];
	
	[sender dismissModalViewControllerAnimated:NO];
}

- (void) saveFolderAction:(UISwitch *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"SaveFolder"];
}

- (void) saveTagsAction:(UISwitch *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"SaveTags"];
}

- (void) saveTagsTumblrAction:(UISwitch *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"SaveTagsTumblr"];
}

- (void) tumblrTweetSwitchAction:(UISwitch *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"TumblrTweet"];
}

#pragma mark-

- (void) googleDriveCancel:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) googleAuthFinished:(GoogleDrive *)sender error:(NSError *)err {
	if (err) {
		if ([err code] != -1000 || ![[err domain] isEqualToString:@"com.google.GTMOAuth2"]) {
			[self.parentViewController dismissModalViewControllerAnimated:YES];
			[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error: %d", nil), [err code]] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
		}
	} else {
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	}
	[self.tableView reloadData];
}

#pragma mark-

- (void) skyDrive:(SkyDrive *)sender loginFinished:(NSError *)err {
	if (err) {
		if ([err code] != 2) {
			[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[err localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
		}
	} else {
		UDSetBool(YES, @"SaveToSkyDrive");
	}
	[self.tableView reloadData];
}

@end

