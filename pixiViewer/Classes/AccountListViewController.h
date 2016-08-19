//
//  AccountListViewController.h
//  pixiViewer
//
//  Created by nya on 09/12/16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"


@interface AccountListViewController : DefaultTableViewController {
	BOOL initial;
}

- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)b;

@end
