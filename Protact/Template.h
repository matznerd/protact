//
//  Template.h
//  Protact
//
//  Created by Ryan Lindbeck on 11/8/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Template : NSManagedObject

@property (nonatomic, retain) NSNumber * isDefault;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * title;

@end
