//
//  SeigaMatixViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/22.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaMatixViewController.h"
#import "ImageDiskCache.h"
#import "Seiga.h"
#import "SeigaMatrixParser.h"
#import "SeigaConstants.h"
#import "SeigaMediumViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "SeigaSlideshowViewController.h"


@implementation SeigaMatixViewController

- (ImageCache *) cache {
	return [ImageCache seigaSmallCache];
}

- (NSString *) referer {
	return [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"];
}

- (PixService *) pixiv {
	return [Seiga sharedInstance];
}

- (NSString *) savedTagsName {
	return @"SavedTagsSeiga";
}

- (NSString *) tags {
	NSMutableData	*data = [NSMutableData data];
	NSScanner		*scanner = [NSScanner scannerWithString:self.method];
	NSString		*str = nil;
	NSRange			range;
	
	[scanner scanUpToString:@"tags=" intoString:nil];
	[scanner scanString:@"tags=" intoString:nil];
	[scanner scanUpToString:@"&" intoString:&str];
	
	range.length = 3;
	for (range.location = 0; range.location + range.length <= [str length]; range.location += 3) {
		NSString	*substr = [str substringWithRange:range];
		if ([substr hasPrefix:@"%"]) {
			substr = [substr substringFromIndex:1];
			UInt8	val = strtol([substr cStringUsingEncoding:NSASCIIStringEncoding], NULL, 16);
			[data appendBytes:&val length:1];
		} else {
			assert(0);
			return nil;
		}
	}
	
	str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	return str;
}

- (long) reload {	
	if (storedContents) {
		[super restoreContents];
		return 0;
	}
	
	SeigaMatrixParser		*parser = [[SeigaMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding];
	if (self.scrapingInfoKey) {
		NSDictionary *d = [[SeigaConstants sharedInstance] valueForKeyPath:self.scrapingInfoKey];
		if (d) {
			parser.scrapingInfo = d;
		}
	}
	CHHtmlParserConnection	*con;
	
	showsNextButton_ = NO;
	
	pictureIsFound_ = NO;
	parser.delegate = self;
	NSString *str;
	if (loadedPage_ == 0) {
		str = [NSString stringWithFormat:@"%@%@", [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"], self.method];
	} else {
		if ([self.method rangeOfString:@"?"].location == NSNotFound) {
			str = [NSString stringWithFormat:@"%@%@?%@=%d", [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"], self.method, [[SeigaConstants sharedInstance] valueForKeyPath:@"constants.page_param"], loadedPage_ + 1];
		} else {
			str = [NSString stringWithFormat:@"%@%@&%@=%d", [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"], self.method, [[SeigaConstants sharedInstance] valueForKeyPath:@"constants.page_param"], loadedPage_ + 1];
		}
	}
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:str]];
	
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
	NSArray *menu = [[SeigaConstants sharedInstance] valueForKeyPath:@"menu"];
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
	SeigaMediumViewController *controller = [[SeigaMediumViewController alloc] init];
	controller.illustID = [senderObject objectForKey:@"IllustID"];
	controller.info = senderObject;
	controller.account = self.account;
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
	SeigaSlideshowViewController *controller = [[SeigaSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = self.method;
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
