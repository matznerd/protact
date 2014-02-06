//
//  Util.h
//  FRManagement
//
//  Created by Ryan Lindbeck on 7/26/13.
//  Copyright (c) 2013 Inndevers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject


+ (NSString*) formatPhoneNumber:(NSString*)simpleNumber deleteLastChar:(BOOL)deleteLastChar;
+ (UIColor*) colorWithHexString:(NSString*)hex;
+ (NSArray*) namesForName:(NSString*)name;
+ (NSString*) replaceFormatCharsInPhoneNumber:(NSString*)number;

@end
