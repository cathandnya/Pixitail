//
//  PixaSearchViewController.h
//  pixiViewer
//
//  Created by nya on 09/09/23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaMatrixViewController.h"


@interface PixaSearchViewController : PixaMatrixViewController<UISearchBarDelegate>  {
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

@end