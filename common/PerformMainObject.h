//
//  PerformMainObject.h
//  pixiViewer
//
//  Created by nya on 10/07/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PerformMainObject : NSObject {
	id target;
	SEL selector;
}

@property(readwrite, nonatomic, assign) id target;
@property(readwrite, nonatomic, assign) SEL selector;

- (void) performMain:(id)arg;

@end
