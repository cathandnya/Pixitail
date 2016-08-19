//
//  NijieAgeJumpParser.h
//  pixiViewer
//
//  Created by nya on 2012/09/29.
//
//

#import <Foundation/Foundation.h>
#import "CHHtmlParser.h"

@interface NijieAgeJumpParser : CHHtmlParser

@property(readwrite, nonatomic, retain) NSString *urlPrefix;
@property(readwrite, nonatomic, retain) NSString *url;

@end
