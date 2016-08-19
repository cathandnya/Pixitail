//
//  SwitchCell.h
//  pixiViewer
//
//  Created by nya on 10/05/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SwitchCell : UITableViewCell {
	UISwitch *sw;
}

@property(readwrite, nonatomic, assign) UISwitch *sw;

@end
