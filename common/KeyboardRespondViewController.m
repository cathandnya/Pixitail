//
//  KeyboardRespondViewController.m
//
//  Created by Naomoto nya on 12/02/08.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "KeyboardRespondViewController.h"

@implementation KeyboardRespondViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
	[super viewWillDisappear:animated];	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark-

- (UIScrollView *) baseScrollView {
	return nil;
}

#pragma mark-

- (void) cancelAction:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) okAction:(id)sender {
}

#pragma mark-

- (void) updateBaseFrame:(CGRect)rect {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return;
	}
	[self baseScrollView].frame = rect;
}

#pragma mark-

- (void) keyboardWillShow:(NSNotification *)notif {	
	NSDictionary *dic = [notif userInfo];
	NSTimeInterval ti = [[dic objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	CGRect bounds = self.view.frame;
	CGRect keyboardFrameEnd = [[dic objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect r0, r1;
	
	r0 = [self baseScrollView].frame;
	
	if (keyboardFrameEnd.size.height == 0) {
		r1.origin.x = 0;
		r1.origin.y = 0;
		r1.size.width = bounds.size.width;
		r1.size.height = 200;
	} else {
		r1.origin.x = 0;
		r1.origin.y = 0;
		r1.size.width = bounds.size.width;
		r1.size.height = bounds.size.height - keyboardFrameEnd.size.height;
	}
	
	if (CGRectEqualToRect(r0, r1)) {
		return;
	}
	
	if (ti > 0) {
		[UIView beginAnimations:@"" context:nil];
		[UIView setAnimationDuration:ti];
		[UIView setAnimationCurve:[[dic objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
	}
	[self updateBaseFrame:r1];
	if (ti > 0) {
		[UIView commitAnimations];
	}
}

- (void) keyboardWillHide:(NSNotification *)notif {
	NSDictionary *dic = [notif userInfo];
	NSTimeInterval ti = [[dic objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	CGRect bounds = self.view.frame;
	CGRect keyboardFrameEnd = [[dic objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect r0, r1;
	
	r0 = [self baseScrollView].frame;
	
	if (keyboardFrameEnd.size.height == 0) {
		r1.origin.x = 0;
		r1.origin.y = 0;
		r1.size.width = bounds.size.width;
		r1.size.height = 200;
	} else {
		r1.origin.x = 0;
		r1.origin.y = 0;
		r1.size.width = bounds.size.width;
		r1.size.height = bounds.size.height;
	}
	
	if (CGRectEqualToRect(r0, r1)) {
		return;
	}
	
	if (ti > 0) {
		[UIView beginAnimations:@"" context:nil];
		[UIView setAnimationDuration:ti];
		[UIView setAnimationCurve:[[dic objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
	}
	[self updateBaseFrame:r1];
	if (ti > 0) {
		[UIView commitAnimations];
	}
}

- (void) keyboardDidShow:(NSNotification *)notif {
	keyboardIsShown = YES;
}

- (void) keyboardDidHide:(NSNotification *)notif {
	keyboardIsShown = NO;
}

#pragma mark-

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	dispatch_async(dispatch_get_main_queue(), ^{
		CGRect r = textField.frame;
		if (textField.superview != [self baseScrollView]) {
			r = [[self baseScrollView] convertRect:r fromView:textField.superview];
		}
		r.origin.y -= ([self baseScrollView].frame.size.height - r.size.height) / 2;
		r.size.height = [self baseScrollView].frame.size.height;
		[[self baseScrollView] scrollRectToVisible:r animated:YES];
	});
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

#pragma mark-

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	dispatch_async(dispatch_get_main_queue(), ^{
		CGRect r = textView.frame;
		if (textView.superview != [self baseScrollView]) {
			r = [[self baseScrollView] convertRect:r fromView:textView.superview];
		}
		[[self baseScrollView] scrollRectToVisible:r animated:YES];
	});
}

- (void)textViewDidEndEditing:(UITextView *)textView {
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
}

@end


@implementation KeyboardRespondTableViewController

@synthesize tableView;

- (void) dealloc {
	self.tableView = nil;
	[super dealloc];
}

- (void) viewDidUnload {
	self.tableView = nil;
	[super dealloc];
}

- (UIScrollView *) baseScrollView {
	return self.tableView;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)aTableView {
	return 0;
}

- (NSInteger) tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return 0;
}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

@end
