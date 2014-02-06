//
//  ContactDetailsTableViewController.h
//  Protact
//
//  Created by Ryan Lindbeck on 11/8/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"

@interface ContactDetailsTableViewController : UITableViewController

@property (nonatomic, strong) Contact *contact;

@end
