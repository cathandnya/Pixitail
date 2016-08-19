//
//  TextFieldCell.m
//
//  Created by nya on 10/06/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TextFieldCell.h"


@interface TextFieldCellLoader : UIViewController
@end


@implementation TextFieldCellLoader

- (void) viewDidLoad {
    [super viewDidLoad];
    
    TextFieldCell *cell = (TextFieldCell *)self.view;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end


@implementation TextFieldCell

@synthesize textField, delegate;

+ (TextFieldCell *) cell:(UITableView *)tableView {
    static NSString *CellIdentifier = @"TextFieldCell";
    TextFieldCell *cell = (TextFieldCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        UIViewController *vc = [[[UIViewController alloc] initWithNibName:@"TextFieldCell" bundle:nil] autorelease];
        cell = (TextFieldCell *)vc.view;
    }
	cell.textLabel.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)dealloc {
    [textField resignFirstResponder];
    [textField release];

    [super dealloc];
}

- (void) prepareForReuse {
    [super prepareForReuse];
    [textField resignFirstResponder];
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    CGSize s = CGSizeZero;
    if ([self.textLabel.text length] > 0) {
        s = [self.textLabel.text sizeWithFont:self.textLabel.font constrainedToSize:CGSizeMake(FLT_MAX, FLT_MAX)];
        s.width += 10;
    }
    
    CGRect r = textField.frame;
    r.origin.x = self.textLabel.frame.origin.x + s.width;
    r.size.width = self.frame.size.width - (r.origin.x + 20);
    if (self.accessoryType == UITableViewCellAccessoryDetailDisclosureButton) {
        r.size.width -= 33;
    }
    textField.frame = r;	
}

#pragma mark-

- (BOOL)textField:(UITextField *)field shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([delegate respondsToSelector:@selector(textFieldCell:shouldChangeCharactersInRange:replacementString:)]) {
        return [delegate textFieldCell:self shouldChangeCharactersInRange:range replacementString:string];
    } else {
        return YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)field {
    if ([delegate respondsToSelector:@selector(textFieldCellValueChanged:)]) {
        [delegate textFieldCellValueChanged:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)field {
    if ([delegate respondsToSelector:@selector(textFieldCellValueChanged:)]) {
        [delegate textFieldCellValueChanged:self];
    }
    //[field resignFirstResponder];
    if ([delegate respondsToSelector:@selector(textFieldCellDidReturn:)]) {
        [delegate textFieldCellDidReturn:self];
    }
    return NO;
}

@end
