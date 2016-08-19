//
//  ScrapingSearchViewController.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScrapingMatrixViewController.h"


@class ScrapingService;


@interface ScrapingSearchViewController : ScrapingMatrixViewController<UISearchBarDelegate> {
	UIView				*headerView;
	UISearchBar		*searchBar;
	
	NSString		*searchTerm;
	CGRect			noScopeRect;
}

@property(retain, readwrite, nonatomic) IBOutlet UIView *headerView;
@property(retain, readwrite, nonatomic) IBOutlet UISearchBar *searchBar;

@property(retain, readwrite, nonatomic) NSString *searchTerm;


- (void) setScopeBarHidden:(BOOL)b;

@end
