//
//  Service.h
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

#import <Foundation/Foundation.h>

@class PixivMatrixParser;
@class CHHtmlParserConnection;

@interface Service : NSObject
@property(strong) NSString *name;
@property(strong) NSString *username;
@property(strong) NSString *password;
@property(strong) NSDate *loginDate;
@property(strong) NSString *authToken;
@property(readonly) BOOL needsLogin;

+ (Service *) serviceWithName:(NSString *)n username:(NSString *)un password:(NSString *)pass;
- (id) initWithUsername:(NSString *)un password:(NSString *)pass;

- (NSError *) login;

- (PixivMatrixParser *) makeParser:(NSString *)key method:(NSString *)method;
- (CHHtmlParserConnection *) makeConnection:(NSString *)method page:(int)page;

@end


NSString* encodeURIComponent(NSString* s);
