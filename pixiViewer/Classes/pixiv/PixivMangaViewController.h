//
//  PixivMangaViewController.h
//  pixiViewer
//
//  Created by nya on 09/09/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHHtmlParserConnection.h"
#import "PixivMangaPageViewController.h"
#import "DefaultViewController.h"


@class PixivUgoIllust;


@interface PixivMangaViewController : DefaultViewController<CHHtmlParserConnectionDelegate, PixivMangaPageViewControllerDelegate, UIScrollViewDelegate, UIActionSheetDelegate> {
	NSString *illustID;
	id		parser_;
	CHHtmlParserConnection	*connection_;
	int		curPage_;
	UIScrollView *scrollView;
	NSArray *urlStrings_;
	NSArray *viewControllers_;
	UIActionSheet *actionSheet_;

	id parent;
}

@property(readwrite, retain, nonatomic) NSString *illustID;
@property(readwrite, retain, nonatomic) PixivUgoIllust *ugoIllust;

- (void) setURLs:(NSArray *)array;
- (long) reload;

@end
