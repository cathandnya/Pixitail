//
//  SwitchCell.m
//  pixiViewer
//
//  Created by nya on 10/05/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SwitchCell.h"


@implementation SwitchCell

@synthesize sw;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		sw = [[UISwitch alloc] init];
		self.accessoryView = sw;
		//[self.contentView addSubview:sw];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)dealloc {
	[sw release];
    [super dealloc];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect	contentFrame = self.contentView.frame;
	CGRect r = sw.frame;
	r.origin.x = contentFrame.size.width - r.size.width - 20;
	r.origin.y = (contentFrame.size.height - r.size.height) / 2.0;
	sw.frame = r;
	[sw removeFromSuperview];
	[self.contentView addSubview:sw];
}

@end
