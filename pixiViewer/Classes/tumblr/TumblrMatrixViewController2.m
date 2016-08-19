//
//  TumblrMatrixViewController2.m
//  pixiViewer
//
//  Created by nya on 10/02/15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrMatrixViewController2.h"
#import "ImageDiskCache.h"
#import "TumblrParser.h"
#import "AccountManager.h"
#import "TumblrMediumViewController.h"
#import "Reachability.h"
#import "TumblrSlideshowViewController2.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"


@implementation TumblrMatrixViewController2

@synthesize name, needsAuth;

- (void) dealloc {
	[name release];
	[super dealloc];
}

- (ImageCache *) cache {
	return [ImageCache tumblrSmallCache];
}

- (NSString *) referer {
	return nil;
}

- (id) pixiv {
	return [Tumblr instance];
}

- (void) viewDidLoad {
	[super viewDidLoad];	
}

- (void) viewDidUnload {
	[reloadTimer invalidate];
	reloadTimer = nil;
	[super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
	if ([self.method hasPrefix:@"likes"]) {
		NSMutableArray *remove = [NSMutableArray array];
		for (NSDictionary *info in contents_) {
			if ([[info objectForKey:@"Liked"] isEqual:@"true"] == NO) {
				[remove addObject:info];
			}
		}
		
		[contents_ removeObjectsInArray:remove];
	}

	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	if ([contents_ count] > 0) {
		UIImage *image = [[self cache] imageForKey:[[contents_ objectAtIndex:0] objectForKey:@"IllustID"]];
		if (image) {
			if (image.size.width != image.size.height) {
				image = [self squareTrimmedImage:image];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TopImageChangedNotification" object:self.account userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
				image,			@"Image",
				[NSString stringWithFormat:@"%@_%@", name, self.method],	@"Method",
				nil]];
		}
	}
}

