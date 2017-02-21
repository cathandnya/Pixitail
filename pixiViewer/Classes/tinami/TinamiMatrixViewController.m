//
//  TinamiMatrixViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiMatrixViewController.h"
#import "ImageDiskCache.h"
#import "Tinami.h"
#import "TinamiMatrixParser.h"
#import "TinamiMediumViewController.h"
#import "AccountManager.h"
#import "TinamiSlideshowViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"


@implementation TinamiMatrixViewController

- (ImageCache *) cache {
	return [ImageCache tinamiSmallCache];
}

- (NSString *) referer {
	return @"http://www.tinami.com/";
}

- (PixService *) pixiv {
	return [Tinami sharedInstance];
}

- (long) reload {
	long	err = [[Tinami sharedInstance] allertReachability];
	if (err) {
		return err;
	}
	/*
	if (err == -1) {
		[self pixiv].username = account.username;
		[self pixiv].password = account.password;
	
		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			return err;
		} else {
			[self showProgress:YES withTitle:@"ログイン中..." tag:1000];
		}
		return 0;
	} else if (err) {
		return err;
	}
	 */

	if (storedContents) {
		[super restoreContents];
		return 0;
	}
		
	TinamiMatrixParser		*parser = [[TinamiMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
	CHHtmlParserConnection	*con;
	
	showsNextButton_ = NO;

	pictureIsFound_ = NO;
	parser.delegate = self;
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.tinami.com/api/%@&api_key=%@&page=%d&auth_key=%@", self.method, TINAMI_API_KEY, loadedPage_ + 1, [Tinami sharedInstance].authKey]]];
	//con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.tinami.com/%@", self.method]]];
	
	con.referer = [self referer];
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];
	return 0;
}


- (void) selectImage:(ButtonImageView *)sender {
	id senderObject = sender.object;
	TinamiMediumViewController *controller = [[TinamiMediumViewController alloc] init];
	controller.illustID = [senderObject objectForKey:@"IllustID"];
	controller.method = self.method;
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
	PixivSlideshowViewController *controller = [[TinamiSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
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

- (void) doAddTag {
	NSMutableArray	*ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedTagsTinami"] ? [[[[NSUserDefaults standardUserDefaults] objectForKey:@"SavedTagsTinami"] mutableCopy] autorelease] : [NSMutableArray array];
	NSMutableData	*data = [NSMutableData data];
	NSScanner		*scanner = [NSScanner scannerWithString:self.method];
	NSString		*str = nil;
	NSString		*type = nil;
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
			return;
		}
	}
	
	str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if ([ary containsObject:str]) {
		[ary removeObject:str];
	}

	[NSScanner scannerWithString:self.method];
	[scanner scanUpToString:@"cont_type[]=" intoString:nil];
	[scanner scanString:@"cont_type[]=" intoString:nil];
	[scanner scanUpToString:@"&" intoString:&type];
			
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
		str,	@"Tag",
		type,	@"Type",
		nil];
	[ary insertObject:info atIndex:0];
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:@"SavedTagsTinami"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to tag bookmark ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
	[alert show];
	[alert release];
}

- (void) random {
	if ([self.method rangeOfString:@"sort=rand"].location == NSNotFound) {
		self.method = [self.method stringByAppendingString:@"&sort=rand"];
	}

	[contents_ removeAllObjects];
	
	loadedPage_ = 0;
	[self reload];
}

@end
