//
//  PixivUserSearchViewController.h
//  pixiViewer
//
//  Created by nya on 10/03/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivUserListViewController.h"


@interface PixivUserSearchViewController : PixivUserListViewController<UISearchBarDelegate> {
	UISearchBar			*searchBar;
	UISegmentedControl	*scopeSegment;
	
	NSString			*searchTerm;
}

@property(readwrite, retain, nonatomic) NSString *searchTerm;

@end
