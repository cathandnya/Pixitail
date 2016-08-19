//
//  ScrapingMatrixViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingMatrixViewController.h"
#import "ImageDiskCache.h"
#import "ScrapingService.h"
#import "ConstantsManager.h"
#import "ScrapingMatrixParser.h"
#import "PixivMediumViewController.h"
#import "PixivSlideshowViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "ScrapingMediumViewController.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "ScrapingSlideshowViewController.h"


@implementation ScrapingMatrixViewController

@synthesize serviceName;
@dynamic service;

- (void) dealloc {
	self.serviceName = nil;
	[super dealloc];
}

- (PixService *) pixiv {
	return [ScrapingService serviceFromName:serviceName];
}

- (ScrapingService *) service {
	return (ScrapingService *)[self pixiv];
}

- (ImageCache *) cache {
	return [ImageCache smallCacheForName:serviceName];
}

- (NSString *) referer {
	return [self.service.constants valueForKeyPath:@"urls.base"];
}

- (NSString *) urlString {
	NSString *str;
	if (loadedPage_ == 0) {
		str = [NSString stringWithFormat:@"%@%@", [self.service.constants valueForKeyPath:@"urls.base"], self.method];
	} else {
		if ([self.method rangeOfString:@"?"].location == NSNotFound) {
			str = [NSString stringWithFormat:@"%@%@?%@=%d", [self.service.constants valueForKeyPath:@"urls.base"], self.method, [self.service.constants valueForKeyPath:@"constants.page_param"], loadedPage_ + 1];
		} else {
			str = [NSString stringWithFormat:@"%@%@&%@=%d", [self.service.constants valueForKeyPath:@"urls.base"], self.method, [self.service.constants valueForKeyPath:@"constants.page_param"], loadedPage_ + 1];
		}
	}
	return str;
}

- (NSData *) postBody {
	return nil;
}

- (BOOL) noRedirect {
	return [[self.service.constants valueForKeyPath:@"constants.no_redirect"] boolValue];
}

- (long) reload {	
	if (storedContents) {
		[super restoreContents];
		return 0;
	}
	NSString *str = [self urlString];
	if (!str) {
		return 0;
	}
	
	Class parserClass = NSClassFromString([NSString stringWithFormat:@"%@MatrixParser", serviceName]);
	if (parserClass == nil) {
		parserClass = [ScrapingMatrixParser class];
	}
	ScrapingMatrixParser *parser = [[parserClass alloc] initWithEncoding:NSUTF8StringEncoding];
	if (self.scrapingInfoKey) {
		parser.scrapingInfo = [self.service.constants valueForKeyPath:self.scrapingInfoKey];
	} else {
		parser.scrapingInfo = [self.service.constants valueForKey:@"matrix"];
	}
	CHHtmlParserConnection	*con;
	
	showsNextButton_ = NO;
	
	pictureIsFound_ = NO;
	parser.delegate = self;
	con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:str]];
	con.noRedirect = [self noRedirect];
	NSData *postBody = [self postBody];
	if (postBody) {
		con.method = @"POST";
		con.postBody = postBody;
	}
	
	DLog(@"%@", str);
	/*
	 NSError *err = nil;
	 NSURLResponse *res = nil;
	 NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:str]] returningResponse:&res error:&err];
	 [data writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"matrix.html"] atomically:YES];
	 */
	
	con.referer = [self referer];
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];
	return 0;
}

- (void) matrixParserFinishedMain:(NSNumber *)num {
	[super matrixParserFinishedMain:num];
	
	NSDictionary *rowInfo = nil;
	NSArray *menu = [self.service.constants valueForKeyPath:@"menu"];
	for (NSDictionary *a in menu) {
		for (NSDictionary *d in [a objectForKey:@"rows"]) {
			if ([[d objectForKey:@"method"] isEqual:self.method]) {
				rowInfo = d;
				break;
			}
		}
		if (rowInfo) {
			break;
		}
	}
	if ([[rowInfo objectForKey:@"no_pages"] boolValue]) {
		showsNextButton_ = NO;
	}
	
	[self.tableView reloadData];
}

- (void) selectImage:(ButtonImageView *)sender {
	id senderObject = sender.object;
	Class class = NSClassFromString([NSString stringWithFormat:@"%@MediumViewController", serviceName]);
	if (!class) {
		class = [ScrapingMediumViewController class];
	}
	ScrapingMediumViewController *controller = [[class alloc] init];
	controller.illustID = [senderObject objectForKey:@"IllustID"];
	controller.info = senderObject;
	controller.account = self.account;
	controller.serviceName = serviceName;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];
		app.alwaysSplitViewController.detailViewController = nc;
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) doSlideshow:(BOOL)random reverse:(BOOL)rev {
	Class class = NSClassFromString([NSString stringWithFormat:@"%@SlideshowViewController", serviceName]);
	if (!class) {
		class = [ScrapingSlideshowViewController class];
	}
	ScrapingSlideshowViewController *controller = [[class alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = self.method;
	controller.serviceName = self.serviceName;
	[controller setPage:loadedPage_];
	[controller setMaxPage:maxPage_];
	[controller setContents:contents_ random:random reverse:rev];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[app pushViewController:controller animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (BOOL) enableShuffle {
	return NO;
}

@end
