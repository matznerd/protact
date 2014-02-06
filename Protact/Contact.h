//
//  Contact.h
//  Protact
//
//  Created by Ryan Lindbeck on 11/12/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Contact : NSManagedObject

@property (nonatomic, retain) NSNumber * abRecId;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * looks;
@property (nonatomic, retain) NSString * nameInitial;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSNumber * personality;
@property (nonatomic, retain) NSString * venue;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * name;

@end
