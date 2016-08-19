//
//  Pixa.h
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixService.h"


@interface Pixa : PixService {
	NSString	*authenticityToken;

	NSMutableData	*logoutRet_;
}

@property(readwrite, retain, nonatomic) NSString *authenticityToken;

+ (Pixa *) sharedInstance;

@end
