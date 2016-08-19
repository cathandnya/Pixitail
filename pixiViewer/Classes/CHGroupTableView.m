//
//  CHGroupTableView.m
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHGroupTableView.h"


UITextField *InputFieldForCell(UITableViewCell *cell) {
	CGRect	frame = cell.contentView.bounds;
	CGSize	labelSize = [cell.textLabel.text sizeWithFont:cell.textLabel.font];
	CGFloat	fieldHeight = [@"abcdefghijklnmopqrstuvxyzABCDEFGHIJKLNMOPQRSTUVWXYZ" sizeWithFont:cell.textLabel.font].height;
	frame.origin.x += labelSize.width + 20;
	frame.size.width -= labelSize.width + 35;
	frame.origin.y += (frame.size.height - fieldHeight) / 2.0;

	return [[[UITextField alloc] initWithFrame:frame] autorelease];
}

UISwitch *SwitchForCell(UITableViewCell *cell) {
	UISwitch *sw = [[UISwitch alloc] init];
	CGRect	frame = cell.contentView.bounds;
	frame.size = sw.frame.size;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		frame.origin.x = 400 - sw.frame.size.width - 20;
	} else {
		frame.origin.x = 320 - sw.frame.size.width - 20;
	}
	frame.origin.y += (cell.contentView.bounds.size.height - sw.frame.size.height) / 2.0;
	sw.frame = frame;
	return [sw autorelease];
}


@implementation CHGroupTableView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	BOOL	outside = YES;
	
	NSEnumerator *enu = [[event allTouches] objectEnumerator];
	UITouch *touch;
	while (touch = [enu nextObject]) {
		CGPoint loc = [touch locationInView:self];
		int	section;
		int row;
		
		for (section = 0; section < [self.dataSource numberOfSectionsInTableView:self]; section++) {
			NSInteger max = [self.dataSource tableView:self numberOfRowsInSection:section];
			
			for (row = 0; row < max; row++) {
				CGRect rect = [self rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
				if (CGRectContainsPoint(rect, loc)) {
					// 中
					outside = NO;
					break;
				}
			}
		}
	}
	
	if (outside) {
		[(id)self.delegate touchesBegan:touches withEvent:event];
	} else {
		[super touchesBegan:touches withEvent:event];
	}
}

@end
