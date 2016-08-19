//
//  ScrapingSearchViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingSearchViewController.h"
#import "ScrapingService.h"
#import "ScrapingConstants.h"


@implementation ScrapingSearchViewController

@synthesize searchTerm;
@synthesize headerView, searchBar;

- (NSString *) defaultName {
	return [NSString stringWithFormat:@"%@SerchHistory", self.serviceName];
}

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

- (NSString *) methodString {
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.search"], encodeURIComponent(searchTerm)];
}

- (NSString *) urlString {
	if (searchTerm.length == 0) {
		return nil;
	}
	
	NSString *str =  [NSString stringWithFormat:@"%@%@", [self.service.constants valueForKeyPath:@"urls.base"], [self methodString]];
	if ([str rangeOfString:@"?"].location == NSNotFound) {
		str = [str stringByAppendingFormat:@"?%@=%d", [self.service.constants valueForKeyPath:@"constants.page_param"], loadedPage_ + 1];
	} else {
		str = [str stringByAppendingFormat:@"&%@=%d", [self.service.constants valueForKeyPath:@"constants.page_param"], loadedPage_ + 1];
	}
	return str;
}

- (NSString *) referer {
	return [self.service.constants valueForKeyPath:@"urls.base"];
}

- (NSString *) httpMethod {
	return nil;
}


- (UITableView *) matrixView {
	return self.tableView;
}

- (void) setupHeaderFooter {
	if (progressShowing_) {
		self.tableView.tableHeaderView = nil;
	} else {
		self.tableView.tableHeaderView = headerView;
	}	
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

- (CGFloat) topMargin {
	return 0;//[super topMargin] + 44;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	//searchBar.showsScopeBar = YES;
	//searchBar.scopeButtonTitles = [NSArray arrayWithObjects:NSLocalizedString(@"Tags", nil), NSLocalizedString(@"Title/Caption", nil), nil];
	searchBar.delegate = self;
	//searchBar.barStyle = UIBarStyleBlack;
	//searchBar.tintColor = [UIColor blackColor];
	searchBar.translucent = NO;
	//scopeSegment.tintColor = [UIColor darkGrayColor];
	
	if (progressShowing_ == NO) {
		[searchBar becomeFirstResponder];
		//[scopeBar setHidden:NO];
		[self setScopeBarHidden:NO];		
	} else {
		self.tableView.tableHeaderView = nil;
	}
	
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFinished:) name:@"LoginFinishedNotification" object:nil];
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

- (void) saveSerchTerm:(NSString *)str {
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
						  str,		@"Term",
						  nil];
	
	NSMutableArray *ary = [[[NSUserDefaults standardUserDefaults] objectForKey:[self defaultName]] mutableCopy];
	if (ary == nil) {
		ary = [[NSMutableArray alloc] init];
	}
	if (![ary containsObject:info]) {
		[ary insertObject:info atIndex:0];
		if ([ary count] > 100) {
			[ary removeLastObject];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:[self defaultName]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[ary release];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)asearchBar {
	self.searchTerm = asearchBar.text;
	[asearchBar resignFirstResponder];
	
	[self setScopeBarHidden:YES];
	
	[self saveSerchTerm:self.searchTerm];
	[self reflesh];
}

/*
- (IBAction) slideshow {
	SeigaSlideshowViewController *controller = [[SeigaSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = [self methodString];
	controller.scrapingInfoKey = self.scrapingInfoKey;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}
*/

//- (void) loginFinished:(NSNotification *)notif {
//	[self reload];
//}

#pragma mark-

/*
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
*/

@end
