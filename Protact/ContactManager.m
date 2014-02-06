//
//  ContactManager.m
//  Protact
//
//  Created by Ryan Lindbeck on 11/9/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "ContactManager.h"
#import "Analytics/Analytics.h"
#import "Constants.h"

@interface ContactManager ()
- (BOOL) saveToLocal;
- (BOOL) saveToAddressBook;
@end

@implementation ContactManager
@synthesize contact;

- (id) initWithParams:(NSDictionary*)params {
    
    self = [super init];
    if (self) {
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        self.contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:appDelegate.managedObjectContext];
        self.contact.createdDate = [NSDate date];
        self.contact.latitude = [NSNumber numberWithFloat:appDelegate.currentLocation.coordinate.latitude];
        self.contact.longitude = [NSNumber numberWithFloat:appDelegate.currentLocation.coordinate.longitude];
        
        if ([params objectForKey:@"firstName"]) {
            [self.contact setFirstName:[params objectForKey:@"firstName"]];
        }
        
        if ([params objectForKey:@"lastName"]) {
            [self.contact setLastName:[params objectForKey:@"lastName"]];
        }
        
        if ([params objectForKey:@"number"]) {
            [self.contact setNumber:[params objectForKey:@"number"]];
        }
        
        if ([params objectForKey:@"looks"]) {
            [self.contact setLongitude:[params objectForKey:@"looks"]];
        }
        
        if ([params objectForKey:@"personality"]) {
            [self.contact setLongitude:[params objectForKey:@"personality"]];
        }
        
        if ([params objectForKey:@"notes"]) {
            [self.contact setLongitude:[params objectForKey:@"notes"]];
        }
        
        if ([params objectForKey:@"status"]) {
            [self.contact setLongitude:[params objectForKey:@"status"]];
        }
        
        if ([params objectForKey:@"venue"]) {
            [self.contact setLongitude:[params objectForKey:@"venue"]];
        }
        
    }
    return self;
}

- (id) initWithContact:(Contact*)contact {
    
    self = [super init];
    if (self) {
        self.contact = contact;
        
    }
    return self;
}

- (BOOL) save {
    BOOL addressBookSuccess = [self saveToAddressBook]; // Must run this first so that you can set the abRecord ID if it is a new contact
    BOOL localSuccess = [self saveToLocal];
    if (localSuccess && addressBookSuccess) {
        return YES;
    }
    
    return NO;
}

- (BOOL) saveToLocal {
    BOOL success = NO;
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    NSError *error;
    [appDelegate.managedObjectContext save:&error];
    if(!error) {
        [[Analytics sharedAnalytics] track:kContactSaved];
        success = YES;
        
    } else {
        
        NSLog(@"Error: %@", [error localizedDescription]);
        success = NO;
        
    }
    
    return success;
}

- (BOOL) saveToAddressBook {
    
    if (self.contact.abRecId != nil) {
        NSLog(@"ABRecordID: %d", [self.contact.abRecId intValue]);
        return [self updateABRecordWithId:(ABRecordID)[self.contact.abRecId intValue]];
    }
    
    CFErrorRef error = NULL;
    
    BOOL didSave = NO;
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
    
    ABRecordRef person = ABPersonCreate();
    
    // Add Phone Number
    if (self.contact.number != nil) {
        ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(phoneNumberMultiValue ,(__bridge CFTypeRef)(self.contact.number),kABPersonPhoneMainLabel, NULL);
        ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
    }
    
    // Add First Name
    if (self.contact.firstName != nil) {
        ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(self.contact.firstName), nil);
    }
    
    // Add Last Name
    if (self.contact.lastName != nil) {
        ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)(self.contact.lastName), nil);
    }
    
    ABAddressBookAddRecord(addressBook, person, &error);
    
    didSave = ABAddressBookSave(addressBook, &error);
    
    ABRecordID recId = ABRecordGetRecordID(person);
    self.contact.abRecId = [NSNumber numberWithInt:(int)recId];
    
    NSLog(@"abRecId: %@", self.contact.abRecId);
    
    CFRelease(person);
    
    if (error != NULL) {
        
        NSLog(@"AB Saved Error: %@", CFErrorCopyDescription(error));
    }
    
    return didSave;

}

- (BOOL) updateABRecordWithId:(ABRecordID)recId {
    
    BOOL didSave = NO;
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
    
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, recId);
    
    if (person) {
        
        ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(phoneNumberMultiValue ,(__bridge CFTypeRef)(self.contact.number),kABPersonPhoneMobileLabel, NULL);
        
        ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(self.contact.firstName), nil);
        ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)(self.contact.lastName), nil);
        
        ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
        
        CFErrorRef error = NULL;
        
        didSave = ABAddressBookSave(addressBook, &error);
        
        if (error != NULL) {
            
            NSLog(@"AB Saved Error: %@", CFErrorCopyDescription(error));
        }
        
    }
    
    return didSave;
    
}

- (BOOL) remove {
    BOOL success = NO;
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.managedObjectContext deleteObject:self.contact];
    
    [self deleteABRecordWithId:(ABRecordID)[self.contact.abRecId intValue]];
    
    if ([self saveToLocal]) {
        success = YES;
    }
    
    return success;
    
}

- (BOOL) deleteABRecordWithId:(ABRecordID)recId {
    
    BOOL didSave = NO;
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
    
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, recId);
    
    if (person) {
        
        CFErrorRef error = NULL;
        BOOL removed = ABAddressBookRemoveRecord(addressBook, person, &error);
        if (removed) {
            didSave = ABAddressBookSave(addressBook, &error);
            if (error != NULL) {
                NSLog(@"AB Saved Error: %@", CFErrorCopyDescription(error));
            }
        }
    }
    
    return didSave;
    
}

@end
