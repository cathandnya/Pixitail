//
//  SeigaSearchViewController.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/23.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SeigaMatixViewController.h"

@interface SeigaSearchViewController : SeigaMatixViewController<UISearchBarDelegate> {
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
