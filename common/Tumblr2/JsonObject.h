//
//  JsonObject.h
//
//  Created by nya on 11/02/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JsonObject : NSObject {
	id json;
}

@property(readonly, nonatomic, assign) id json;

- (id) initWithJson:(id)obj;
- (id) initWithContentsOfFile:(NSString *)path;
- (void) writeToFile:(NSString *)path;
- (NSData *) data;
- (id) valueForKey:(NSString *)key;
- (void) merge:(NSDictionary *)d;

@end
