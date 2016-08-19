//
//  NetworkActivityIndicator.h
//  EchoPro
//
//  Created by nya on 09/08/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NetworkActivityIndicator : NSObject {
	int		count_;
}

+ (NetworkActivityIndicator *) sharedInstance;

@end
