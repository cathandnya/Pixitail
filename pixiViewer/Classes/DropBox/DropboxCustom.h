//
//  DropboxCustom.h
//  Pictures
//
//  Created by nya on 2012/08/20.
//
//

#import <Foundation/Foundation.h>
#import "DropboxSDK.h"


@interface DBSessionCustom : DBSession

- (NSString *) handleOpenURLReturningUserID:(NSURL *)url;

@end


@interface SessionDelegate : NSObject<DBSessionDelegate>

+ (SessionDelegate *) sharedInstance;

@end
