//
//  TagCloud.m
//  pixiViewer
//
//  Created by nya on 10/05/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "TagCloud.h"
#import "Database.h"
#import "Tag.h"


@implementation TagCloud

+ (TagCloud *) sharedInstance {
	static TagCloud *obj = nil;
	if (obj == nil) {
		obj = [[TagCloud alloc] init];
	}
	return obj;
}

- (void) add:(NSString *)tag forType:(NSString *)type user:(NSString *)user {
	if ([tag length] == 0) {
		return;
	}

	NSManagedObjectContext *ctx = [[Database sharedDatabase] managedObjectContext];
	NSFetchRequest *req = [[[NSFetchRequest alloc] init] autorelease];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:ctx];
	[req setEntity:entity];
	
	NSPredicate *pre = [NSPredicate predicateWithFormat:@"(type == %@) && (username == %@) && (name == %@)", type, user, tag];
	[req setPredicate:pre];

	NSArray *ary = [ctx executeFetchRequest:req error:nil];
	if ([ary count] > 0) {
		Tag *old = [ary objectAtIndex:0];
		old.frequency = [NSNumber numberWithInteger:[old.frequency intValue] + 1];
		[ctx refreshObject:old mergeChanges:YES];
	} else {
		Tag *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:ctx];
		obj.name = tag;
		obj.type = type;
		obj.username = user;
		obj.frequency = [NSNumber numberWithInteger:1];
		[ctx insertObject:obj];
	}
	
	[ctx processPendingChanges];
	[ctx save:nil];
}

- (void) remove:(NSString *)tag forType:(NSString *)type user:(NSString *)user {
	if ([tag length] == 0) {
		return;
	}

	NSManagedObjectContext *ctx = [[Database sharedDatabase] managedObjectContext];
	NSFetchRequest *req = [[[NSFetchRequest alloc] init] autorelease];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:ctx];
	[req setEntity:entity];
	
	NSPredicate *pre = [NSPredicate predicateWithFormat:@"(type == %@) && (username == %@) && (name == %@)", type, user, tag];
	[req setPredicate:pre];

	NSArray *ary = [ctx executeFetchRequest:req error:nil];
	if ([ary count] > 0) {
		Tag *old = [ary objectAtIndex:0];
		if ([old.frequency intValue] > 1) {
			old.frequency = [NSNumber numberWithInteger:[old.frequency intValue] - 1];
			[ctx refreshObject:old mergeChanges:YES];
		} else {
			[ctx deleteObject:old];
		}

		[ctx processPendingChanges];
		[ctx save:nil];
	}	
}

- (void) cleanTagsForType:(NSString *)type user:(NSString *)user {
	NSManagedObjectContext *ctx = [[Database sharedDatabase] managedObjectContext];
	NSArray *ary = [self tagsForType:type user:user];
	for (Tag *tag in ary) {
		[ctx deleteObject:tag];
	}
	[ctx processPendingChanges];
	[ctx save:nil];
}

- (NSArray *) tagsForType:(NSString *)type user:(NSString *)user {
	NSManagedObjectContext *ctx = [[Database sharedDatabase] managedObjectContext];
	NSFetchRequest *req = [[[NSFetchRequest alloc] init] autorelease];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:ctx];
	[req setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"frequency" ascending:NO] autorelease];
	NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
	[req setSortDescriptors:sortDescriptors];
	
	NSPredicate *pre = [NSPredicate predicateWithFormat:@"(type == %@) && (username == %@)", type, user];
	[req setPredicate:pre];

	return [ctx executeFetchRequest:req error:nil];
}

@end
