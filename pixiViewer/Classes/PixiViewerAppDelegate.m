//
//  PixiViewerAppDelegate.m
//  pixiViewer
//
//  Created by nya on 09/08/17.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "PixiViewerAppDelegate.h"
#import "NetworkActivityIndicator.h"
#import "Pixiv.h"
#import "Pixa.h"
#import "ImageDiskCache.h"
#import "AccountListViewController.h"
#import "AccountManager.h"
#import "PixivTopViewController.h"
#import "PixaTopViewController.h"
#import "TinamiTopViewController.h"
#import "SettingViewController.h"
#import "PixivMediumViewController.h"
#import "PixaMediumViewController.h"
#import "TinamiMediumViewController.h"
#import "Tinami.h"
#import "DropBoxTail.h"
#import "EvernoteTail.h"
#import "PostQueue.h"
#import "UserDefaults.h"
#import "AlwaysSplitViewController.h"
#import "PixivMatrixViewController.h"
#import "SFHFKeychainUtils.h"
#import "StatusMessageViewController.h"
#ifdef PIXITAIL
#import "PixitailConstants.h"
#endif
#import "SkyDrive.h"
#import "SeigaTopViewController.h"
#import "SeigaMediumViewController.h"
#import "DanbooruTopViewController.h"
#import "DanbooruMediumViewController.h"
#import "WidgetSettingViewController.h"


static NSString *urlDecode(NSString *str) {
	return [(NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)str, CFSTR(":/?#[]@!$&()*+,;=%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease];
}

static NSString *idFrom36(NSString *num) {
	const char *str = [num cStringUsingEncoding:NSASCIIStringEncoding];
	int len = (int)strlen(str);
	unsigned long ret = 0;
	
	for (int i = len - 1, j = 0; i >= 0; i--, j++) {
		char c = str[i];
		if ('0' <= c && c <= '9') {
			c -= '0';
		} else if ('a' <= c && c <= 'z') {
			c -= 'a';
		} else {
			assert(0);
			return nil;
		}
		
		ret += c * 36 ^ j;
	}
	
	return [NSString stringWithFormat:@"%ld", ret];
}


@implementation PixiViewerAppDelegate

@synthesize window;
@synthesize alwaysSplitViewController;

- (UINavigationController *) navController {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return (UINavigationController *)self.alwaysSplitViewController.rootViewController;
	} else {
		return self;
	}
}

- (void) popToRootAnimated {
	[[self navController] popToRootViewControllerAnimated:YES];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.alwaysSplitViewController.detailViewController = nil;
	}
}

