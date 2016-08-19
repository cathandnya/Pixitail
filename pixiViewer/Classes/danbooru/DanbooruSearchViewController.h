//
//  DanbooruSearchViewController.h
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DanbooruMatrixViewController.h"

@interface DanbooruSearchViewController : DanbooruMatrixViewController<UISearchBarDelegate> {
	UIView				*headerView;
	UISearchBar			*searchBar;
	
	NSString			*searchTerm;
}

@property(retain, readwrite, nonatomic) IBOutlet UIView *headerView;
@property(retain, readwrite, nonatomic) IBOutlet UISearchBar *searchBar;

@property(retain, readwrite, nonatomic) NSString *searchTerm;

@end
