//
//  TinamiSearchViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiSearchViewController.h"
#import "Tinami.h"
#import "TinamiMatrixParser.h"
#import "AccountManager.h"


@implementation TinamiSearchViewController

@synthesize searchTerm;
@synthesize headerView, searchBar, scopeSegment, typeSegment, sortSegment;

- (void) dealloc {
	[searchBar release];
	searchBar = nil;
	[searchTerm release];
	searchTerm = nil;
	
	[scopeSegment release];
	scopeSegment = nil;
	[typeSegment release];
	typeSegment = nil;
	[sortSegment release];
	sortSegment = nil;
	self.searchTerm = nil;
	[super dealloc];
}


- (NSInteger) typeCount {
	return 4;
}

- (NSString *) typeNameAt:(NSInteger)idx {
	switch (idx) {
	case 0:
		return @"作品";
	case 1:
		return @"イラスト";
	case 2:
		return @"マンガ";
	case 3:
		return @"モデル";
	case 4:
		return @"コスプレ";
	case 5:
		return @"小説";
	default:
		return @"";
	}
}

- (NSString *) typeAt:(NSInteger)idx {
	switch (idx) {
	case 0:
		return @"perpage=20";
	case 1:
		return @"cont_type[]=1";
	case 2:
		return @"cont_type[]=2";
	case 3:
		return @"cont_type[]=3";
	case 4:
		return @"cont_type[]=5";
	case 5:
		return @"cont_type[]=4";
	default:
		return @"";
	}
}

- (NSInteger) scopeCount {
	return 2;
}

- (NSString *) scopeNameAt:(NSInteger)idx {
	switch (idx) {
	case 0:
		return @"テキスト";
	case 1:
		return @"タグ";
	default:
		return @"";
	}
}

- (NSString *) scopeAt:(NSInteger)idx {
	switch (idx) {
	case 0:
		return @"text=%@";
	case 1:
		return @"tags=%@";
	default:
		return @"";
	}
}

- (NSString *) sortAt:(NSInteger)idx {
	switch (idx) {
	case 0:
		return @"sort=new";
	case 1:
		return @"sort=score";
	case 2:
		return @"sort=value";
	case 3:
		return @"sort=view";
	case 4:
		return @"sort=rand";
	default:
		return @"";
	}
}

- (NSString *) selectedScope {
	return [self scopeAt:scopeSegment.selectedSegmentIndex];
}

- (NSString *) selectedType {
	return [self typeAt:typeSegment.selectedSegmentIndex];
}

- (NSString *) selectedSort {
	return [self sortAt:sortSegment.selectedSegmentIndex];
}

- (NSString *) urlString {
	return [NSString stringWithFormat:@"https://www.tinami.com/api/content/search?api_key=%@&auth_key=%@&%@&%@&%@&page=%d", TINAMI_API_KEY, [Tinami sharedInstance].authKey, [NSString stringWithFormat:[self selectedScope], encodeURIComponent(self.searchTerm)], [self selectedType], [self selectedSort], loadedPage_ + 1];
}

- (NSString *) referer {
	return @"http://www.tinami.com/";
}

- (NSString *) httpMethod {
	return @"GET";
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

#define MIN_HEIGHT 44
#define MAX_HEIGHT 157
- (void) setScopeBarHidden:(BOOL)b {
	CGRect rect;
	rect.origin = CGPointZero;
	rect.size.width = self.view.frame.size.width;
	rect.size.height = b ? MIN_HEIGHT : MAX_HEIGHT;

	//tableView.tableHeaderView = nil;
	headerView.frame = rect;
	self.tableView.tableHeaderView = headerView;
	//headerView.frame = rect;
	[self.tableView reloadData];
}

- (long) reload {
	long	err = [[Tinami sharedInstance] allertReachability];
	if (err) {
		return err;
	}
	/*
	if (err == -1) {
		[Tinami sharedInstance].username = account.username;
		[Tinami sharedInstance].password = account.password;
	
		err = [[Tinami sharedInstance] login:self];
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
	
	TinamiMatrixParser		*parser = [[TinamiMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding];
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
	searchBar.delegate = self;
	//searchBar.barStyle = UIBarStyleBlack;
	searchBar.translucent = NO;
	
	[super viewDidLoad];

	self.tableView.tableHeaderView = headerView;

	if (progressShowing_ == NO) {
		[searchBar becomeFirstResponder];
	} else {
		self.tableView.tableHeaderView = nil;
	}
}

- (void)viewDidUnload {
	[searchBar release];
	searchBar = nil;
	[searchTerm release];
	searchTerm = nil;

	[scopeSegment release];
	scopeSegment = nil;
	[typeSegment release];
	typeSegment = nil;
	[sortSegment release];
	sortSegment = nil;
	
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

- (void) saveSerchTerm:(NSString *)str withScope:(NSString *)scope type:(NSString *)type sort:(NSString *)sort {
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
		str,	@"Term",
		scope,	@"Scope",
		type,	@"Type",
		sort,	@"Sort",
		nil];
		
	NSMutableArray *ary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SerchHistoryTinami"] mutableCopy];
	if (ary == nil) {
		ary = [[NSMutableArray alloc] init];
	}
	if ([ary containsObject:info]) {
		[ary removeObject:info];
	}
	if (![ary containsObject:info]) {
		[ary insertObject:info atIndex:0];
		while ([ary count] > 100) {
			[ary removeLastObject];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:@"SerchHistoryTinami"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[ary release];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)asearchBar {
	self.searchTerm = asearchBar.text;
	[asearchBar resignFirstResponder];

	[self setScopeBarHidden:YES];

	[self saveSerchTerm:self.searchTerm withScope:[self selectedScope] type:[self selectedType] sort:[self selectedSort]];
	[self reflesh];
}

- (IBAction) slideshow {
}

#pragma mark-

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[self hideProgress];
	if (err) {
		// もいっかい
		err = [[Tinami sharedInstance] login:self];
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