- (void) login:(PixivTopViewController *)vc {
	if (loginAlert) {
		return;
	}
	
	[vc setup];
	if (![vc pixiv].needsLogin) {
		return;
	}
	
	[vc pixiv].logined = NO;
	
	long err = [[vc pixiv] login:self];
	if (err) {
		UIAlertView *alert = nil;
		if (err == -1) {
			// ログイン失敗
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login faied.", nil) message:NSLocalizedString(@"Please confirm your account.", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else if (err == -2) {
			// 通信不可
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"Network is not connected.", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else if (err != 0) {
			// その他
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		}
		[alert show];
		[alert release];
		
		[self popToRootAnimated];
	} else {
		loginAlert = [[UIAlertView alloc] initWithTitle:@"ログイン中..." message:nil delegate:self cancelButtonTitle:@"キャンセル" otherButtonTitles:nil];
		[loginAlert show];
	}
}

- (void) autoLogin {
	if ([self navController].viewControllers.count > 1) {
		PixivTopViewController *vc = (PixivTopViewController *)[[self navController].viewControllers objectAtIndex:1];
		if ([vc isKindOfClass:[PixivTopViewController class]]) {
			[self login:vc];
		}
	}
}

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[loginAlert dismissWithClickedButtonIndex:0 animated:YES];
	[loginAlert release];
	loginAlert = nil;
	[window makeKeyAndVisible];
	
	if (err) {
		UIAlertView	*alert = nil;
		if (err == -1) {
			// ログイン失敗
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login faied.", nil) message:NSLocalizedString(@"Please confirm your account.", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else if (err == -2) {
			// 通信不可
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"Network is not connected.", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else if (err != 0) {
			// その他
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:[NSString stringWithFormat:@"%ld", err] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		}
		alert.tag = 100;
		[alert show];
		[alert release];
		
		[self popToRootAnimated];
	} else {		
		sender.logined = YES;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"LoginFinishedNotification" object:nil];
		
		/*
		//[[StatusMessageViewController sharedInstance] performSelector:@selector(showMessage:) withObject:@"1" afterDelay:2.6];
		
		[[StatusMessageViewController sharedInstance] performSelector:@selector(showMessage:) withObject:@"1" afterDelay:1.0];
		[[StatusMessageViewController sharedInstance] performSelector:@selector(showMessage:) withObject:@"2" afterDelay:2.0];
		[[StatusMessageViewController sharedInstance] performSelector:@selector(showMessage:) withObject:@"3" afterDelay:3.0];
		//[[StatusMessageViewController sharedInstance] performSelector:@selector(showMessage:) withObject:@"4" afterDelay:4.0];
		//[[StatusMessageViewController sharedInstance] performSelector:@selector(showMessage:) withObject:@"5" afterDelay:5.0];

		[[StatusMessageViewController sharedInstance] performSelector:@selector(showMessage:) withObject:@"6" afterDelay:10.0 + 2.6];
		[[StatusMessageViewController sharedInstance] performSelector:@selector(showMessage:) withObject:@"7" afterDelay:10.0 + 2.6 + 1];
		 */
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[loginAlert release];
	loginAlert = nil;

	if ([self navController].viewControllers.count > 1) {
		PixivTopViewController *vc = (PixivTopViewController *)[[self navController].viewControllers objectAtIndex:1];
		[[vc pixiv] loginCancel];
	
		if (![vc pixiv].logined) {
			[self popToRootAnimated];
		}
	}
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [NetworkActivityIndicator sharedInstance];
	[AccountManager encryptoAccounts];
	[SkyDrive sharedInstance];
	
	//[SFHFKeychainUtils storeUsername:@"DisableAd" andPassword:@"1" forServiceName:@"org.cathand.Illustail" updateExisting:YES error:nil];
#ifdef PIXITAIL
	[PixitailConstants sharedInstance];
    NSString *disad = DISABLE_AD ? @"1" : @"0";
#else
	NSString *disad = [SFHFKeychainUtils getPasswordForUsername:@"DisableAd" andServiceName:@"org.cathand.Illustail" error:nil];
#endif
	if ([disad isEqualToString:@"1"] && !UDBool(@"DisableAd")) {
		UDSetBool(YES, @"DisableAd");
	} else if (![disad isEqualToString:@"1"] && UDBool(@"DisableAd")) {
#ifdef PIXITAIL
		//[SFHFKeychainUtils storeUsername:@"DisableAd" andPassword:@"1" forServiceName:@"org.cathand.Pixitail" updateExisting:YES error:nil];
#else
		[SFHFKeychainUtils storeUsername:@"DisableAd" andPassword:@"1" forServiceName:@"org.cathand.Illustail" updateExisting:YES error:nil];
#endif		
	}
	
	BOOL accountIsEmpty = NO;
	if ([[AccountManager sharedInstance].accounts count] == 0 || ([[AccountManager sharedInstance].accounts count] == 1 && ((PixAccount *)[[AccountManager sharedInstance].accounts objectAtIndex:0]).anonymous && [((PixAccount *)[[AccountManager sharedInstance].accounts objectAtIndex:0]).serviceName isEqualToString:@"TINAMI"])) {
		// ない
		UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No account.", nil) message:NSLocalizedString(@"Please set account.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		[alert show];
		[alert release];
		
		accountIsEmpty = YES;
	}

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationBar.translucent = YES;
	self.toolbar.barStyle = UIBarStyleBlackTranslucent;
	//self.toolbar.translucent = YES;
	//self.navigationController.navigationBar.translucent = YES;
	//self.navigationController.toolbar.translucent = YES;
	
	NSMutableArray *ary;
	NSArray *stored = nil;

	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
	if (a_paths.count > 0 && [[NSFileManager defaultManager] fileExistsAtPath:[[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"StoredState"]]) {
		stored = [NSKeyedUnarchiver unarchiveObjectWithFile:[[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"StoredState"]];
		[[NSFileManager defaultManager] removeItemAtPath:[[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"StoredState"] error:nil];
	}
	
//NSArray *stored = [[NSUserDefaults standardUserDefaults] objectForKey:@"StoredState"];
[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"StoredState"];
[[NSUserDefaults standardUserDefaults] synchronize];
if (stored) {
	ary = [NSMutableArray array];
	for (NSDictionary *sinfo in stored) {
		UIViewController *vc = DefaultViewControllerWithStoredInfo(sinfo);
		if (vc == nil) {
			break;
		}
		
		[vc view];
		[ary addObject:vc];
	}
} else {
	
	AccountListViewController *vc = [[AccountListViewController alloc] init];
	ary = [NSMutableArray arrayWithObject:vc];
	[vc release];
	
	{
		NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastAccount"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastAccount"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		PixAccount *acc = nil;
		if (info && (acc = [PixAccount accountWithInfo:info])) {		
			UIViewController *controller = nil;
			if ([acc.serviceName isEqualToString:@"pixiv"]) {
				PixivTopViewController *tmp = [[PixivTopViewController alloc] init];
				tmp.account = acc;
				controller = tmp;
			} else if ([acc.serviceName isEqualToString:@"PiXA"]) {
				PixivTopViewController *tmp = [[PixaTopViewController alloc] init];
				tmp.account = acc;
				controller = tmp;
			} else if (([acc.serviceName isEqualToString:@"TINAMI"]) && !acc.anonymous) {
				PixivTopViewController *tmp = [[TinamiTopViewController alloc] init];
				tmp.account = acc;
				controller = tmp;
			}
		
			if (controller) {
				[ary addObject:controller];
				[controller release];
			}
		}
	}
}
	
	if ([ary count] == 0) {
		AccountListViewController *vc = [[AccountListViewController alloc] init];
		ary = [NSMutableArray arrayWithObject:vc];
		[vc release];
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.alwaysSplitViewController = [[[AlwaysSplitViewController alloc] init] autorelease];
		[self setNavigationBarHidden:YES animated:NO];
		
		//UIViewController *right = nil;
		if ([[ary lastObject] isKindOfClass:[PixivMediumViewController class]]) {
			//right = [[[ary lastObject] retain] autorelease];
			[ary removeLastObject];
		}
		
		[self performSelector:@selector(setRootViewControllerDelay:) withObject:ary afterDelay:0.1];
		/*
		UINavigationController *root = [[[UINavigationController alloc] init] autorelease];
		root.viewControllers = ary;
		root.navigationBar.barStyle = UIBarStyleBlackTranslucent;
		root.toolbar.barStyle = UIBarStyleBlackTranslucent;
		[root setNavigationBarHidden:NO animated:NO];
		self.alwaysSplitViewController.rootViewController = root;
		if (right) {
			UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:right] autorelease];
			nc.navigationBar.barStyle = UIBarStyleBlackTranslucent;
			self.alwaysSplitViewController.detailViewController = nc;
		}
		*/
		
		self.viewControllers = [NSArray arrayWithObject:self.alwaysSplitViewController];
		window.rootViewController = self;
		//[window addSubview:self.view];
	} else {
		self.viewControllers = ary;
		window.rootViewController = self;
		//[window addSubview:self.view];
	}
	
    // Add the tab bar controller's current view as a subview of the window
	[window makeKeyAndVisible];

	[PostQueue sharedInstance];
	[PostQueue evernoteQueue];
	[PostQueue dropboxQueue];
	[PostQueue sugarsyncQueue];
	[PostQueue googleDriveQueue];
	[PostQueue skyDriveQueue];
	[PostQueue pogoplugQueue];

	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		if (UDStringWithDefault(@"Passcode", nil).length == 4 && !accountIsEmpty && !lockViewController) {
			lockViewController = [[PasscodeLockViewController alloc] init];
			lockViewController.password = UDStringWithDefault(@"Passcode", nil);
			lockViewController.delegate = self;
			
			if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
				[self presentModalViewController:lockViewController animated:NO];
			} else {
				[lockViewController present];
			}
		} else {
			//if (UDBoolWithDefault(@"SaveToEvernote", NO)) {
			//	[[EvernoteTail sharedInstance] setup];
			//}

			[self autoLogin];
		}
	}
}

- (void) setRootViewControllerDelay:(NSArray *)ary {
	UINavigationController *root = [[[UINavigationController alloc] init] autorelease];
	root.viewControllers = ary;
	root.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	root.toolbar.barStyle = UIBarStyleBlackTranslucent;
	[root setNavigationBarHidden:NO animated:NO];
	self.alwaysSplitViewController.rootViewController = root;

	if (UDStringWithDefault(@"Passcode", nil).length == 4) {
		if ([[AccountManager sharedInstance].accounts count] == 0 || ([[AccountManager sharedInstance].accounts count] == 1 && ((PixAccount *)[[AccountManager sharedInstance].accounts objectAtIndex:0]).anonymous && [((PixAccount *)[[AccountManager sharedInstance].accounts objectAtIndex:0]).serviceName isEqualToString:@"TINAMI"])) {
		} else if (!lockViewController) {
			lockViewController = [[PasscodeLockViewController alloc] init];
			lockViewController.password = UDStringWithDefault(@"Passcode", nil);
			lockViewController.delegate = self;
			
			if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
				[self presentModalViewController:lockViewController animated:NO];
			} else {
				[lockViewController present];
			}
		}
	} else {
		//if (UDBoolWithDefault(@"SaveToEvernote", NO)) {
		//	[[EvernoteTail sharedInstance] setup];
		//}
	
		[self autoLogin];
	}
}

- (void) passcodeLockViewControllerFinished:(PasscodeLockViewController *)sender {
	if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
		[sender dismissModalViewControllerAnimated:NO];
	} else {
		[sender dismiss];
	}
	[lockViewController release];
	lockViewController = nil;
	
	//if (UDBoolWithDefault(@"SaveToEvernote", NO)) {
	//	[[EvernoteTail sharedInstance] setup];
	//}

	[self autoLogin];
}

