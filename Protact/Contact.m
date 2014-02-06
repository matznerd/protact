//
//  Contact.m
//  Protact
//
//  Created by Ryan Lindbeck on 11/12/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "Contact.h"


@implementation Contact

@dynamic abRecId;
@dynamic createdDate;
@dynamic firstName;
@dynamic lastName;
@dynamic latitude;
@dynamic longitude;
@dynamic looks;
@dynamic nameInitial;
@dynamic notes;
@dynamic number;
@dynamic personality;
@dynamic venue;
@dynamic status;
@dynamic name;

- (NSString *) nameInitial {
    
    [self willAccessValueForKey:@"nameInitial"];
    
    NSString * initial;
    
    if (self.lastName.length) {
        
        NSLog(@"lastName not nil");
        
        initial = [[[self lastName] uppercaseString] substringToIndex:1];
        
    } else if (self.firstName.length) {
        
        NSLog(@"lastName nil");
        
        initial = [[[self firstName] uppercaseString] substringToIndex:1];
        
    } else {
        
        initial = @" ";
    }
    
    [self didAccessValueForKey:@"nameInitial"];
    return initial;
    
}


- (NSString *) name {
    
    [self willAccessValueForKey:@"name"];
    
    NSString *name;
    
    if (self.firstName.length) {
        name = self.firstName;
    }
    
    if (self.lastName.length) {
        name = [NSString stringWithFormat:@"%@ %@", name, self.lastName];
    }
    
    if (!self.firstName.length && !self.lastName.length) {
        name = self.number;
    }
    
    [self didAccessValueForKey:@"name"];
    
    return name;
}


@end
