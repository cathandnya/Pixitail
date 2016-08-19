//
//  AccountViewController.m
//  pixiViewer
//
//  Created by nya on 09/12/16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AccountViewController.h"
#import "CHGroupTableView.h"
#import "AccountManager.h"
#import "EditableCell.h"

#import "Pixiv.h"
#import "Tinami.h"
#import "Pixa.h"
#import "Tumblr.h"
#import "ProgressViewController.h"
#import "Seiga.h"
#import "AccountManager.h"


@interface OtherAccountTypeViewController : DefaultTableViewController<UITextFieldDelegate> {
	UITextField *hostnameField;
}

@property(readwrite, assign, nonatomic) PixAccount *account;

@end


@implementation OtherAccountTypeViewController

@synthesize account;

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	NSString *CellIdentifier = @"Cell";
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[EditableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	cell.textLabel.text = @"";
	((EditableCell *)cell).field.placeholder = @"URL";
	[hostnameField release];
	hostnameField = nil;
	hostnameField = [((EditableCell *)cell).field retain];
	hostnameField.delegate = self; //delegateを食わせて
	return cell;
}

- (void) doneAction:(id)sender {
	[hostnameField resignFirstResponder];
	
	BOOL done = NO;
	NSString *str = hostnameField.text;
	if ([str hasPrefix:@"http://"]) {
		str = [str substringFromIndex:[@"http://" length]];
	} else if ([str hasPrefix:@"https://"]) {
		str = [str substringFromIndex:[@"https://" length]];
	}
	str = [str stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
	
	/*
	if ([str isEqualToString:@"www.pixiv.net"]) {
		account.serviceName = @"pixiv";
		done = YES;
	} else 
	*/
	if ([str isEqualToString:@"www.fg-site.net/old"] || [str isEqualToString:@"www.fg-site.net"]) {
		account.serviceName = @"fg";
		done = YES;
	/*
	} else if ([str isEqualToString:@"nijie.info"]) {
		account.serviceName = @"Nijie";
		done = YES;
	*/
	}
	
	if (done) {
		NSMutableArray *mary = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
		[mary removeObjectAtIndex:mary.count - 2];
		self.navigationController.viewControllers = mary;
		
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"対応していないサービスです。" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
		[alert show];
	}
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

@end


@interface AccountTypeViewController : DefaultTableViewController {
	PixAccount *account;
	NSArray *serviceNames;
}

@property(readwrite, assign, nonatomic) PixAccount *account;

@end


@implementation AccountTypeViewController

@synthesize account;

- (id) initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (style) {
		NSMutableArray *mary = [NSMutableArray array];
		[mary addObject:@"TINAMI"];
		//[mary addObject:@"PiXA"];
		//[mary addObject:@"Tumblr"];
		[mary addObject:@"Danbooru"];
		[mary addObject:@"Seiga"];
		
		serviceNames = [mary retain];
	}
	return self;
}

- (void) dealloc {
	[serviceNames release];
	[super dealloc];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return serviceNames.count;
	} else {
		return 1;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		UITableViewCell	*cell = nil;
		cell = [tableView dequeueReusableCellWithIdentifier:@"Value1"];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Value1"] autorelease];
		}
		
		NSDictionary *info = [PixAccount serviceWithName:[serviceNames objectAtIndex:indexPath.row]];
		NSString *typestr = [info objectForKey:@"name"];
		cell.textLabel.text = NSLocalizedString(typestr, nil);
		cell.detailTextLabel.text = [info objectForKey:@"url"];
		
		if ([account.serviceName isEqualToString:typestr]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		return cell;
	} else {
		UITableViewCell	*cell = nil;
		cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"] autorelease];
			cell.textLabel.text = @"他のサービス";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		return cell;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		account.serviceName = [serviceNames objectAtIndex:indexPath.row];
		[(UITableView *)self.view reloadData];
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		OtherAccountTypeViewController *vc = [[[OtherAccountTypeViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		vc.account = self.account;
		[self.navigationController pushViewController:vc animated:YES];
	}
}

@end


@implementation AccountViewController

@synthesize account;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void) updateRows {
	NSMutableArray *mary;
	NSMutableArray *rowAry;

#ifdef PIXITAIL
	mary = [NSMutableArray array];
	rowAry = [NSMutableArray array];
	[mary addObject:rowAry];
	[rowAry addObject:@"username"];
	[rowAry addObject:@"password"];

	[rows release];
	rows = [mary retain];

	mary = [NSMutableArray array];
	[mary addObject:@"PixAccount"];
	
	[sectionTitles release];
	sectionTitles = [mary retain];
#else
	mary = [NSMutableArray array];
	rowAry = [NSMutableArray array];
	[mary addObject:rowAry];
	[rowAry addObject:@"service"];
	if ([account.serviceName isEqualToString:@"Danbooru"]) {
		[rowAry addObject:@"hostname"];
	}
	
	rowAry = [NSMutableArray array];
	[mary addObject:rowAry];
	[rowAry addObject:@"username"];
	[rowAry addObject:@"password"];
	
    if ([account.serviceName isEqualToString:@"TINAMI"]) {
		rowAry = [NSMutableArray array];
		[mary addObject:rowAry];
		[rowAry addObject:@"add_account"];
	}
	
	[rows release];
	rows = [mary retain];

	mary = [NSMutableArray array];
	[mary addObject:@"PixAccount Type"];
	[mary addObject:@"PixAccount"];
    if ([account.serviceName isEqualToString:@"TINAMI"]) {
		[mary addObject:@""];
	}
	
	[sectionTitles release];
	sectionTitles = [mary retain];
#endif	
}

- (void)dealloc {
	[account release];

    [super dealloc];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	CHGroupTableView *tv = [[CHGroupTableView alloc] initWithFrame:self.tableView.frame style:UITableViewStyleGrouped];
	tv.delegate = self;
	tv.dataSource = self;
	self.tableView = tv;
	[tv release];
	
	if (account == nil) {
		account = [[PixAccount alloc] init];
#ifdef PIXITAIL
		account.serviceName = @"pixiv";
#else
		account.serviceName = @"TINAMI";
#endif
	} else {
		PixAccount *acc = nil;
		for (acc in [AccountManager sharedInstance].accounts) {
			if ([acc isEqual:account]) {
				break;
			}
		}
		originalAccount = acc;
	}
	
	[self updateRows];
	self.title = NSLocalizedString(@"PixAccount", nil);
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"ログイン" style:UIBarButtonItemStyleDone target:self action:@selector(done)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[idField release];
	[passField release];
	[hostnameField release];
	
	[super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateRows];
	[self.tableView reloadData];
	
	self.navigationItem.rightBarButtonItem.title = @"ログイン";
}

- (IBAction) done {
	[idField resignFirstResponder];
	[passField resignFirstResponder];
	[hostnameField resignFirstResponder];

	if ([account.serviceName isEqualToString:@"Danbooru"]) {
		account.hostname = hostnameField.text;
	}
	account.password = passField.text;
	account.username = idField.text;
	
	if ([account.serviceName isEqualToString:@"TINAMI"] && ([account.username length] == 0 || [account.password length] == 0)) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid PixAccount", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		return;
	}
	for (PixAccount *acc in [AccountManager sharedInstance].accounts) {
		if ([acc isEqual:account] && ![acc isEqual:originalAccount]) {
			// 重複
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"既に登録されています" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
			[alert show];
			[alert release];
			return;
		}
	}
	
	if (account.anonymous || [account.serviceName isEqualToString:@"Danbooru"]) {
		[[AccountManager sharedInstance] addAccount:account original:originalAccount];
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		PixService *service = [PixService serviceWithName:account.serviceName];
		service.username = account.username;
		service.password = account.password;
		service.logined = NO;
		if ([service login:self]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
			[alert show];
			[alert release];
		} else {
			[self showProgress:YES withTitle:NSLocalizedString(@"Login", nil) tag:0];
			progressViewController_.cancelButton.hidden = NO;
		}
	}
}

- (IBAction) cancel {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[self hideProgress];
	
	if (err) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
	} else {
		[[AccountManager sharedInstance] addAccount:account original:originalAccount];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [rows count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return NSLocalizedString(([sectionTitles objectAtIndex:section]), nil);
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[rows objectAtIndex:section] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

	NSString *key = [[rows objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([key isEqual:@"service"]) {
		static NSString *CellIdentifier = @"Default";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		cell.textLabel.text = NSLocalizedString(account.typeString, nil);
	} else if ([key isEqual:@"username"]) {
		NSString *CellIdentifier = key;
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[EditableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}

		if ([account.serviceName isEqualToString:@"pixiv"] || [account.serviceName isEqualToString:@"Danbooru"]) {
			cell.textLabel.text = NSLocalizedString(@"Username", nil);
		} else {
			cell.textLabel.text = NSLocalizedString(@"Mailaddress", nil);
		}
		((EditableCell *)cell).field.text = account.username;
		[idField release];
		idField = nil;
		idField = [((EditableCell *)cell).field retain];
		idField.delegate = self; //delegateを食わせて
	} else if ([key isEqual:@"password"]) {
		NSString *CellIdentifier = key;
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[EditableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		cell.textLabel.text = NSLocalizedString(@"Password", nil);
		((EditableCell *)cell).field.text = account.password;
		[passField release];
		passField = nil;
		passField = [((EditableCell *)cell).field retain];
		passField.secureTextEntry = YES;
		passField.delegate = self; //delegateを食わせて
	} else if ([key isEqual:@"hostname"]) {
		NSString *CellIdentifier = key;
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[EditableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}

		if (account.hostname.length == 0) {
			account.hostname = @"danbooru.donmai.us";
		}
		
		cell.textLabel.text = NSLocalizedString(@"HOST", nil);
		((EditableCell *)cell).field.placeholder = @"danbooru.donmai.us";
		((EditableCell *)cell).field.text = account.hostname;
		[hostnameField release];
		hostnameField = nil;
		hostnameField = [((EditableCell *)cell).field retain];
		hostnameField.delegate = self; //delegateを食わせて
	} else if ([key isEqual:@"add_account"]) {
		static NSString *CellIdentifier = @"Button";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.textAlignment = UITextAlignmentCenter;
		}
		
		cell.textLabel.text = NSLocalizedString(@"新規アカウントを取得する", nil);
	}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	NSString *key = [[rows objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([key isEqual:@"service"]) {
		AccountTypeViewController *vc = [[AccountTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
		vc.account = account;
		vc.title = @"サービス";
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	} else if ([key isEqual:@"add_account"]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TINAMIに接続して新規アカウントを取得しますか？" message:@"Safariを起動します" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@"取得する", nil];
		[alert show];
		[alert release];
	}
}

#pragma mark-

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (textField == passField) {
		account.password = textField.text;
	} else if (textField == idField) {
		account.username = textField.text;
	} else if (textField == hostnameField) {
		account.hostname = hostnameField.text;
	}
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == idField) {
		[passField becomeFirstResponder];
	} else {
		[textField resignFirstResponder];
	}
	return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[passField resignFirstResponder];
	[idField resignFirstResponder];
	[hostnameField resignFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		if (!originalAccount && [account.serviceName isEqualToString:@"TINAMI"]) {
			// 起動
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.tinami.com/entry/iphone/form"]];
		} else {
			// 削除
			[[AccountManager sharedInstance] removeAccount:originalAccount];
		
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
}

@end