- (void) setDetailViewControllerDelay:(UIViewController *)vc {
	UINavigationController *nc = [[[UINavigationController alloc] init] autorelease];
	nc.viewControllers = [NSArray arrayWithObject:vc];
	//nc.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//nc.toolbar.barStyle = UIBarStyleBlackTranslucent;
	[nc setNavigationBarHidden:NO animated:NO];
	self.alwaysSplitViewController.detailViewController = nc;
}

- (void)dealloc {
	self.alwaysSplitViewController.rootViewController = nil;
	self.alwaysSplitViewController = nil;
    [window release];
    [super dealloc];
}

/*
	pixitail://org.cathand.pixitail/pixiv/illustID
	illustail://org.cathand.illustail/pixiv/illustID
*/
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

#ifdef PIXITAIL
    if ([[url scheme] caseInsensitiveCompare:@"pixitail"] == NSOrderedSame) {
#else
    if ([[url scheme] caseInsensitiveCompare:@"illustail"] == NSOrderedSame) {
#endif
		NSString *sericeName = nil;
		NSString *iid = nil;
		if (url) {
			NSString *path = [url path];
			iid = [path lastPathComponent];		
			sericeName = [[path stringByDeletingLastPathComponent] lastPathComponent];
		}
		
		NSString *method = nil;
		NSMutableDictionary *param = [NSMutableDictionary dictionary];
		if ([iid hasPrefix:@"compose"]) {
			method = @"compose";
			NSArray *ary = [[url absoluteString] componentsSeparatedByString:@"?"];
			if (ary.count == 2) {
				NSArray *params = [[ary lastObject] componentsSeparatedByString:@"&"];
				for (NSString *s in params) {
					NSArray *a = [s componentsSeparatedByString:@"="];
					if (a.count == 2) {
						NSString *key = [a objectAtIndex:0];
						NSString *val = [a objectAtIndex:1];
						[param setObject:val forKey:key];
					}
				}
			}
		}
		
		if ([sericeName isEqualToString:@"settings"]) {
			if ([iid isEqualToString:@"widget"]) {
				SettingViewController *vc = [[[SettingViewController alloc] init] autorelease];
				WidgetSettingViewController *wvc = [[[WidgetSettingViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
				UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
				[nc pushViewController:wvc animated:NO];
				
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					nc.modalPresentationStyle = UIModalPresentationFormSheet;
					UINavigationController *app = (UINavigationController *)[UIApplication sharedApplication].delegate;
					[app presentModalViewController:nc animated:NO];
				} else {
					[self presentModalViewController:nc animated:NO];
				}
			}
		}
		
#ifdef PIXITAIL
		PixAccount *acc = [[AccountManager sharedInstance] defaultAccount:@"pixiv"];
		if ([sericeName caseInsensitiveCompare:@"pixiv"] == NSOrderedSame && iid && acc) {
			//if (![[Pixiv sharedInstance].username isEqual:acc.username] || ![[Pixiv sharedInstance].password isEqual:acc.password]) {
			//	[Pixiv sharedInstance].username = acc.username;
			//	[Pixiv sharedInstance].password = acc.password;
			//	[Pixiv sharedInstance].logined = NO;
			//}	

			NSMutableArray *ary = [NSMutableArray arrayWithObject:[self.viewControllers objectAtIndex:0]];
			
			PixivTopViewController *top = [[[PixivTopViewController alloc] init] autorelease];
			top.account = acc;
			[ary addObject:top];
			
			PixivMediumViewController *controller = nil;
			if (!method) {
				controller = [[[PixivMediumViewController alloc] init] autorelease];
				controller.account = acc;
				controller.illustID = iid;
				[ary addObject:controller];
			}
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				[self performSelector:@selector(setRootViewControllerDelay:) withObject:[NSArray arrayWithObjects:[[[AccountListViewController alloc] init] autorelease], top, nil] afterDelay:0.1];
				if (controller) {
					[self performSelector:@selector(setDetailViewControllerDelay:) withObject:controller afterDelay:0.1];
				}
			} else {
				self.viewControllers = ary;
			}
						
			if (UDStringWithDefault(@"Passcode", nil).length != 4) {
				[self performSelector:@selector(autoLogin) withObject:nil afterDelay:0.0];
			}
			return YES;
		}
#else
		if ([sericeName caseInsensitiveCompare:@"pixa"] == NSOrderedSame && iid) {
			PixAccount *acc = [[AccountManager sharedInstance] defaultAccount:@"PiXA"];
			if (acc) {
				//if (![[Pixa sharedInstance].username isEqual:acc.username] || ![[Pixa sharedInstance].password isEqual:acc.password]) {
				//	[Pixa sharedInstance].username = acc.username;
				//	[Pixa sharedInstance].password = acc.password;
				//	[Pixa sharedInstance].logined = NO;
				//}	
	
				NSMutableArray *ary = [NSMutableArray arrayWithObject:[self.viewControllers objectAtIndex:0]];
				
				PixivTopViewController *top = [[[PixaTopViewController alloc] init] autorelease];
				top.account = acc;
				[ary addObject:top];

				PixaMediumViewController *controller = [[[PixaMediumViewController alloc] init] autorelease];
				controller.illustID = iid;
				controller.account = acc;
				[ary addObject:controller];
			
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					[self performSelector:@selector(setRootViewControllerDelay:) withObject:[NSArray arrayWithObjects:[[[AccountListViewController alloc] init] autorelease], top, nil] afterDelay:0.1];
					[self performSelector:@selector(setDetailViewControllerDelay:) withObject:controller afterDelay:0.1];
				} else {
					self.viewControllers = ary;
				}

				if (UDStringWithDefault(@"Passcode", nil).length != 4) {
					[self performSelector:@selector(autoLogin) withObject:nil afterDelay:0.0];
				}
				return YES;
			}
		} else if ([sericeName caseInsensitiveCompare:@"tinami"] == NSOrderedSame && iid) {
			PixAccount *acc = [[AccountManager sharedInstance] defaultAccount:@"TINAMI"];
			//if (acc) {// && (![[Tinami sharedInstance].username isEqual:acc.username] || ![[Tinami sharedInstance].password isEqual:acc.password])) {
			//	[Tinami sharedInstance].username = acc.username;
			//	[Tinami sharedInstance].password = acc.password;
			//	[Tinami sharedInstance].logined = NO;
			//} else {
			//	[Tinami sharedInstance].username = @"";
			//	[Tinami sharedInstance].password = @"";
			//	[Tinami sharedInstance].logined = NO;
			//}

			NSMutableArray *ary = [NSMutableArray arrayWithObject:[self.viewControllers objectAtIndex:0]];

			PixivTopViewController *top = [[[TinamiTopViewController alloc] init] autorelease];
			top.account = acc;
			[ary addObject:top];

			TinamiMediumViewController *controller = [[[TinamiMediumViewController alloc] init] autorelease];
			controller.illustID = iid;
			controller.account = acc;
			[ary addObject:controller];
	
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				[self performSelector:@selector(setRootViewControllerDelay:) withObject:[NSArray arrayWithObjects:[[[AccountListViewController alloc] init] autorelease], top, nil] afterDelay:0.1];
				[self performSelector:@selector(setDetailViewControllerDelay:) withObject:controller afterDelay:0.1];
			} else {
				self.viewControllers = ary;
			}
			
			if (UDStringWithDefault(@"Passcode", nil).length != 4) {
				[self performSelector:@selector(autoLogin) withObject:nil afterDelay:0.0];
			}
			return YES;
		} else if ([sericeName caseInsensitiveCompare:@"seiga"] == NSOrderedSame && iid) {
			PixAccount *acc = [[AccountManager sharedInstance] defaultAccount:@"Seiga"];
			
			NSMutableArray *ary = [NSMutableArray arrayWithObject:[self.viewControllers objectAtIndex:0]];
			
			SeigaTopViewController *top = [[[SeigaTopViewController alloc] init] autorelease];
			top.account = acc;
			[ary addObject:top];
			
			SeigaMediumViewController *controller = [[[SeigaMediumViewController alloc] init] autorelease];
			controller.illustID = iid;
			controller.account = acc;
			[ary addObject:controller];
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				[self performSelector:@selector(setRootViewControllerDelay:) withObject:[NSArray arrayWithObjects:[[[AccountListViewController alloc] init] autorelease], top, nil] afterDelay:0.1];
				[self performSelector:@selector(setDetailViewControllerDelay:) withObject:controller afterDelay:0.1];
			} else {
				self.viewControllers = ary;
			}
			
			if (UDStringWithDefault(@"Passcode", nil).length != 4) {
				[self performSelector:@selector(autoLogin) withObject:nil afterDelay:0.0];
			}
			return YES;
		} else if ([sericeName caseInsensitiveCompare:@"danbooru"] == NSOrderedSame && iid) {
			NSUserDefaults *defaults = [[[NSUserDefaults alloc] initWithSuiteName:@"group.org.cathand.illustail"] autorelease];
			[defaults synchronize];
			NSDictionary *info = [defaults objectForKey:@"danbooru_selected_post"];
			if (info) {
				[defaults removeObjectForKey:@"danbooru_selected_post"];
				[defaults synchronize];
				
				NSString *host = [NSURL URLWithString:[info objectForKey:@"method"]].host;
				PixAccount *acc = nil;
				for (acc in [[AccountManager sharedInstance] accountsForServiceName:@"Danbooru"]) {
					if ([acc.hostname isEqualToString:host]) {
						break;
					}
				}
				if (acc) {
					NSMutableArray *ary = [NSMutableArray arrayWithObject:[self.viewControllers objectAtIndex:0]];
					
					DanbooruTopViewController *top = [[[DanbooruTopViewController alloc] init] autorelease];
					top.account = acc;
					[ary addObject:top];
					
					DanbooruMediumViewController *controller = [[[DanbooruMediumViewController alloc] init] autorelease];
					controller.illustID = iid;
					controller.account = acc;
					controller.info = info;
					[ary addObject:controller];
					
					if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
						[self performSelector:@selector(setRootViewControllerDelay:) withObject:[NSArray arrayWithObjects:[[[AccountListViewController alloc] init] autorelease], top, nil] afterDelay:0.1];
						[self performSelector:@selector(setDetailViewControllerDelay:) withObject:controller afterDelay:0.1];
					} else {
						self.viewControllers = ary;
					}
					
					if (UDStringWithDefault(@"Passcode", nil).length != 4) {
						[self performSelector:@selector(autoLogin) withObject:nil afterDelay:0.0];
					}
					return YES;
					
				}
			}
		}
