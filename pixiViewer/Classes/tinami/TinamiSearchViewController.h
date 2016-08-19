//
//  TinamiSearchViewController.h
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiMatrixViewController.h"


@interface TinamiSearchViewController : TinamiMatrixViewController<UISearchBarDelegate> {
	UIView				*headerView;
	UISearchBar		*searchBar;
	UISegmentedControl	*scopeSegment;
	UISegmentedControl	*typeSegment;
	UISegmentedControl	*sortSegment;

	NSString		*searchTerm;
	CGRect			noScopeRect;
}

@property(retain, readwrite, nonatomic) IBOutlet UIView *headerView;
@property(retain, readwrite, nonatomic) IBOutlet UISearchBar *searchBar;
@property(retain, readwrite, nonatomic) IBOutlet UISegmentedControl *scopeSegment;
@property(retain, readwrite, nonatomic) IBOutlet UISegmentedControl *typeSegment;
@property(retain, readwrite, nonatomic) IBOutlet UISegmentedControl *sortSegment;

@property(retain, readwrite, nonatomic) NSString *searchTerm;

- (NSString *) selectedScope;

@end
