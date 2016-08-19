    //
//  DefaultViewController.m
//  pixiViewer
//
//  Created by nya on 10/05/12.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"
#import "ProgressViewController.h"


#define PROGRESS_VIEW_TAG 384256


static BOOL defaultLotation(UIInterfaceOrientation interfaceOrientation) {
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		return YES;
	} else {
		return interfaceOrientation ==  UIInterfaceOrientationPortrait;
	}
}

void setStatusbarHidden(BOOL hidden, BOOL animated) {
	[[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
}

void setBackButton(UIViewController *vc) {
    UIBarButtonItem *back = [[[UIBarButtonItem alloc] init] autorelease];
    back.title = @"";
    vc.navigationItem.backBarButtonItem = back;
}


@implementation NSObject(DefaultViewControllerAddition)

- (BOOL) isKindOfDefaultViewController {
	return [self respondsToSelector:@selector(storeInfo)] && [self respondsToSelector:@selector(needsStore)] && [self respondsToSelector:@selector(restore:)];
}

@end


@interface ProgressTableView : UITableView {
}
@end


@implementation DefaultViewController

- (id) init {
    self = [super init];
    setBackButton(self);
    return self;
}

- (id) initWithNibName:(NSString *)name bundle:(NSBundle *)bundle {
    self = [super initWithNibName:name bundle:bundle];
    setBackButton(self);
    return self;
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
    UIBarButtonItem *back = [[[UIBarButtonItem alloc] init] autorelease];
    back.title = @"";
    self.navigationItem.backBarButtonItem = back;

	if (storedTitle) {
		self.title = storedTitle;
	} else {
		storedTitle = [self.navigationItem.title retain];
	}
}

- (void) dealloc {
	[storedTitle release];

	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return defaultLotation(interfaceOrientation);
}

- (NSMutableDictionary *) storeInfo {
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		NSStringFromClass([self class]),		@"Class",
		storedTitle,							@"NavigationTitle",
		nil];
}

- (BOOL) needsStore {
	return NO;
}

- (BOOL) restore:(NSDictionary *)info {
	storedTitle = [[info objectForKey:@"NavigationTitle"] retain];
	return YES;
}

- (void) hideProgress {
	DLog(@"hideProgress");

	if ([self.view isKindOfClass:[UIScrollView class]]) {
		((UIScrollView *)self.view).scrollEnabled = YES;
	}

	[progressViewController_.view removeFromSuperview];
	[progressViewController_ release];
	progressViewController_ = nil;
	
	progressShowing_ = NO;

	[self.navigationItem setHidesBackButton:NO animated:YES];
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void) showProgress:(BOOL)activity withTitle:(NSString *)str tag:(int)tag {
	DLog(@"showProgress");

	[self hideProgress];
	progressShowing_ = YES;

	progressViewController_ = [[ProgressViewController alloc] initWithNibName:@"ProgressViewController" bundle:nil];
	[progressViewController_ setDoubleValue:0.0];
	[progressViewController_ setCancelAction:@selector(progressCancel:) toTarget:self];
	progressViewController_.text = str;
	progressViewController_.showActivity = activity;
	progressViewController_.tag = tag;

	progressViewController_.view.backgroundColor = [UIColor clearColor];
				
	CGRect	frame = self.view.frame;
	frame.origin = CGPointZero;
	if ([self.view isKindOfClass:[UIScrollView class]]) {
		frame.size = ((UIScrollView *)self.view).contentSize;
	} else {
		frame.size = self.view.frame.size;
	}
	[progressViewController_.view setFrame:frame];
	[self.view addSubview:progressViewController_.view];
	
	if ([self.view isKindOfClass:[UIScrollView class]]) {
		[(UIScrollView *)self.view scrollRectToVisible:CGRectMake(0, 0, 10, 10) animated:YES];
		((UIScrollView *)self.view).scrollEnabled = NO;
	}
	
	[self.navigationItem setHidesBackButton:YES animated:YES];
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated {
	setStatusbarHidden(hidden, animated);
}

@end


@implementation DefaultTableViewController

- (id) init {
    self = [super init];
    setBackButton(self);
    return self;
}

- (id) initWithNibName:(NSString *)name bundle:(NSBundle *)bundle {
    self = [super initWithNibName:name bundle:bundle];
    setBackButton(self);
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ProgressTableView *view = [[ProgressTableView alloc] initWithFrame:self.tableView.frame style:self.tableView.style];
    view.dataSource = self;
    view.delegate = self;
    self.tableView = view;
    [view release];

	if (storedTitle) {
		self.title = storedTitle;
	} else {
		storedTitle = [self.navigationItem.title retain];
	}
}

- (void) viewDidUnload {
	self.tableView = nil;
	[super viewDidUnload];
}

- (void) dealloc {
	self.tableView = nil;
	[storedTitle release];
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return defaultLotation(interfaceOrientation);
}

- (BOOL) needsStore {
	return NO;
}

- (NSMutableDictionary *) storeInfo {
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		NSStringFromClass([self class]),		@"Class",
		storedTitle,							@"NavigationTitle",
		nil];
}

- (BOOL) restore:(NSDictionary *)info {
	storedTitle = [[info objectForKey:@"NavigationTitle"] retain];
	return YES;
}

- (void) hideProgress {
	DLog(@"hideProgress");

	self.tableView.scrollEnabled = YES;

	[progressViewController_.view removeFromSuperview];
	[progressViewController_ release];
	progressViewController_ = nil;
	
	progressShowing_ = NO;

	[self.navigationItem setHidesBackButton:NO animated:NO];
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void) showProgress:(BOOL)activity withTitle:(NSString *)str tag:(int)tag {
	DLog(@"showProgress");

	[self hideProgress];
	progressShowing_ = YES;

	progressViewController_ = [[ProgressViewController alloc] initWithNibName:@"ProgressViewController" bundle:nil];
	[progressViewController_ setDoubleValue:0.0];
	[progressViewController_ setCancelAction:@selector(progressCancel:) toTarget:self];
	progressViewController_.text = str;
	progressViewController_.showActivity = activity;
	progressViewController_.tag = tag;
	
	progressViewController_.view.backgroundColor = [UIColor clearColor];
				
	CGRect	frame = self.tableView.frame;
	frame.origin = CGPointZero;
	frame.size = ((UIScrollView *)self.view).contentSize;
	if (CGSizeEqualToSize(frame.size, CGSizeZero)) {
		frame.size = ((UIScrollView *)self.view).frame.size;
	}
	progressViewController_.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[progressViewController_.view setFrame:frame];
	[self.tableView addSubview:progressViewController_.view];
	
	[self.tableView scrollRectToVisible:CGRectMake(0, 0, 10, 10) animated:YES];
	self.tableView.scrollEnabled = NO;

	[self.navigationItem setHidesBackButton:YES animated:NO];
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated {
	setStatusbarHidden(hidden, animated);
}

@end


@implementation ProgressTableView

- (void) layoutSubviews {
    [super layoutSubviews];
    
	if ([self viewWithTag:PROGRESS_VIEW_TAG]) {
        [self bringSubviewToFront:[self viewWithTag:PROGRESS_VIEW_TAG]];
    }
}

@end


id DefaultViewControllerWithStoredInfo(NSDictionary *info) {
	NSString *className = [info objectForKey:@"Class"];

	Class cls = NSClassFromString(className);
	if (cls == nil) {
		return nil;
	}
	
	id<DefaultViewControllerProtocol> obj;
	
	Class c = cls;
	NSString *nibName = className;
	while ([[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"] == nil) {
		//DLog(@"path: %@", [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:nibName] stringByAppendingPathExtension:@"nib"]);
		c = [c superclass];
		if (c == [NSObject class]) {
			nibName = nil;
			break;
		}
		nibName = NSStringFromClass(c);
	}
	
	if ([className isEqual:@"TinamiSearchViewController"]) {
		nibName = @"TinamiSearchController";
	} else if ([className hasSuffix:@"DanbooruSearchViewController"]) {
		nibName = @"DanbooruSearchController";
	} else if ([className hasSuffix:@"SearchViewController"] && ![className hasSuffix:@"UserSearchViewController"]) {
		nibName = @"PixivSearchController";
	}
	
	if ([nibName isEqual:@"PixivMatrixViewController"]) {
		nibName = nil;
	} else if ([nibName isEqual:@"PixivMediumViewController"]) {
		nibName = nil;
	}
	
	if (nibName) {
		obj = [[[cls alloc] initWithNibName:nibName bundle:nil] autorelease];
	} else {
		obj = [[[cls alloc] init] autorelease];
	}
	if (obj == nil) {
		return nil;
	}
	
	if ([obj restore:info] == NO) {
		return nil;
	}
	return obj;
}

