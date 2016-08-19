//
//  MediumViewCell.m
//  pixiViewer
//
//  Created by nya on 10/05/31.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MediumViewCell.h"


@implementation MediumViewImageCell

@synthesize mediumImageView, progressView, activityView;

+ (MediumViewImageCell *) cell {
	UIViewController *vc = [[[UIViewController alloc] initWithNibName:@"MediumViewImageCell" bundle:nil] autorelease];
	return (MediumViewImageCell *)vc.view;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}

- (void)dealloc {
	self.mediumImageView = nil;
	self.progressView = nil;
	self.activityView = nil;
    [super dealloc];
}

@end


#pragma mark-


@implementation MediumViewLabelCell

@synthesize labelLabel, descLabel;

+ (MediumViewLabelCell *) cell {
	UIViewController *vc = [[[UIViewController alloc] initWithNibName:@"MediumViewLabelCell" bundle:nil] autorelease];
	return (MediumViewLabelCell *)vc.view;
}

+ (CGFloat) heightForDesc:(NSString *)desc viewWidth:(CGFloat)width {
	width -= 25;
	CGSize size = [desc sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(width, FLT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
	return size.height + 31 + 5;
}

- (void) awakeFromNib {
    [super awakeFromNib];
    descLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    descLabel.delegate = self;
    descLabel.linkAttributes = @{NSForegroundColorAttributeName : [UIColor cyanColor]};
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}

- (void)dealloc {
	self.labelLabel = nil;
	self.descLabel = nil;
    [super dealloc];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}

@end


#pragma mark-


@implementation MediumViewCommentCell

@synthesize nameLabel, dateLabel, commentLabel;

+ (MediumViewCommentCell *) cell {
	UIViewController *vc = [[[UIViewController alloc] initWithNibName:@"MediumViewCommentCell" bundle:nil] autorelease];
	return (MediumViewCommentCell *)vc.view;
}

+ (CGFloat) heightForDesc:(NSString *)desc viewWidth:(CGFloat)width {
	width -= 25;
	CGSize size = [desc sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(width, FLT_MAX) lineBreakMode:UILineBreakModeCharacterWrap];
	return size.height + 26 + 5 + 5;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}

- (void)dealloc {
	self.nameLabel = nil;
	self.dateLabel = nil;
	self.commentLabel = nil;
    [super dealloc];
}

@end
