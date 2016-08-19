//
//  ScrapingMetadata.h
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface ScrapingTag : NSObject 

@property(readwrite, nonatomic, retain) NSString *ID;
@property(readwrite, nonatomic, retain) NSString *name;
@property(readwrite, nonatomic, retain) NSDictionary *attributes;
@property(readwrite, nonatomic, assign) ScrapingTag *parent;
@property(readwrite, nonatomic, retain) NSMutableArray *children;
@property(readwrite, nonatomic, assign) int depth;

@property(readwrite, nonatomic, retain) NSDictionary *needsScrapAttributes;
@property(readwrite, nonatomic, retain) NSArray *needsScrapBodys;
@property(readwrite, nonatomic, assign) BOOL needsReadBody;

- (id) initWithDictionary:(NSDictionary *)dic;

- (BOOL) matchStart:(NSString *)name attributes:(NSDictionary *)attr;
- (BOOL) matchEnd:(NSString *)name;

- (NSDictionary *) scrapedAttributes:(NSDictionary *)attr;
- (NSArray *) scrapedBodys:(NSString *)body;

- (void) addChild:(ScrapingTag *)c;

@end


@interface ScrapingResult : NSObject 

@property(readwrite, nonatomic, retain) NSMutableString *stringBuffer;

@property(readwrite, nonatomic, retain) NSDictionary *scrapedAttributes;
@property(readwrite, nonatomic, retain) NSArray *scrapedBodys;

@property(readwrite, nonatomic, retain) NSString *ID;
@property(readwrite, nonatomic, assign) ScrapingResult *parent;
@property(readwrite, nonatomic, retain) NSMutableArray *children;

- (void) addChild:(ScrapingResult *)c;
- (ScrapingResult *) childForPath:(NSString *)path;
- (NSString *) description;

@end


@interface ScrapingEvaluator : NSObject 

@property(readwrite, nonatomic, retain) NSArray *path;
@property(readwrite, nonatomic, retain) NSString *attrName;
@property(readwrite, nonatomic, retain) NSArray *children;
@property(readwrite, nonatomic, retain) NSArray *replacing;
@property(readwrite, nonatomic, assign) int regexIndex;
@property(readwrite, nonatomic, assign) int bodyIndex;
@property(readwrite, nonatomic, assign) int resultIndex;
@property(readwrite, nonatomic, assign) BOOL isList;
@property(readwrite, nonatomic, assign) BOOL strict;

@property(readwrite, nonatomic, assign) ScrapingResult *resultRoot;

- (id) initWithDictionary:(NSDictionary *)dic;

- (id) eval;

@end
