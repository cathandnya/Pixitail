//
//  PixivSearchedUserListParser.h
//  pixiViewer
//
//  Created by nya on 10/03/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivUserListParser.h"


@interface PixivSearchedUserListParser : PixivUserListParser {
	BOOL hasNext;
}

@property(readonly, nonatomic, assign) BOOL hasNext;

@end
