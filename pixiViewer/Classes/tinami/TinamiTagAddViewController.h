//
//  TinamiTagAddViewController.h
//  pixiViewer
//
//  Created by nya on 10/02/28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivTagAddViewController.h"


@interface TinamiTagAddViewController : PixivTagAddViewController {
	UISegmentedControl *typeSegment;
}

@property(readwrite, nonatomic, retain) IBOutlet UISegmentedControl *typeSegment;

@end
