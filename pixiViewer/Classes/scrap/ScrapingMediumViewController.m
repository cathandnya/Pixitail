//
//  ScrapingMediumViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import "ScrapingMediumViewController.h"
#import "ScrapingService.h"
#import "ImageDiskCache.h"
#import "ImageLoaderManager.h"
#import "ScrapingMediumParser.h"
#import "ScrapingBigViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "ScrapingMatrixViewController.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "ScrapingMangaViewController.h"
#import "ScrapingConstants.h"


@implementation ScrapingMediumViewController

@synthesize serviceName;
@dynamic service;

- (void) dealloc {
	[serviceName autorelease];
	[super dealloc];
}

- (PixService *) pixiv {
	return [ScrapingService serviceFromName:serviceName];
}

- (ScrapingService *) service {
	return (ScrapingService *)[self pixiv];
}

- (ImageCache *) cache {
	return [ImageCache mediumCacheForName:serviceName];
}

- (NSString *) referer {
	return [self.service.constants valueForKeyPath:@"urls.base"];
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithName:serviceName];
	loader.referer = [self referer];
	return loader;
}

- (NSString *) serviceName {
	return NSLocalizedString(serviceName, nil);
}

- (void) update:(NSDictionary *)info {
	NSMutableDictionary *minfo = [[info mutableCopy] autorelease];
	[minfo setObject:self.illustID forKey:@"IllustID"];
	NSString *big = [self.service.constants valueForKeyPath:@"urls.big"];
	if (big) {
		[minfo setObject:[NSString stringWithFormat:big, self.illustID] forKey:@"BigURLString"];
	}
	[super update:minfo];
}

- (BOOL) noRedirect {
	return [[self.service.constants valueForKeyPath:@"constants.no_redirect"] boolValue];
}

- (id) parser {
	Class parserClass = NSClassFromString([NSString stringWithFormat:@"%@MediumParser", serviceName]);
	if (parserClass == nil) {
		parserClass = [ScrapingMediumParser class];
	}
	ScrapingMediumParser *parser = [[parserClass alloc] initWithEncoding:NSUTF8StringEncoding];
	parser.scrapingInfo = [self.service.constants valueForKey:@"medium"];
	return [parser autorelease];
}

