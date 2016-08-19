//
//  fgMediumViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 12/01/04.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import "fgMediumViewController.h"
#import "ScrapingService.h"


@implementation fgMediumViewController

- (void) rating:(id)sender {
	[self performSelector:@selector(ratingDelay) withObject:nil afterDelay:0.0];
}

- (void) ratingDelay {
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"★", @"★★", @"★★★", @"★★★★", @"★★★★★", nil] autorelease];
	sheet.tag = 10000;
	[sheet showFromToolbar:self.navigationController.toolbar];
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (sheet.tag == 10000) {
		actionSheet_ = nil;
		if (buttonIndex != sheet.cancelButtonIndex) {
			[self.service rating:buttonIndex + 1 withInfo:info_];
		}
	} else {
		[super actionSheet:sheet clickedButtonAtIndex:buttonIndex];
	}
}

@end
