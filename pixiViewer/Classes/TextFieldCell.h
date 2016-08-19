//
//  TextFieldCell.h
//
//  Created by nya on 10/06/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class TextFieldCell;
@protocol TextFieldCellDelegate<NSObject>
@optional
- (BOOL) textFieldCell:(TextFieldCell *)sender shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
- (void) textFieldCellValueChanged:(TextFieldCell *)sender;
- (void) textFieldCellDidReturn:(TextFieldCell *)sender;
@end


@interface TextFieldCell : UITableViewCell<UITextFieldDelegate> {
    UITextField *textField;
    id<TextFieldCellDelegate> delegate;
}

@property(readwrite, nonatomic, retain) IBOutlet UITextField *textField;
@property(readwrite, nonatomic, assign) id<TextFieldCellDelegate> delegate;

+ (TextFieldCell *) cell:(UITableView *)tableView;

@end
