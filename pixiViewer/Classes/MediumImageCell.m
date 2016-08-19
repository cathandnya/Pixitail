//
//  MediumViewImageCell.m
//  pixiViewer
//
//  Created by nya on 11/08/05.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MediumImageCell.h"
#import "ImageLoaderManager.h"


@implementation MediumImageCell

@synthesize mediumImageView, progressView, activityView;

+ (MediumImageCell *) cell:(UITableView *)tableView {
    static NSString *CellIdentifier = @"MediumImageCell";
    MediumImageCell *cell = (MediumImageCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		UIViewController *vc = [[[UIViewController alloc] initWithNibName:CellIdentifier bundle:nil] autorelease];
		cell = (MediumImageCell *)vc.view;
		cell.backgroundColor = [UIColor clearColor];
	}
	return cell;
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

- (void) setImageWithID:(NSString *)ID loader:(ImageLoaderManager *)mgr {
	UIImage *img = [mgr imageForID:ID];
	if (!img) {
		img = [mgr imageForID:ID];
	}
	self.mediumImageView.image = img;
}

@end
