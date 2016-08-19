//
//  DanbooruMatrixViewController.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DanbooruMatrixViewController.h"
#import "ImageDiskCache.h"
#import "DanbooruPostsParser.h"
#import "Danbooru.h"
#import "DanbooruMediumViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "DanbooruSlideshowViewController.h"
#import "AccountManager.h"


@implementation DanbooruMatrixViewController

- (ImageCache *) cache {
	return [ImageCache danbooruSmallCache];
}

- (PixService *) pixiv {
	return [Danbooru sharedInstance];
}

- (NSString *) referer {
	return [NSString stringWithFormat:@"http://%@/", account.hostname];
}

- (NSString *) savedTagsName {
	return @"SavedTagsDanbooru";
}

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	//[info removeObjectForKey:@"Contents"];
	return info;
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
	
	DanbooruPostsParser		*parser = [[DanbooruPostsParser alloc] init];
	parser.urlBase = [NSString stringWithFormat:@"%@://%@", [[NSURL URLWithString:self.method] scheme], [[NSURL URLWithString:self.method] host]];
	CHHtmlParserConnection	*con;
	
	showsNextButton_ = NO;
	
	pictureIsFound_ = NO;
	parser.delegate = self;
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@&login=%@&password_hash=%@&page=%d", self.method, encodeURIComponent(account.username), [Danbooru hashedPassword:account.password], loadedPage_ + 1]]];
	DLog(@"%@", [NSString stringWithFormat:@"%@&login=%@&password_hash=%@&page=%d", self.method, encodeURIComponent(account.username), [Danbooru hashedPassword:account.password], loadedPage_ + 1]);
	
	con.referer = [self referer];
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];
	return 0;
}


- (void) selectImage:(ButtonImageView *)sender {
	//- (void) matrixView:(CHMatrixView *)view action:(id)senderObject {	
	id senderObject = sender.object;
	DanbooruMediumViewController *controller = [[DanbooruMediumViewController alloc] init];
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
	DanbooruSlideshowViewController *controller = [[DanbooruSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
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
