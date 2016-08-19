//
//  MultiSelectionViewController.h
//
//  Created by nya on 10/06/18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MultiSelectionViewController;
@protocol MultiSelectionViewControllerDelegate<NSObject>
- (void) multiSelectionView:(MultiSelectionViewController *)mview done:(BOOL)complete;
@end


@interface MultiSelectionViewController : UITableViewController {
    id object;
    NSArray *titles;
    BOOL allowMultipleSelection;
    BOOL allowEmptySelection;
    NSMutableIndexSet *selectedIndexes;
    id<MultiSelectionViewControllerDelegate> delegate;
}

@property(readwrite, nonatomic, retain) id object;
@property(readwrite, nonatomic, retain) NSArray *titles;
@property(readwrite, nonatomic, assign) BOOL allowMultipleSelection;
@property(readwrite, nonatomic, assign) BOOL allowEmptySelection;
@property(readwrite, nonatomic, retain) NSMutableIndexSet *selectedIndexes;
@property(readwrite, nonatomic, assign) id<MultiSelectionViewControllerDelegate> delegate;

@end
