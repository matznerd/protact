//
//  ContactAnnotation.m
//  Protact
//
//  Created by Ryan Lindbeck on 1/7/14.
//  Copyright (c) 2014 Inndevers LLC. All rights reserved.
//

#import "ContactAnnotation.h"

@implementation ContactAnnotation

- (id)initWithContact:(Contact *)contact {
    self = [super init];
    if (self) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([contact.latitude floatValue], [contact.longitude floatValue]);
        _coordinate = coordinate;
        _contact = contact;
        _title = contact.name;
    }
    return self;
}

@end
