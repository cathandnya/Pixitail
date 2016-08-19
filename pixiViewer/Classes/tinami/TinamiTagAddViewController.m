//
//  TinamiTagAddViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiTagAddViewController.h"


@implementation TinamiTagAddViewController

@synthesize typeSegment;

- (void) dealloc {
	[typeSegment release];
	[super dealloc];
}

- (NSString *) typeAtIndex:(NSInteger)i {
	switch (i) {
	case 0:
		return @"1";
	case 1:
		return @"2";
	case 2:
		return @"3";
	case 3:
		return @"5";
	case 4:
		return @"4";
	default:
		assert(0);
		return nil;
	}
}

- (IBAction) done {
	[delegate tagAddView:self done:[NSDictionary dictionaryWithObjectsAndKeys:
		textView_.text,		@"Tag",
		[self typeAtIndex:typeSegment.selectedSegmentIndex],	@"Type",
		nil]];
}

@end