- (CHHtmlParserConnection *) connection {
	//[[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.medium"], self.illustID]]] returningResponse:nil error:nil] writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"medium.html"] atomically:YES];
	CHHtmlParserConnectionNoScript *con = [[[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.medium"], self.illustID]]] autorelease];
	con.noRedirect = [self noRedirect];
	return con;
}

- (void) imageButtonAction:(id)obj {
	if (![info_ objectForKey:@"MediumURLString"]) {
		return;
	}
	
	if ([info_ objectForKey:@"Images"]) {		
		Class class = NSClassFromString([NSString stringWithFormat:@"%@MangaViewController", serviceName]);
		if (!class) {
			class = [ScrapingMangaViewController class];
		}
		ScrapingMangaViewController *controller = nil;
		controller = [[class alloc] init];
		controller.illustID = self.illustID;
		controller.serviceName = serviceName;
		//[controller setURLs:ary];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
			[app pushViewController:controller animated:YES];
		} else {
			[self.navigationController pushViewController:controller animated:YES];
		}
		[controller release];
	} else {
		Class class = NSClassFromString([NSString stringWithFormat:@"%@BigViewController", serviceName]);
		if (!class) {
			class = [ScrapingBigViewController class];
		}
		ScrapingBigViewController *controller = nil;
		controller = [[class alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
		controller.illustID = self.illustID;
		controller.serviceName = serviceName;
		//controller.account = account;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
			[app pushViewController:controller animated:YES];
		} else {
			[self.navigationController pushViewController:controller animated:YES];
		}
		[controller release];
	}
}

- (void) tagButtonAction:(UIButton *)sender {
	NSInteger idx = sender.tag;
	NSArray *tags = [self.info objectForKey:@"Tags"];
	NSString *tagName = nil;
	NSString *method = nil;
	if (idx < tags.count) {
		id obj = [tags objectAtIndex:idx];
		if ([obj isKindOfClass:[NSString class]]) {
			tagName = obj;
		} else if ([obj isKindOfClass:[NSDictionary class]]) {
			if ([(NSDictionary *)obj objectForKey:@"URL"]) {
				NSString *str = [(NSDictionary *)obj objectForKey:@"URL"];
				if ([str hasPrefix:[self.service.constants valueForKeyPath:@"urls.base"]]) {
					method = [str substringFromIndex:[[self.service.constants valueForKeyPath:@"urls.base"] length]];
				}
			} else {
				tagName = [(NSDictionary *)obj objectForKey:@"Name"];
			}
		}
	}
	
	if (tagName) {
		NSData				*data = [tagName dataUsingEncoding:NSUTF8StringEncoding];
		NSMutableString		*tag = [NSMutableString string];
		int					i;
		
		for (i = 0; i < [data length]; i++) {
			[tag appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
		}
		method = [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.tag"], tag];
	}
	if (!method) {
		return;
	}
	
	Class class = NSClassFromString([NSString stringWithFormat:@"%@MatrixViewController", serviceName]);
	if (!class) {
		class = [ScrapingMatrixViewController class];
	}
	ScrapingMatrixViewController *controller = [[class alloc] init];
	controller.method = method;
	controller.account = account;
	controller.serviceName = serviceName;
	controller.navigationItem.title = ((UIButton *)sender).titleLabel.text;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[(UINavigationController *)app.alwaysSplitViewController.rootViewController pushViewController:controller animated:![app.alwaysSplitViewController rootIsHidden]];
		[app.alwaysSplitViewController setRootHidden:NO animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) showUserIllust {
	Class class = NSClassFromString([NSString stringWithFormat:@"%@MatrixViewController", serviceName]);
	if (!class) {
		class = [ScrapingMatrixViewController class];
	}
	ScrapingMatrixViewController *controller = [[class alloc] init];
	controller.method = [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.user"], [info_ objectForKey:@"UserID"]];
	controller.navigationItem.title = [NSString stringWithFormat:@"%@の%@", [info_ objectForKey:@"UserName"], @"作品"];
	controller.account = account;
	controller.serviceName = serviceName;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[(UINavigationController *)app.alwaysSplitViewController.rootViewController pushViewController:controller animated:![app.alwaysSplitViewController rootIsHidden]];
		[app.alwaysSplitViewController setRootHidden:NO animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) action:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];
	
	UIActionSheet	*alert;
	alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Go to the web of this illust", nil), @"共有...", nil];
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (IBAction) goToWeb {	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self url]]];
}

- (void)action:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != sheet.cancelButtonIndex) {
		switch (buttonIndex) {
			case 0:
				[self goToWeb];
				break;
			case 1:
				[self twitter];
				break;
			default:
				break;
		}
	}
}

- (UIBarButtonItem *) ratingButton {
	return nil;
}

- (BOOL) showAddButton {
	return NO;
}

- (BOOL) ratingEnabled {
	return NO;
}

- (BOOL) commentEnabled {
	return NO;
}

- (NSString *) tumblrServiceName {
	return [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", [self.service.constants valueForKeyPath:@"urls.base"], [self serviceName]];
}

- (NSString *) url {
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.medium"], self.illustID];
}

- (NSString *) parserClassName {
	Class parserClass = NSClassFromString([NSString stringWithFormat:@"%@MediumParser", serviceName]);
	if (parserClass == nil) {
		return @"ScrapMediumParser";
	} else {
		return [NSString stringWithFormat:@"%@MediumParser", serviceName];
	}
}

- (NSString *) sourceURL {
	return [self.info objectForKey:@"source"];
}

- (NSArray *) saveImageURLs {
	if ([[info_ objectForKey:@"Images"] count] > 0) {	
		NSMutableArray *mary = [NSMutableArray array];
		for (NSDictionary *d in [info_ objectForKey:@"Images"]) {
			[mary addObject:[d objectForKey:@"URLString"]];
		}
		return mary;
	} else if ([info_ objectForKey:@"BigURLString"]) {
		return [NSArray arrayWithObject:[info_ objectForKey:@"BigURLString"]];
	} else {
		return [NSArray arrayWithObject:[NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.big"], self.illustID]];
	}
}

#pragma mark-

- (void) setupToolbar {
    NSMutableArray	*tmp = [NSMutableArray array];
    UIBarButtonItem	*item;
    
    if (self.service.ratingIsEnabled || self.service.commentIsEnabled || self.service.bookmarkIsEnabled || self.service.favoriteUserIsEnabled) {
        [tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star.png"] style:UIBarButtonItemStylePlain target:self action:@selector(starAction:)] autorelease]];
        [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    }
        
	[tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save.png"] style:UIBarButtonItemStylePlain target:self action:@selector(saveAction:)] autorelease]];
    [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    
    [tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left_tool.png"] style:UIBarButtonItemStylePlain target:self action:@selector(prev)] autorelease]];
    [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
	
    [tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"right_tool.png"] style:UIBarButtonItemStylePlain target:self action:@selector(next)] autorelease]];
    [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
	
    item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)] autorelease];
    [tmp addObject:item];
	    
    [self setToolbarItems:tmp animated:NO];
}

- (void) starAction:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];
	
	UIActionSheet	*alert;
    alert = [[[UIActionSheet alloc] init] autorelease];
    alert.delegate = self;
    alert.tag = 1000;
	
	if (self.service.ratingIsEnabled) {
		[alert addButtonWithTitle:[self.service.constants valueForKeyPath:@"constants.rating_title"]];
	}
	if (self.service.commentIsEnabled) {
		[alert addButtonWithTitle:[self.service.constants valueForKeyPath:@"constants.comment_title"]];
	}
	if (self.service.bookmarkIsEnabled) {
		[alert addButtonWithTitle:[self.service.constants valueForKeyPath:@"constants.bookmark_title"]];
	}
	if (self.service.favoriteUserIsEnabled) {
		[alert addButtonWithTitle:[self.service.constants valueForKeyPath:@"constants.favorite_user_title"]];
	}
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	alert.cancelButtonIndex = alert.numberOfButtons - 1;
	
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;	
}

- (void) rating:(id)sender {
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (sheet.tag == 1000) {
		actionSheet_ = nil;

		NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
		if ([title isEqualToString:[self.service.constants valueForKeyPath:@"constants.rating_title"]]) {
			[self rating:nil];
		} else if ([title isEqualToString:[self.service.constants valueForKeyPath:@"constants.comment_title"]]) {
			[self performSelector:@selector(comment)];
		} else if ([title isEqualToString:[self.service.constants valueForKeyPath:@"constants.bookmark_title"]]) {
			[self.service addToBookmark:info_];
		} else if ([title isEqualToString:[self.service.constants valueForKeyPath:@"constants.favorite_user_title"]]) {
			[self.service addToFavoriteUser:info_];
		}
	} else {
		[super actionSheet:sheet clickedButtonAtIndex:buttonIndex];
	}
}

- (int) maxLengthOfComment {
	return [[self.service.constants valueForKeyPath:@"constants.max_length_of_comment"] intValue];
}

@end
