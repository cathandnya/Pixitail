//
//  PixivMediumViewController.h
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"
#import "MediumParser.h"
#import "CHHtmlParserConnection.h"
#import "CHURLImageView.h"
#import "PixService.h"
#import "PixivTagAddViewController.h"
#import "PixivRatingViewController.h"
#import "Tumblr.h"


@class ProgressViewController;
@class PixivMatrixViewController;
@class PixAccount;
@class MediumImageCell;


@interface PixivMediumViewController : DefaultViewController<CHHtmlParserConnectionDelegate, UIActionSheetDelegate, PixServiceAddBookmarkHandler, PixivTagAddViewControllerDelegate, PixServiceCommentHandler, PixivRatingViewDelegate, PixServiceRatingHandler, PixServiceLoginHandler, UITableViewDelegate, UITableViewDataSource> {
	
	id						parser_;
	CHHtmlParserConnection	*connection_;
	
	NSString		*illustID;
	NSDictionary	*info_;
	
	NSInteger		addButtonIndex_;
	
	PixAccount *account;
	
	UIImage *whiteIndicator;
	UIActionSheet *actionSheet_;
	
	UITableView *tableView_;
	UIScrollView *scrollView_;
	
	NSArray *tableRows;
	MediumImageCell *imageCell;
}

@property(readwrite, retain, nonatomic) NSString *illustID;
@property(retain, nonatomic, readwrite) PixAccount *account;
@property(retain, nonatomic, readwrite) NSDictionary *info;

@property(retain, nonatomic, readwrite) UITableView *tableView;
@property(retain, nonatomic, readwrite) UIScrollView *scrollView;

- (IBAction) goToWeb;
- (IBAction) twitter;
- (void) report;

- (UIBarButtonItem *) ratingButton;
- (void) update:(NSDictionary *)info;
- (void) updateInfo:(NSDictionary *)info;
- (long) reload;
- (void) hideProgress;
- (void) showProgress:(BOOL)activity withTitle:(NSString *)str tag:(int)tag;

- (void) updateSegment;
- (void) updateToolbar;
- (PixivMatrixViewController *) parentMatrix;
- (NSString *) nextIID;
- (NSString *) prevIID;

- (NSString *)url;
- (NSString *) serviceName;

- (PixivMatrixViewController *) parentMatrix;

- (void) prev;
- (void) next;

- (NSDictionary *) infoForIllustID:(NSString *)iid;
- (NSString *) parserClassName;
- (NSString *) sourceURL;
- (NSString *) tumblrServiceName;

@end


NSString *shorten(NSString *url);
