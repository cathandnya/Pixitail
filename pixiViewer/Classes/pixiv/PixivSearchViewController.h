//
//  PixivSearchViewController.h
//  pixiViewer
//
//  Created by nya on 09/08/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivMatrixViewController.h"


@interface PixivSearchViewController : PixivMatrixViewController<UISearchBarDelegate> {
	UIView				*headerView;
	UISearchBar		*searchBar;
	UIToolbar			*scopeBar;
	UISegmentedControl	*scopeSegment;

	NSString		*searchTerm;
	CGRect			noScopeRect;
}

@property(retain, readwrite, nonatomic) IBOutlet UIView *headerView;
@property(retain, readwrite, nonatomic) IBOutlet UISearchBar *searchBar;
@property(retain, readwrite, nonatomic) IBOutlet UIToolbar *scopeBar;
@property(retain, readwrite, nonatomic) IBOutlet UISegmentedControl *scopeSegment;

@property(retain, readwrite, nonatomic) NSString *searchTerm;


- (NSString *) selectedScope;
- (void) setScopeBarHidden:(BOOL)b;

@end
