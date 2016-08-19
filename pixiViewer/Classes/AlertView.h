//
//  AlertView.h
//
//  Created by nya on 10/11/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AlertView : UIAlertView {
	id object;
}

@property(readwrite, nonatomic, retain) id object;

@end
