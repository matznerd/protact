//
//  ContactAnnotation.h
//  Protact
//
//  Created by Ryan Lindbeck on 1/7/14.
//  Copyright (c) 2014 Inndevers LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Contact.h"

@interface ContactAnnotation : NSObject <MKAnnotation>

@property (nonatomic, strong) Contact *contact;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;

- (id)initWithContact:(Contact *)contact;

@end
