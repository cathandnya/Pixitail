//
//  UnzipFile.h
//
//  Created by nya on 10/08/17.
//  Copyright 2010 Cores. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UnzipFile : NSObject {
	NSString *path;
	NSData *password;
}

@property(readwrite, nonatomic, retain) NSData *password;

- (id) initWithPath:(NSString *)str;

- (NSArray *) files;
- (NSData *) contentWithFilename:(NSData *)cstring;
- (void) cancelLoadContent;

- (BOOL) contentNeedsPassword:(NSData *)cstring;
- (BOOL) contentPasswordIsValid:(NSData *)cstring password:(NSData *)pass;

@end
