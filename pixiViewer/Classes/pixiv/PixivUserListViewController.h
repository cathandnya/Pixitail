//
//  PixivUserListViewController.h
//  pixiViewer
//
//  Created by nya on 09/10/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"
#import "CHHtmlParserConnection.h"
#import "PixService.h"


@class PixivUserListParser;


@class URLCacheDataLoader;
@protocol URLCacheDataLoaderDelegate
- (void) loader:(URLCacheDataLoader *)sender loadFinished:(NSData *)data;
@end


@class PixAccount;
@class PixService;

@interface PixivUserListViewController : DefaultTableViewController<CHHtmlParserConnectionDelegate, URLCacheDataLoaderDelegate, PixServiceLoginHandler> {
	PixivUserListParser			*parser_;
	CHHtmlParserConnection		*connection_;
	NSMutableArray				*imageLoaders_;
	NSMutableArray				*users_;
	int							loadedPage_;
	int							maxPage_;

	NSString					*method;
	PixAccount *account;
}

@property(retain, nonatomic, readwrite) NSString *method;
@property(retain, nonatomic, readwrite) PixAccount *account;
@property(retain, nonatomic, readwrite) NSString *scrapingInfoKey;

- (PixService *) pixiv;

@end
