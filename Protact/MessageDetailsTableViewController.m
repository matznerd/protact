//
//  MessageDetailsTableViewController.m
//  Protact
//
//  Created by Ryan Lindbeck on 1/6/14.
//  Copyright (c) 2014 Inndevers LLC. All rights reserved.
//

#import "MessageDetailsTableViewController.h"
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "Constants.h"

@interface MessageDetailsTableViewController ()
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) IBOutlet UIButton *defaultButton;
- (IBAction)save:(id)sender;
- (IBAction)defaultButtonPressed:(id)sender;
@end

@implementation MessageDetailsTableViewController
@synthesize titleTextField, messageTextView, appDelegate, defaultButton;

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
    
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.messageTextView.layer.borderWidth = 1.0f;
    self.messageTextView.layer.borderWidth = 1.0f;
    self.messageTextView.layer.borderColor = [UIColor greenColor].CGColor;
    
    [self.titleTextField becomeFirstResponder];
    
    if (self.message != nil) {
        [self populateFieldsWithMessage];
        self.defaultButton.hidden = NO;
    } else {
        self.defaultButton.hidden = YES;
    }

}

- (void) viewDidAppear:(BOOL)animated {
    [[Analytics sharedAnalytics] screen:kViewTemplateDetails];
}

- (void) populateFieldsWithMessage {
    self.titleTextField.text = self.message.title;
    self.messageTextView.text = self.message.message;
    [self toggleDefaultButton];
}

- (IBAction)save:(id)sender {
    BOOL isFirstTemplate = YES;
    if ([self getTemplatesCount])
        isFirstTemplate = NO;
    
    if (self.message == nil)
        self.message = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.appDelegate.managedObjectContext];
    
    self.message.title = self.titleTextField.text;
    self.message.message = self.messageTextView.text;
    if (isFirstTemplate) {
        self.message.isDefault = [NSNumber numberWithBool:YES];
        [self toggleDefaultButton];
    }
    
    NSError *error;
    [self.appDelegate.managedObjectContext save:&error];
    
    if(!error) {
        [self displaySuccessMessage];
        self.defaultButton.hidden = NO;
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
        
    }
}

- (IBAction) defaultButtonPressed:(id)sender {
    [self updateOtherTemplatesAsNonDefault];
    if (!self.message.isDefault.boolValue) {
        self.message.isDefault = [NSNumber numberWithBool:YES];
    }
    [self.appDelegate.managedObjectContext save:nil];
    [self toggleDefaultButton];
}

- (void) toggleDefaultButton {
    if (self.message.isDefault.boolValue) {
        [self.defaultButton setTitle:@"Default" forState:UIControlStateNormal];
        self.defaultButton.enabled = NO;
    } else {
        [self.defaultButton setTitle:@"Set As Default" forState:UIControlStateNormal];
        self.defaultButton.enabled = YES;
    }
}

- (void) updateOtherTemplatesAsNonDefault {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Template" inManagedObjectContext:self.appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *templates = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error) {
        for (Template *template in templates) {
            template.isDefault = [NSNumber numberWithBool:NO];
        }
    } else
        NSLog(@"Error: %@", [error localizedDescription]);
    
    [self.appDelegate.managedObjectContext save:&error];
    
    if(error)
        NSLog(@"Error: %@", [error localizedDescription]);
    
}

- (int) getTemplatesCount {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Template" inManagedObjectContext:self.appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *templates = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    return templates.count;
}

- (void) displaySuccessMessage {
    UIAlertView *successAlertview = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Message Saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [successAlertview show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
