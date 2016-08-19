//
//  EditableCell.m
//  pixiViewer
//
//  Created by nya on 10/05/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EditableCell.h"


@implementation EditableCell

@synthesize field;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;

		field = [[UITextField alloc] init];
		field.textColor = [UIColor blackColor];
		[self.contentView addSubview:field];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)dealloc {
	[field release];

    [super dealloc];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect	contentFrame = self.contentView.frame;
	CGSize	labelSize = [self.textLabel.text sizeWithFont:self.textLabel.font constrainedToSize:CGSizeMake(FLT_MAX, FLT_MAX)];
	CGFloat	fieldHeight = [@"abcdefghijklnmopqrstuvxyzABCDEFGHIJKLNMOPQRSTUVWXYZ" sizeWithFont:field.font].height;
	CGRect r;
	r.origin.x = self.textLabel.frame.origin.x + labelSize.width + 10;
	r.origin.y = (contentFrame.size.height - fieldHeight) / 2.0;
	r.size.width = contentFrame.size.width - r.origin.x;
	r.size.height = fieldHeight;
	field.frame = r;
	[field removeFromSuperview];
	[self.contentView addSubview:field];
}

@end
