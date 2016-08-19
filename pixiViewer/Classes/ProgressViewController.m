//
//  ProgressViewController.m
//  EchoPro
//
//  Created by nya on 09/10/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ProgressViewController.h"


static void CGContextFillStrokeRoundedRect( CGContextRef context, CGRect rect, CGFloat radius ) {
	CGContextMoveToPoint( context, CGRectGetMinX( rect ), CGRectGetMidY( rect ));
	CGContextAddArcToPoint( context, CGRectGetMinX( rect ), CGRectGetMinY( rect ), CGRectGetMidX( rect ), CGRectGetMinY( rect ), radius );
	CGContextAddArcToPoint( context, CGRectGetMaxX( rect ), CGRectGetMinY( rect ), CGRectGetMaxX( rect ), CGRectGetMidY( rect ), radius );
	CGContextAddArcToPoint( context, CGRectGetMaxX( rect ), CGRectGetMaxY( rect ), CGRectGetMidX( rect ), CGRectGetMaxY( rect ), radius );
	CGContextAddArcToPoint( context, CGRectGetMinX( rect ), CGRectGetMaxY( rect ), CGRectGetMinX( rect ), CGRectGetMidY( rect ), radius );
	CGContextSetLineWidth( context, 2 );
	CGContextClosePath( context );
	CGContextDrawPath( context, kCGPathFillStroke );
	//CGContextFillPath(context);
}


@interface ProgressBackView : UIView {
}
@end


@implementation ProgressBackView

- (void) drawRect:(CGRect)rect {
	CGRect r;
	r.origin.x = 1;
	r.origin.y = 1;
	r.size.width = rect.size.width - 2;
	r.size.height = rect.size.height - 2;
	
	[[[UIColor blackColor] colorWithAlphaComponent:0.75] setFill];
	[[[UIColor whiteColor] colorWithAlphaComponent:0.75] setStroke];
	CGContextFillStrokeRoundedRect(UIGraphicsGetCurrentContext(), r, 10);
}

@end



@implementation ProgressViewController

@synthesize progressView, activityView, textView, cancelButton, backView;
@dynamic showActivity;
@synthesize tag, text;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (BOOL) showActivity {
	return showActivity;
}

- (void) setShowActivity:(BOOL)b {
	showActivity = b;
	if (showActivity) {
		self.progressView.hidden = YES;
		[self.activityView startAnimating];
	} else {
		self.progressView.hidden = NO;
		[self.activityView stopAnimating];
	}
}

- (void)dealloc {
	[progressView release];
	[activityView release];
	[textView release];
	[cancelButton release];
	[backView release];
	[text release];

    [super dealloc];
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	backView.backgroundColor = [UIColor clearColor];
	[self setDoubleValue:0.0];
	[self setShowActivity:self.showActivity];
	if (text) textView.text = text;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void) setDoubleValue:(double)val {
	progressView.progress = val;
}

- (void) setCancelAction:(SEL)sel toTarget:(id)target {
	cancelAction = sel;
	cancelTarget = target;
}

- (IBAction) cancel {
	[cancelTarget performSelector:cancelAction withObject:self];
}

@end
