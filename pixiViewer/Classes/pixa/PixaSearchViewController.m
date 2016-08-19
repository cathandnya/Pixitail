//
//  PixaSearchViewController.m
//  pixiViewer
//
//  Created by nya on 09/09/23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaSearchViewController.h"
#import "PixaMatrixParser.h"
#import "PixaSlideshowViewController.h"
#import "Pixa.h"
#import "AccountManager.h"


@implementation PixaSearchViewController

@synthesize searchTerm;
@synthesize headerView, searchBar, scopeBar, scopeSegment;

- (void) dealloc {
	[searchBar release];
	searchBar = nil;
	[searchTerm release];
	searchTerm = nil;
	self.searchTerm = nil;
	[super dealloc];
}


- (int) scopeCount {
	return 3;
}

- (NSString *) scopeNameAt:(int)idx {
	switch (idx) {
	case 0:
		return NSLocalizedString(@"Illust", nil);
	case 1:
		return NSLocalizedString(@"Tags", nil);
	case 2:
		return NSLocalizedString(@"UserName", nil);
	case 3:
		return NSLocalizedString(@"Badge", nil);
	default:
		return @"";
	}
}

- (NSString *) scopeAt:(NSInteger)idx {
	switch (idx) {
	case 0:
		return @"illustrations/list_search?keyword=";
	case 1:
		return @"illustrations/list_tag?tag=";
	case 2:
		return @"illustrations/list_nickname?nickname=";
	case 3:
		return @"badges/list_search?keyword=";
	default:
		return @"";
	}
}

- (NSString *) urlString {
	return [NSString stringWithFormat:@"http://www.pixa.cc/%@%@&page=%d", [self selectedScope], encodeURIComponent(self.searchTerm), loadedPage_ + 1];
}

- (NSString *) referer {
	return @"http://www.pixa.cc/";
}

- (NSString *) httpMethod {
	return nil;
	//return @"POST";
}

- (void) setupHeaderFooter {
	UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.navigationController.toolbar.frame.size.height)];
	footer.backgroundColor = [UIColor clearColor];
	self.tableView.tableFooterView = footer;
	[footer release];
}

- (UITableView *) matrixView {
	return self.tableView;
}

- (NSString *) selectedScope {
	return [self scopeAt:scopeSegment.selectedSegmentIndex];
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
	long	err = [[Pixa sharedInstance] allertReachability];
	if (err) {
		return err;
	}
	/*
	if (err == -1) {
		[Pixa sharedInstance].username = account.username;
		[Pixa sharedInstance].password = account.password;
	
		err = [[Pixa sharedInstance] login:self];
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
	
	PixaMatrixParser		*parser = [[PixaMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding];
	CHHtmlParserConnection	*con;
	
	//[[self matrixView] setShowsLoadNextButton:NO];
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
		[self setScopeBarHidden:NO];
	} else {
		self.tableView.tableHeaderView = nil;
	}
}

- (void)viewDidUnload {
	[searchBar release];
	searchBar = nil;
	[searchTerm release];
	searchTerm = nil;
	
	[super viewDidUnload];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)asearchBar {
	self.searchTerm = @"";

	[self setScopeBarHidden:NO];
	
	showsNextButton_ = NO;
	@synchronized(self) {
		[contents_ removeAllObjects];
	}
	[self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)asearchBar {
	self.searchTerm = asearchBar.text;
	[asearchBar resignFirstResponder];

	[self setScopeBarHidden:YES];

	[self reflesh];
}

- (IBAction) slideshow {
	PixivSlideshowViewController *controller = [[PixaSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = [NSString stringWithFormat:@"search.php?word=%@&s_mode=%@&", encodeURIComponent(self.searchTerm), [self selectedScope]];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

#pragma mark-

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[self hideProgress];
	if (err) {
		// もいっかい
		err = [[Pixa sharedInstance] login:self];
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
