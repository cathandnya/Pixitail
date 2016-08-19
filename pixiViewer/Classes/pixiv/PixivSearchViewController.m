//
//  PixivSearchViewController.m
//  pixiViewer
//
//  Created by nya on 09/08/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivSearchViewController.h"
#import "PixivSlideshowViewController.h"
#import "Pixiv.h"
#import "AccountManager.h"
#import "PixitailConstants.h"


@implementation PixivSearchViewController

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


- (int) scopeCount {
	return 2;
}

- (NSString *) scopeNameAt:(int)idx {
	switch (idx) {
	case 0:
		return NSLocalizedString(@"Tags", nil);
	case 1:
		return NSLocalizedString(@"Title/Caption", nil);
	default:
		return @"";
	}
}

- (NSString *) scopeAt:(NSInteger)idx {
	switch (idx) {
	case 0:
		return @"s_tag";
	case 1:
		return @"s_tc";
	default:
		return @"";
	}
}

- (NSString *) urlString {
	return [NSString stringWithFormat:@"http://www.pixiv.net/search.php?word=%@&s_mode=%@&p=%d", [self.searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [self selectedScope], loadedPage_ + 1];
}

- (NSString *) referer {
	return @"http://www.pixiv.net/mypage.php";
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
	long	err = [[Pixiv sharedInstance] allertReachability];
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
	
	PixivMatrixParser		*parser = [[PixivMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
	if (self.scrapingInfoKey) {
		NSDictionary *d = [[PixitailConstants sharedInstance] valueForKeyPath:self.scrapingInfoKey];
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
		str,	@"Term",
		scope,	@"Scope",
		nil];
		
	NSMutableArray *ary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SerchHistory"] mutableCopy];
	if (ary == nil) {
		ary = [[NSMutableArray alloc] init];
	}
	if (![ary containsObject:info]) {
		[ary insertObject:info atIndex:0];
		if ([ary count] > 100) {
			[ary removeLastObject];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:@"SerchHistory"];
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
	PixivSlideshowViewController *controller = [[PixivSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = [NSString stringWithFormat:@"search.php?word=%@&s_mode=%@&", encodeURIComponent(self.searchTerm), [self selectedScope]];
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
		err = [[Pixiv sharedInstance] login:self];
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
