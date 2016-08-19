//
//  SeigaSearchViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/23.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaSearchViewController.h"
#import "SeigaConstants.h"
#import "Seiga.h"
#import "SeigaSlideshowViewController.h"
#import "SeigaMatrixParser.h"


@implementation SeigaSearchViewController

@synthesize searchTerm;
@synthesize headerView, searchBar, scopeBar, scopeSegment;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[searchBar release];
	searchBar = nil;
	[searchTerm release];
	searchTerm = nil;
	[headerView release];
	headerView = nil;

	self.searchTerm = nil;
	[super dealloc];
}


- (NSInteger) scopeCount {
	return 2;
}

- (NSString *) scopeNameAt:(NSInteger)idx {
	switch (idx) {
		case 0:
			return NSLocalizedString(@"Tags", nil);
		case 1:
			return NSLocalizedString(@"All", nil);
		default:
			return @"";
	}
}

- (NSString *) scopeAt:(NSInteger)idx {
	switch (idx) {
		case 0:
			return @"urls.tag";
		case 1:
		default:
			return @"urls.search";
	}
}

- (NSString *) escapedSearchTerm {	
	NSData				*data = [[self searchTerm] dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*tag = [NSMutableString string];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[tag appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	return tag;
}

- (NSString *) methodString {
	return [NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:[self selectedScope]], encodeURIComponent([self searchTerm])];
}

- (NSString *) urlString {
	NSString *str =  [NSString stringWithFormat:@"%@%@", [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"], [self methodString]];
	if ([str rangeOfString:@"?"].location == NSNotFound) {
		str = [str stringByAppendingFormat:@"?%@=%d", [[SeigaConstants sharedInstance] valueForKeyPath:@"constants.page_param"], loadedPage_ + 1];
	} else {
		str = [str stringByAppendingFormat:@"&%@=%d", [[SeigaConstants sharedInstance] valueForKeyPath:@"constants.page_param"], loadedPage_ + 1];
	}
	return str;
}

- (NSString *) referer {
	return [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"];
}

- (NSString *) httpMethod {
	return nil;
}


- (UITableView *) matrixView {
	return self.tableView;
}

- (NSString *) selectedScope {
	return [self scopeAt:scopeSegment.selectedSegmentIndex];
}

- (void) setupHeaderFooter {
	if (progressShowing_) {
		self.tableView.tableHeaderView = nil;
	} else {
		self.tableView.tableHeaderView = headerView;
	}
	
	/*
	 UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.navigationController.toolbar.frame.size.height)];
	 footer.backgroundColor = [UIColor clearColor];
	 self.tableView.tableFooterView = footer;
	 [footer release];
	 */
}

#define MIN_HEIGHT 44
#define MAX_HEIGHT 88
- (void) setScopeBarHidden:(BOOL)b {
	CGRect rect;
	rect.origin = CGPointZero;
	rect.size.width = self.view.frame.size.width;
	rect.size.height = b ? MIN_HEIGHT : MAX_HEIGHT;
	
	scopeBar.hidden = b;
	
	//tableView.tableHeaderView = nil;
	headerView.frame = rect;
	self.tableView.tableHeaderView = headerView;
	//headerView.frame = rect;
	[self.tableView reloadData];
}

/*
 - (void) setScopeBarHidden:(BOOL)b {
 CGRect rect;
 rect.origin = CGPointZero;
 rect.size.width = self.view.frame.size.width;
 
 rect.size.height = 64 + searchBar.frame.size.height;
 if (b == NO) {
 rect.size.height += scopeBar.frame.size.height;
 }
 
 scopeBar.hidden = b;
 headerView.frame = rect;
 
 self.tableView.tableHeaderView = headerView;
 }
 */

- (long) reload {
	long	err = [[Seiga sharedInstance] allertReachability];
	if (err) {
		return err;
	}
	/*
	 if (err == -1) {
	 [Pixiv sharedInstance].username = account.username;
	 [Pixiv sharedInstance].password = account.password;
	 
	 err = [[Pixiv sharedInstance] login:self];
	 if (err) {
	 UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
	 [alert show];
	 return err;
	 } else {
	 [self showProgress:YES withTitle:@"ログイン中..." tag:1000];
	 }
	 return 0;
	 } else if (err) {
	 return err;
	 }
	 */
	
	SeigaMatrixParser		*parser = [[SeigaMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding];
	if (self.scrapingInfoKey) {
		NSDictionary *d = [[SeigaConstants sharedInstance] valueForKeyPath:self.scrapingInfoKey];
		if (d) {
			parser.scrapingInfo = d;
		}
	}
	CHHtmlParserConnection	*con;
	
	showsNextButton_ = NO;
	
	if ([self.searchTerm length] == 0) {
		[parser release];
		return 1;
	}
	
	if (!contents_) {
		contents_ = [[NSMutableArray alloc] init];
	}
	
	pictureIsFound_ = NO;
	parser.delegate = self;
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[self urlString]]];
	DLog(@"%@", [self urlString]);
	
	con.referer = [self referer];
	con.delegate = self;
	con.method = [self httpMethod];
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	return 0;
}

- (CGFloat) topMargin {
	return 0;//[super topMargin] + 44;
}

- (void)viewDidLoad {
	//searchBar.showsScopeBar = YES;
	//searchBar.scopeButtonTitles = [NSArray arrayWithObjects:NSLocalizedString(@"Tags", nil), NSLocalizedString(@"Title/Caption", nil), nil];
	searchBar.delegate = self;
	//searchBar.barStyle = UIBarStyleBlack;
	//searchBar.tintColor = [UIColor blackColor];
	searchBar.translucent = NO;
	//scopeSegment.tintColor = [UIColor darkGrayColor];
	
	[scopeSegment removeAllSegments];
	int	i;
	for (i = 0; i < [self scopeCount]; i++) {
		[scopeSegment insertSegmentWithTitle:[self scopeNameAt:i] atIndex:i animated:NO];
	}
	scopeSegment.selectedSegmentIndex = 0;
	
	[super viewDidLoad];
	
	if (progressShowing_ == NO) {
		[searchBar becomeFirstResponder];
		//[scopeBar setHidden:NO];
		[self setScopeBarHidden:NO];		
	} else {
		self.tableView.tableHeaderView = nil;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFinished:) name:@"LoginFinishedNotification" object:nil];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[searchBar release];
	searchBar = nil;
	[searchTerm release];
	searchTerm = nil;
	[headerView release];
	headerView = nil;
	
	[super viewDidUnload];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)asearchBar {
	self.searchTerm = @"";
	
	//[scopeBar setHidden:NO];
	[self setScopeBarHidden:NO];
	
	showsNextButton_ = NO;
	@synchronized(self) {
		[contents_ removeAllObjects];
	}
	[self.tableView reloadData];
}

- (void) saveSerchTerm:(NSString *)str withScope:(NSString *)scope {
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
						  str,		@"Term",
						  scope,	@"Scope",
						  nil];
	
	NSMutableArray *ary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SeigaSerchHistory"] mutableCopy];
	if (ary == nil) {
		ary = [[NSMutableArray alloc] init];
	}
	if (![ary containsObject:info]) {
		[ary insertObject:info atIndex:0];
		if ([ary count] > 100) {
			[ary removeLastObject];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:@"SeigaSerchHistory"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[ary release];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)asearchBar {
	self.searchTerm = asearchBar.text;
	[asearchBar resignFirstResponder];
	
	//[scopeBar setHidden:YES];
	[self setScopeBarHidden:YES];
	
	if ([self.searchTerm isEqualToString:@"nekomimigahoshii"]) {
		[[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"R18IsEnabled"] forKey:@"R18IsEnabled"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[self saveSerchTerm:self.searchTerm withScope:[self selectedScope]];
	[self reflesh];
}

- (IBAction) slideshow {
	SeigaSlideshowViewController *controller = [[SeigaSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = [self methodString];
	controller.scrapingInfoKey = self.scrapingInfoKey;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void) loginFinished:(NSNotification *)notif {
	[self reload];
}

#pragma mark-

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[self hideProgress];
	if (err) {
		// もいっかい
		err = [[Seiga sharedInstance] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			[self.navigationController popToRootViewControllerAnimated:YES];
			return;
		}
	} else {
		[searchBar becomeFirstResponder];
		[self setScopeBarHidden:NO];
		
		[self reload];
	}
}

@end
