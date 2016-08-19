//
//  MediumViewCell.h
//  pixiViewer
//
//  Created by nya on 10/05/31.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"


@class CHURLImageView;
@interface MediumViewImageCell : UITableViewCell {
	CHURLImageView *mediumImageView;
	UIProgressView *progressView;
	UIActivityIndicatorView *activityView;
}

+ (MediumViewImageCell *) cell;

@property(readwrite, nonatomic, retain) IBOutlet CHURLImageView *mediumImageView;
@property(readwrite, nonatomic, retain) IBOutlet UIProgressView *progressView;
@property(readwrite, nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;

@end


@interface MediumViewLabelCell : UITableViewCell<TTTAttributedLabelDelegate> {
	UILabel *labelLabel;
	TTTAttributedLabel *descLabel;
}

+ (MediumViewLabelCell *) cell;
+ (CGFloat) heightForDesc:(NSString *)desc viewWidth:(CGFloat)width;

@property(readwrite, nonatomic, retain) IBOutlet UILabel *labelLabel;
@property(readwrite, nonatomic, retain) IBOutlet TTTAttributedLabel *descLabel;

@end


@interface MediumViewCommentCell : UITableViewCell {
	UILabel *nameLabel;
	UILabel *dateLabel;
	UILabel *commentLabel;
}

+ (MediumViewCommentCell *) cell;
+ (CGFloat) heightForDesc:(NSString *)desc viewWidth:(CGFloat)width;

@property(readwrite, nonatomic, retain) IBOutlet UILabel *nameLabel;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *dateLabel;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *commentLabel;

@end
