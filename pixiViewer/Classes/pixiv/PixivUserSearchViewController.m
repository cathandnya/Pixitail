//
//  PixivUserSearchViewController.m
//  pixiViewer
//
//  Created by nya on 10/03/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivUserSearchViewController.h"
#import "Pixiv.h"
#import "PixivUserListParser.h"
#import "PixivSearchedUserListParser.h"
#import "AccountManager.h"
#import "CHHtmlParserConnectionNoScript.h"


@implementation PixivUserSearchViewController

@synthesize searchTerm;

- (void) dealloc {
	[searchBar release];
	[scopeSegment release];
	[searchTerm release];

	[super dealloc];
}

- (void) load {
	long	err = [[self pixiv] allertReachability];
	if (err) {
		return;
	}
	
	/*
	if (err == -1) {
		[Pixiv sharedInstance].username = account.username;
		[Pixiv sharedInstance].password = account.password;

		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			return;
		} else {
			[self showProgress:YES withTitle:@"ログイン中..." tag:1000];
		}
		return;
	} else if (err) {
		return;
	}
	 */
	
	if ([self.searchTerm length] == 0) {
		return;
	}

	PixivUserListParser		*parser = [[PixivSearchedUserListParser alloc] initWithEncoding:NSUTF8StringEncoding];
	CHHtmlParserConnection	*con;
	
	NSMutableString *urlstr = [NSMutableString stringWithString:@"http://www.pixiv.net/search_user.php?mode=search"];
	if (scopeSegment.selectedSegmentIndex == 0) {
		[urlstr appendFormat:@"&nick=%@", encodeURIComponent(self.searchTerm)];
		[urlstr appendFormat:@"&nick_mf=%@", @"0"];
	} else {
		[urlstr appendFormat:@"&kw=%@", encodeURIComponent(self.searchTerm)];
	}
	[urlstr appendFormat:@"&sex=0"];
	[urlstr appendFormat:@"&i=1"];
	[urlstr appendFormat:@"&p=%d", loadedPage_ + 1];
	
	con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:urlstr]];
	
	con.referer = @"http://www.pixiv.net/search_user.php";
	con.delegate = self;
	parser.method = self.method;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];
}

- (void) setupHeader {
	CGRect r;
	if (1) {
		UIView *v = [[[UIView alloc] init] autorelease];
		r = CGRectMake(0, 0, 320, 44 * 2);
		v.frame = r;
		v.backgroundColor = [UIColor colorWithRed:176/255.0 green:188/255.0 blue:205/255.0 alpha:1];
		v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.tableView.tableHeaderView = v;
	}
	if (searchBar == nil) {
		searchBar = [[UISearchBar alloc] init];
		r = CGRectMake(0, 0, 320, 44);
		searchBar.frame = r;
		searchBar.barStyle = UIBarStyleDefault;
		searchBar.delegate = self;
		searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	}
	[self.tableView.tableHeaderView addSubview:searchBar];
	if (scopeSegment == nil) {
		scopeSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"ニックネーム", @"キーワード", nil]];
		r = CGRectMake(10, 49, 300, 34);
		scopeSegment.frame = r;
		scopeSegment.segmentedControlStyle = UISegmentedControlStyleBar;
		scopeSegment.selectedSegmentIndex = 0;
		scopeSegment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[scopeSegment addTarget:self action:@selector(segmentAction) forControlEvents:UIControlEventValueChanged];
	}
	[self.tableView.tableHeaderView addSubview:scopeSegment];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	/*
	[users_ release];
	users_ = [[NSMutableArray alloc] init];
	[imageLoaders_ release];
	imageLoaders_ = [[NSMutableArray alloc] init];
	loadedPage_ = 0;
	*/
	
	if (progressShowing_ == NO) {
		[self setupHeader];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFinished:) name:@"LoginFinishedNotification" object:nil];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if ([users_ count] == 0 && progressShowing_ == NO) {
		[searchBar becomeFirstResponder];
	}
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	BOOL hasNext = ((PixivSearchedUserListParser *)parser_).hasNext;
	[super connection:con finished:err];
	if (hasNext) {
		maxPage_ = loadedPage_ + 1;
	}
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)asearchBar {
	self.searchTerm = @"";
	
	[users_ removeAllObjects];
	loadedPage_ = 0;
	[self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)asearchBar {
	self.searchTerm = asearchBar.text;
	[asearchBar resignFirstResponder];

	[self load];
}

- (void) segmentAction {
	[searchBar becomeFirstResponder];
}

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	if (err == 0) {
		[self setupHeader];
		[searchBar becomeFirstResponder];
	}
	[super pixService:sender loginFinished:err];
}

- (void) loginFinished:(NSNotification *)notif {
	[self load];
}

@end
