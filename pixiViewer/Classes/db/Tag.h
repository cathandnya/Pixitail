//
//  Tag.h
//  pixiViewer
//
//  Created by nya on 10/05/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Tag : NSManagedObject

@property(readwrite, nonatomic, retain) NSString *name;
@property(readwrite, nonatomic, retain) NSString *type;
@property(readwrite, nonatomic, retain) NSString *username;
@property(readwrite, nonatomic, retain) NSNumber *frequency;

@end
