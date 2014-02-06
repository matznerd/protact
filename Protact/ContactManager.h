//
//  ContactManager.h
//  Protact
//
//  Created by Ryan Lindbeck on 11/9/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Contact.h"

@interface ContactManager : NSObject

@property (nonatomic, strong) Contact *contact;

- (id) initWithParams:(NSDictionary*)params;
- (id) initWithContact:(Contact*)contact;
- (BOOL) save;
- (BOOL) remove;


@end
