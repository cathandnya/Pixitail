//
//  WidgetSettingViewController.m
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

#import "WidgetSettingViewController.h"
#import "WidgetContentSettingViewController.h"


#define MAX_COUNT	5
#ifdef PIXITAIL
#define SUITE_NAME	@"group.org.cathand.pixitail"
#else
#define SUITE_NAME	@"group.org.cathand.illustail"
#endif


@interface WidgetAccountViewController : DefaultTableViewController
@property(strong) NSArray *widgets;
@property(weak) id delegate;
@end

@implementation WidgetAccountViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	self.title = @"アカウント";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
}

- (void) cancelAction:(id)sender {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ([AccountManager sharedInstance].accounts.count == 0) {
		return 1;
	} else {
		return [AccountManager sharedInstance].accounts.count;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([AccountManager sharedInstance].accounts.count == 0) {
		UITableViewCell *cell;
		cell = [tableView dequeueReusableCellWithIdentifier:@"no_account"];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"no_account"];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.textLabel.textAlignment = NSTextAlignmentCenter;
			cell.textLabel.font = [UIFont systemFontOfSize:14];
			cell.textLabel.text = @"アカウントがありません";
		}
		return cell;
	}
	
	UITableViewCell *cell;
	cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	PixAccount *account = [AccountManager sharedInstance].accounts[indexPath.row];
		
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	//cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.textLabel.text = NSLocalizedString(account.typeString, nil);
	if ([account.serviceName isEqualToString:@"Danbooru"]) {
		cell.detailTextLabel.text = account.hostname;
	} else {
		cell.detailTextLabel.text = account.anonymous ? @"ゲスト" : account.username;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if ([AccountManager sharedInstance].accounts.count > 0) {
		PixAccount *account = [AccountManager sharedInstance].accounts[indexPath.row];
		WidgetContentSettingViewController *vc = [[WidgetContentSettingViewController alloc] initWithStyle:UITableViewStyleGrouped];
		vc.widgets = self.widgets;
		vc.delegate = self.delegate;
		vc.account = account;
		[self.navigationController pushViewController:vc animated:YES];
	}
}

@end


@interface WidgetSettingViewController ()
@property(strong) NSUserDefaults *defaults;
@end

@implementation WidgetSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	DLog(@"SUITE_NAME: %@", SUITE_NAME);
	//self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	self.defaults = [[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME];
	
	self.navigationItem.title = @"ウィジェット";
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.tableView reloadData];
	[self updateBarButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateBarButton {
	if (self.tableView.editing) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
		self.navigationItem.hidesBackButton = YES;
	} else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
		self.navigationItem.hidesBackButton = NO;
	}
}

- (void) editAction:(id)sender {
	[self.tableView setEditing:YES animated:YES];
	
	[self updateBarButton];
}

- (void) doneAction:(id)sender {
	[self.tableView setEditing:NO animated:YES];

	[self updateBarButton];
}

#pragma mark-

- (NSArray *) list {
	NSArray *ary = [self.defaults objectForKey:@"widgets"];
	if (!ary) {
		ary = [NSArray array];
	}
	return ary;
}

- (void) addItem:(NSDictionary *)item {
	NSMutableArray *list = [[self list] mutableCopy];
	[list addObject:item];
	[self.defaults setObject:list forKey:@"widgets"];
	[self.defaults synchronize];
	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return [self list].count;
		case 1:
			return [self list].count >= MAX_COUNT ? 0 : 1;
		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
	if (indexPath.section == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		NSDictionary *item = [self list][indexPath.row];
		cell.textLabel.text = item[@"name"];
		
		NSMutableString *mstr = [NSMutableString string];
		[mstr appendString:NSLocalizedString(item[@"service"], nil)];
		[mstr appendString:@" / "];
		[mstr appendString:item[@"username"]];
		cell.detailTextLabel.text = mstr;
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"add_cell"];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"add_cell"];
			cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		}
		
		cell.textLabel.text = @"追加";
	}

	return cell;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		return UITableViewCellEditingStyleDelete;
	} else {
		return UITableViewCellEditingStyleNone;
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSMutableArray *list = [[self list] mutableCopy];
		[list removeObjectAtIndex:indexPath.row];
		[self.defaults setObject:list forKey:@"widgets"];
		[self.defaults synchronize];
		
        // Delete the row from the data source
		[tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		if (list.count == 4) {
			[tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		[tableView endUpdates];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NSMutableArray *list = [[self list] mutableCopy];
	id obj = list[fromIndexPath.row];
	[list removeObjectAtIndex:fromIndexPath.row];
	[list insertObject:obj atIndex:toIndexPath.row];
	[self.defaults setObject:list forKey:@"widgets"];
	[self.defaults synchronize];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 1) {
		WidgetAccountViewController *avc = [[WidgetAccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
		avc.widgets = [self list];
		avc.delegate = self;
		
		UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:avc];
		[self presentViewController:nc animated:YES completion:NULL];
	}
}


@end
