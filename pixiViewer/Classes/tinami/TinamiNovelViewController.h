//
//  TinamiNovelViewController.h
//  pixiViewer
//
//  Created by nya on 10/04/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiMediumViewController.h"
#import "DefaultViewController.h"


@interface TinamiNovelViewController : DefaultViewController {
	NSArray *pages;
	NSUInteger currentPage;
	
	UIWebView *webView;
}

@property(readwrite, retain, nonatomic) NSArray *pages;

- (void) reload;

@end
