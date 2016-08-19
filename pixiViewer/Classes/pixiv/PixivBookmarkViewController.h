//
//  PixivBookmarkViewController.h
//  pixiViewer
//
//  Created by nya on 09/08/21.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivMatrixViewController.h"


@interface PixivBookmarkViewController : PixivMatrixViewController {
	CHHtmlParser	*parserHide_;
	int				loadedPageHide_;
	int				maxPageHide_;
}

@end
