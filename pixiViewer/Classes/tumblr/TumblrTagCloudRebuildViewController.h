//
//  TumblrTagCloudRebuildViewController.h
//  pixiViewer
//
//  Created by nya on 10/05/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MatrixParser.h"
#import "CHHtmlParserConnection.h"
#import "DefaultViewController.h"


@class TumblrParser;
@class CHHtmlParserConnection;
@class PixAccount;


@interface TumblrTagCloudRebuildViewController : DefaultViewController<MatrixParserDelegate, CHHtmlParserConnectionDelegate> {
	UIButton *button;
	UIProgressView *progressView;
	UILabel *progressLabel;

	PixAccount *account;
	NSString *name;

	TumblrParser *parser;
	CHHtmlParserConnection *connection;
	int index;
}

@property(readwrite, nonatomic, retain) IBOutlet UIButton *button;
@property(readwrite, nonatomic, retain) IBOutlet UIProgressView *progressView;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *progressLabel;

@property(readwrite, nonatomic, retain) PixAccount *account;
@property(readwrite, nonatomic, retain) NSString *name;

- (IBAction) rebuild;

@end
