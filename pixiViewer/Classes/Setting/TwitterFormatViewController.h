//
//  TwitterFormatViewController.h
//  pixiViewer
//
//  Created by nya on 10/04/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"


@interface TwitterFormatViewController : DefaultViewController {
	UITextView *textView;
	UILabel *authorLabelLabel;
	UILabel *authorDescLabel;
	UILabel *titleLabelLabel;
	UILabel *titleDescLabel;
}

@property(readwrite, nonatomic, retain) IBOutlet UITextView *textView;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *authorLabelLabel;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *authorDescLabel;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *titleLabelLabel;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *titleDescLabel;

@end


@interface TumblrFormatViewController : TwitterFormatViewController

@end
