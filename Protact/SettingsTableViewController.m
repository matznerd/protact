//
//  SettingsTableViewController.m
//  Protact
//
//  Created by Ryan Lindbeck on 2/6/14.
//  Copyright (c) 2014 Inndevers LLC. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Constants.h"

@interface SettingsTableViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *defaultSwitch;

- (IBAction)defaultSwitchChanged:(id)sender;

@end

@implementation SettingsTableViewController
@synthesize defaultSwitch;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) viewDidAppear:(BOOL)animated {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kDefaultMessagetIsOn] boolValue])
        [self.defaultSwitch setOn:YES];
    else
        [self.defaultSwitch setOn:NO];
}

- (IBAction)defaultSwitchChanged:(id)sender {
    if(self.defaultSwitch.isOn)
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultMessagetIsOn];
    else
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultMessagetIsOn];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