- (long) reload {
	[reloadTimer invalidate];
	reloadTimer = nil;

	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == 0) {
		return 2;
	}
	if ([Tumblr instance].logined == NO) {
		return -1;
	}
	/*
		[Tumblr instance].username = account.username;
		[Tumblr instance].password = account.password;
	
		long err = [[Tumblr instance] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			return err;
		} else {
			[self showProgress:YES withTitle:@"ログイン中..." tag:1000];
		}
		return 0;
	}
	 */
	
	if (storedContents) {
		[contents_ release];
		contents_ = [storedContents mutableCopy];
		[storedContents release];
		storedContents = nil;
		
		for (NSDictionary *pic in contents_) {
			if ([[self cache] conteinsImageForKey:[pic objectForKey:@"IllustID"]] == NO) {
				CHURLImageLoader *loader = [[CHURLImageLoader alloc] init];
				loader.delegate = self;
				loader.object = pic;
				loader.referer = [self referer];
				loader.url = [NSURL URLWithString:[[pic objectForKey:@"ThumbnailURLString"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
				if ([loadingLoaders_ count] > MATRIXPARSER_IMAGELOADER_COUNT) {
					[pendingLoaders_ addObject:loader];
				} else {
					[loader load];
					[loadingLoaders_ addObject:loader];
				}
				[loader release];
				
				UIProgressView *prog = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
				prog.progress = 0.0;
				[progressViews_ setObject:prog forKey:[pic objectForKey:@"IllustID"]];
				[prog release];
			} else {
				NSData *data = [[self cache] imageDataForKey:[pic objectForKey:@"IllustID"]];
		
				[self push:data withInfo:pic];
			}
		}
		
		showsNextButton_ = YES;
		[self.tableView reloadData];
		self.tableView.contentOffset = displayedOffset_;
		displayedOffset_ = CGPointZero;
		return 0;
	}
	
	TumblrParser			*parser = [[TumblrParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
	CHHtmlParserConnection	*con;
	
	showsNextButton_ = NO;

	pictureIsFound_ = NO;
	parser.delegate = self;
	
	NSString *authString = @"";
	if (self.needsAuth) {
		authString = [NSString stringWithFormat:@"&email=%@&password=%@", encodeURIComponent(account.username), encodeURIComponent(account.password)];
	}
	
	if ([self.method hasPrefix:@"read"]) {
		if (loadedPage_ > 0) {
			con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.tumblr.com/api/%@type=photo&start=%d&num=25%@", name, self.method, loadedPage_, authString]]];
		} else {
			con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.tumblr.com/api/%@type=photo&num=25%@", name, self.method, authString]]];		
		}
	} else {
		if (loadedPage_ > 0) {
			con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.tumblr.com/api/%@type=photo&start=%d&num=25%@", self.method, loadedPage_, authString]]];
		} else {
			con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.tumblr.com/api/%@type=photo&num=25%@", self.method, authString]]];
		}
	}
	
	if (self.needsAuth) {
		con.method = @"POST";
		con.postBody = [[NSString stringWithFormat:@"email=%@&password=%@", encodeURIComponent(account.username), encodeURIComponent(account.password)] dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	con.referer = [self referer];
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];
	return 0;
}

- (void) reloadTimer {
	reloadTimer = nil;
	[self reload];
}

- (void) selectImage:(ButtonImageView *)sender {
	id senderObject = sender.object;
	TumblrMediumViewController *controller = [[TumblrMediumViewController alloc] init];
	controller.illustID = [senderObject objectForKey:@"IllustID"];
	controller.info = senderObject;
	controller.account = account;
	controller.enableTagEdit = [self.name isEqual:[Tumblr instance].name] && [self.method hasPrefix:@"read"];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];
		app.alwaysSplitViewController.detailViewController = nc;
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

//- (void) matrixParser:(MatrixParser *)parser foundPicture:(NSMutableDictionary *)pic {
- (void) matrixParserFoundPictureMain:(NSDictionary *)pic {
	loadedPage_++;
	//[super matrixParser:parser foundPicture:pic];
	//[super performSelector:@selector(matrixParserFoundPictureMain:) withObject:pic];
	[super matrixParserFoundPictureMain:pic];
}

/*
- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	if (err == 0 && ((TumblrParser *)parser_).finished == NO) {
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reloadTimer) userInfo:nil repeats:NO];
	} else {
		[super connection:con finished:err];
	}
}
*/

- (IBAction) doSlideshow:(BOOL)random reverse:(BOOL)rev {
	TumblrSlideshowViewController2 *controller = [[TumblrSlideshowViewController2 alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = self.method;
	controller.account = self.account;
	controller.name = self.name;
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

- (NSString *) tagDefaultKey {
	return [NSString stringWithFormat:@"TumblrSavedTags_%@", self.account.username];
}

- (void) doAddTagTag {
	NSMutableArray	*ary = [[NSUserDefaults standardUserDefaults] objectForKey:[self tagDefaultKey]] ? [[[[NSUserDefaults standardUserDefaults] objectForKey:[self tagDefaultKey]] mutableCopy] autorelease] : [NSMutableArray array];
	NSMutableData	*data = [NSMutableData data];
	NSScanner		*scanner = [NSScanner scannerWithString:self.method];
	NSString		*str = nil;
	NSRange			range;
	
	[scanner scanString:@"read?tagged=" intoString:nil];
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
	[ary insertObject:str atIndex:0];
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:[self tagDefaultKey]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to tag bookmark ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
	[alert show];
	[alert release];
}

- (NSString *) blogDefaultKey {
	return [NSString stringWithFormat:@"TumblrBlogList_%@", self.account.username];
}

- (void) saveBlogs:(NSArray *)tags {
	[[NSUserDefaults standardUserDefaults] setObject:tags forKey:[self blogDefaultKey]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *) blogs {
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self blogDefaultKey]];
}

- (void) addBlog:(NSString *)str {
	NSMutableArray *ary = [NSMutableArray arrayWithArray:[self blogs]];
	if ([ary containsObject:str]) {
		[ary removeObject:str];
	}
	[ary insertObject:str atIndex:0];
	[self saveBlogs:ary];
}

- (void) doAddBlog {
	[self addBlog:self.name];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"追加しました。" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
	[alert show];
	[alert release];
}

- (void) doAddTag {
	if ([self.method hasPrefix:@"read"] && ![self.name isEqual:[Tumblr instance].name]) {
		[self doAddBlog];
	} else if ([self.method rangeOfString:@"tagged="].location != NSNotFound && [self.name isEqual:[Tumblr instance].name]) {
		[self doAddTagTag];
	}
}

- (void) addTag:(id)sender {
	if (actionSheet) [actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:NO];

	UIActionSheet *sheet = nil;
	if ([self.method hasPrefix:@"read"] && ![self.name isEqual:[Tumblr instance].name]) {
		sheet = [[UIActionSheet alloc] initWithTitle:@"この Tumblog を追加しますか？" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add ok.", nil), nil];
		sheet.tag = 100;
	} else if ([self.method rangeOfString:@"tagged="].location != NSNotFound && [self.name isEqual:[Tumblr instance].name]) {
		sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add to tag bookmark?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add ok.", nil), nil];
		sheet.tag = 100;
	}
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[sheet showFromBarButtonItem:sender animated:YES];
	} else {
		[sheet showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet = sheet;
	[sheet release];
}

- (BOOL) enableShuffle {
	return NO;
}

- (BOOL) enableAdd {
	return ([self.method hasPrefix:@"read"] && ![self.name isEqual:[Tumblr instance].name]) || ([self.method rangeOfString:@"tagged="].location != NSNotFound && [self.name isEqual:[Tumblr instance].name]);
}

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:self.name forKey:@"Name"];
	[info setObject:[NSNumber numberWithBool:self.needsAuth] forKey:@"NeedsAuth"];
	
	return info;
}

- (BOOL) needsStore {
	return YES;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
	if ([super restore:info] == NO) {
		return NO;
	}
	
	obj = [info objectForKey:@"Name"];
	if (obj == nil) {
		return NO;
	}
	self.name = obj;

	obj = [info objectForKey:@"NeedsAuth"];
	if (obj == nil) {
		return NO;
	}
	self.needsAuth = [obj boolValue];

	return YES;
}

@end
