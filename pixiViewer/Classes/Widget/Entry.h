//
//  Entry.h
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

#import <Foundation/Foundation.h>

@interface Entry : NSObject
@property(strong) NSString *illust_id;
@property(strong) NSString *thumbnail_url;
@property(strong) NSString *service_name;
@property(strong) id other_info;

@property(readonly) NSDictionary *info;

- (id) initWithInfo:(NSDictionary *)info;

@end
