//
//  EditableCell.h
//  pixiViewer
//
//  Created by nya on 10/05/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EditableCell : UITableViewCell {
	UITextField *field;
}

@property(readwrite, nonatomic, assign) UITextField *field;

@end
