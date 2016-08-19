//
//  MultiSelectionViewController.m
//
//  Created by nya on 10/06/18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MultiSelectionViewController.h"


@implementation MultiSelectionViewController

@synthesize object, titles, allowMultipleSelection, allowEmptySelection, selectedIndexes, delegate;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    //self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
    //self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
}

- (void) done {
    [delegate multiSelectionView:self done:YES];
}

- (void) cancel {
    [delegate multiSelectionView:self done:NO];
}

- (void) viewWillDisappear:(BOOL)b {
	[super viewWillDisappear:b];
	[self done];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [titles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (selectedIndexes == nil) {
        selectedIndexes = [[NSMutableIndexSet alloc] init];
    }
    
    cell.textLabel.text = [titles objectAtIndex:indexPath.row];
    cell.accessoryType = [selectedIndexes containsIndex:indexPath.row] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (allowMultipleSelection == NO) {
        for (UITableViewCell *cell in [tableView visibleCells]) {
            NSIndexPath *idx = [tableView indexPathForCell:cell];
            if ([indexPath isEqual:idx] == NO) {
                if ([selectedIndexes containsIndex:idx.row]) {
                    [selectedIndexes removeIndex:idx.row];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
        }
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (allowEmptySelection) {
        if ([selectedIndexes containsIndex:indexPath.row]) {
            [selectedIndexes removeIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            [selectedIndexes addIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        if (![selectedIndexes containsIndex:indexPath.row]) {
            [selectedIndexes addIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

- (void)dealloc {
    [object release];
    [titles release];
    [selectedIndexes release];

    [super dealloc];
}


@end

