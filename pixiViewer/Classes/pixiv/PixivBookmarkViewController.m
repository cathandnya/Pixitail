//
//  PixivBookmarkViewController.m
//  pixiViewer
//
//  Created by nya on 09/08/21.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivBookmarkViewController.h"


@implementation PixivBookmarkViewController

- (void) reloadHide {
	if (maxPageHide_ > 0 && loadedPageHide_ >= maxPageHide_) {
		return;
	}
	
	PixivMatrixParser		*parser = [[PixivMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding];
	CHHtmlParserConnection	*con;
	
	[(CHMatrixView *)self.view setShowsLoadNextButton:NO];

	pictureIsFound_ = NO;
	parser.delegate = self;
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/%@.php?rest=hide&p=%d", self.method, loadedPageHide_ + 1]]];
	
	con.referer = @"http://www.pixiv.net/";
	con.delegate = self;
	parserHide_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
}

- (void) reload {
	if (maxPage_ > 0 && loadedPage_ >= maxPage_) {
		[self reloadHide];
		return;
	}
	
	PixivMatrixParser		*parser = [[PixivMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding];
	CHHtmlParserConnection	*con;
	
	[(CHMatrixView *)self.view setShowsLoadNextButton:NO];

	pictureIsFound_ = NO;
	parser.delegate = self;
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/%@.php?p=%d", self.method, loadedPage_ + 1]]];
	
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
}

- (void) pixivParser:(CHHtmlParser *)parser finished:(long)err {
	if (parser == parser_) {
		if (pictureIsFound_) {
			loadedPage_++;
			maxPage_ = ((PixivMatrixParser *)parser).maxPage;
			
			if (loadedPage_ < maxPage_) {
				[(CHMatrixView *)self.view setShowsLoadNextButton:YES];
			}
		}

		[parser_ release];
		parser_ = nil;

		if (maxPageHide_ == 0 || loadedPageHide_ < maxPageHide_) {
			[self reloadHide];
		}
	} else if (parser == parserHide_) {
		if (pictureIsFound_) {
			loadedPage_++;
			maxPageHide_ = ((PixivMatrixParser *)parser).maxPage;
			
			if (loadedPageHide_ < maxPageHide_ || loadedPage_ < maxPage_) {
				[(CHMatrixView *)self.view setShowsLoadNextButton:YES];
			}
		}

		[parserHide_ release];
		parserHide_ = nil;
	}
}

@end
