//
//  PixaMatrixParser.h
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MatrixParser.h"


@interface PixaMatrixParser : MatrixParser {
	NSString	*method;
}

@property(readwrite, retain, nonatomic) NSString *method;

@end
