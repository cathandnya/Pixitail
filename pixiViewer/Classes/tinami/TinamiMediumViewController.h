//
//  TinamiMediumViewController.h
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivMediumViewController.h"


@class TinamiCommentParser;
@class CHHtmlParserConnection;

@interface TinamiMediumViewController : PixivMediumViewController<UIAlertViewDelegate> {
	NSString *method;

	TinamiCommentParser		*commentParser_;
	CHHtmlParserConnection	*commentConnection_;
	
	BOOL needsReloadAfterAdd;
	BOOL alertShowing;
}

@property(readwrite, nonatomic, retain) NSString *method;

@end
