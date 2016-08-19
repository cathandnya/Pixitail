//
//  CHTumbletailActivity.h
//  CHTumbletailActivity
//
//  Created by nya on 2012/10/02.
//  Copyright (c) 2012年 cathand.org. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHTumbletailActivity : UIActivity

@end


@interface CHTumbletailActivityPhoto : CHTumbletailActivity

@end


@interface CHTumbletailActivityQuote : CHTumbletailActivity {
	NSString *encodedString;
}

@end


@interface CHTumbletailActivityLink : CHTumbletailActivity {
	NSString *encodedString;
}

@end
