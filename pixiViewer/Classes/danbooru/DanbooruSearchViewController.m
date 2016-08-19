//
//  DanbooruSearchViewController.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DanbooruSearchViewController.h"
#import "DanbooruPostsParser.h"
#import "Danbooru.h"
#import "AccountManager.h"


@implementation DanbooruSearchViewController

@synthesize searchTerm;
@synthesize headerView, searchBar;

- (void) dealloc {
	[searchBar release];
	searchBar = nil;
	[searchTerm release];
	searchTerm = nil;
	[super dealloc];
}


- (int) scopeCount {
	return 3;
}

- (NSString *) urlString {
	return [NSString stringWithFormat:@"http://%@/post/index.json?limit=20&tags=%@&page=%d&login=%@&password_hash=%@", account.hostname, encodeURIComponent(self.searchTerm), loadedPage_ + 1, encodeURIComponent(account.username), [Danbooru hashedPassword:account.password]];
}

- (NSString *) referer {
	return [NSString stringWithFormat:@"http://%@/", account.hostname];
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

#define MIN_HEIGHT 44
#define MAX_HEIGHT 88
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
	DanbooruPostsParser		*parser = [[DanbooruPostsParser alloc] init];
	parser.urlBase = [NSString stringWithFormat:@"http://%@", account.hostname];
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
	searchBar.translucent = NO;
		
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

- (void) saveSerchTerm:(NSString *)str {
	NSMutableArray *ary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SerchHistoryDanbooru"] mutableCopy];
	if (ary == nil) {
		ary = [[NSMutableArray alloc] init];
	}
	if ([ary containsObject:str]) {
		[ary removeObject:str];
	}
	[ary insertObject:str atIndex:0];
	while ([ary count] > 40) {
		[ary removeLastObject];
	}
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:@"SerchHistoryDanbooru"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[ary release];
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

	[self saveSerchTerm:self.searchTerm];
	
	[self setScopeBarHidden:YES];
	
	[self reflesh];
}

- (IBAction) slideshow {
	/*
	PixivSlideshowViewController *controller = [[PixaSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = [NSString stringWithFormat:@"search.php?word=%@&s_mode=%@&", encodeURIComponent(self.searchTerm), [self selectedScope]];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
	 */
}

@end
