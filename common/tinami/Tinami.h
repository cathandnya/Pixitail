//
//  Tinami.h
//  pixiViewer
//
//  Created by nya on 10/02/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixService.h"


@interface Tinami : PixService {
	NSMutableData *ratingRet;
	NSMutableData *bookmarkRet;
	NSString *creatorID;
	NSURLConnection *getLoginInfoConnection;
}

@property(readonly, nonatomic, retain) NSString *creatorID;
@property(readwrite, nonatomic, retain) NSString *authKey;

+ (Tinami *) sharedInstance;

@end
