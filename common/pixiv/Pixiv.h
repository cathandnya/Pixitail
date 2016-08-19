//
//  Pixiv.h
//  pixiViewerTest
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixService.h"


@interface Pixiv : PixService {
}

@property(readwrite, nonatomic, retain) NSString *tt;

+ (Pixiv *) sharedInstance;

@end