#endif
	}

	return NO;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	DLog(@"applicationDidReceiveMemoryWarning");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	DLog(@"applicationDidEnterBackground");
	
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	DLog(@"applicationWillEnterForeground");
	//if (UDStringWithDefault(@"Passcode", nil).length != 4) {
	//	[self autoLogin];
	//}
}

- (void)applicationWillResignActive:(UIApplication *)application {
	DLog(@"applicationWillResignActive");
	if (UDStringWithDefault(@"Passcode", nil).length == 4 && !lockViewController) {
		lockViewController = [[PasscodeLockViewController alloc] init];
		lockViewController.password = UDStringWithDefault(@"Passcode", nil);
		lockViewController.delegate = self;
		
		if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
			[self presentModalViewController:lockViewController animated:NO];
		} else {
			[lockViewController present];
		}
	}
}
	
- (void) applicationDidBecomeActive:(UIApplication *)application {
	DLog(@"applicationDidBecomeActive");
	if (UDStringWithDefault(@"Passcode", nil).length != 4) {
		//[self autoLogin];
		[self performSelector:@selector(autoLogin) withObject:nil afterDelay:0.0];
	}
}

- (void)applicationWillTerminate:(UIApplication *)application {
	DLog(@"applicationWillTerminate");

	[PostQueue clean];
	[PostQueue cleanEvernote];
	[PostQueue cleanDropbox];
	[PostQueue cleanSugarSync];
	[PostQueue cleanGoogleDrive];
	[PostQueue cleanSkyDrive];
	[PostQueue cleanPogoplug];
	
	NSMutableArray *ary = [NSMutableArray array];
	NSArray *vcs;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		vcs = ((UINavigationController *)self.alwaysSplitViewController.rootViewController).viewControllers;
	} else {
		vcs = self.viewControllers;
	}
	for (UIViewController *vc in vcs) {
		if (![vc isKindOfDefaultViewController]) {
			break;
		}
		
		id<DefaultViewControllerProtocol> dvc = (id<DefaultViewControllerProtocol>)vc;
		if (![dvc needsStore]) {
			break;
		}
		[ary addObject:[dvc storeInfo]];
	}
	
	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
	if (a_paths.count > 0) {
		[NSKeyedArchiver archiveRootObject:ary toFile:[[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"StoredState"]];
	}
	
	//[[NSUserDefaults standardUserDefaults] setObject:ary forKey:@"StoredState"];
	//[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
}

@end

