//
//  KeyboardViewController.m
//  Protact
//
//  Created by Ryan Lindbeck on 11/8/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "KeyboardViewController.h"
#import "ContactManager.h"
#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Template.h"
#import "Util.h"
#import "Constants.h"

@interface KeyboardViewController () <UITextFieldDelegate, MFMessageComposeViewControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

typedef enum directionTypes {
    DIRECTIONLEFT = 0,
    DIRECTIONRIGHT = 1
} Direction;

@property (nonatomic, strong) Contact *contact;
@property (nonatomic, weak) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, weak) IBOutlet UIView *addContactView;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextView *messageTextView;
@property (nonatomic, weak) IBOutlet UIView *keyboardView;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) IBOutlet UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UISwitch *defaultSwitch;
@property (nonatomic, strong) NSString *defaultMessage;
@property (nonatomic, weak) IBOutlet UITableView *templatesTableView;

@property (nonatomic, strong) NSFetchRequest *searchFetchRequest;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (IBAction) keyPadNumberPressed:(id)sender;
- (IBAction) backButtonPressed:(id)sender;
- (IBAction) callPressed:(id)sender;
- (IBAction) saveAndSendPressed:(id)sender;
- (IBAction) savePressed:(id)sender;
- (IBAction) nextPressed:(id)sender;
- (IBAction) chooseTemplatePressed:(id)sender;
- (IBAction) defaultSwitchChanged:(id)sender;

@end

@implementation KeyboardViewController
@synthesize appDelegate, phoneNumberField, contact, keyboardView, pickerView, defaultSwitch, defaultMessage;
@synthesize addContactView, nameTextField, messageTextView, templatesTableView;
@synthesize searchFetchRequest = _searchFetchRequest;
@synthesize fetchedResultsController = _fetchedResultsController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    self.nameTextField.layer.borderWidth = 1.0f;
    self.messageTextView.layer.borderWidth = 1.0f;
    self.nameTextField.layer.borderColor = [UIColor greenColor].CGColor;
    self.messageTextView.layer.borderColor = [UIColor greenColor].CGColor;
    
    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    [self.phoneNumberField addGestureRecognizer:tapGesture];
    
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
}

- (void) viewDidAppear:(BOOL)animated {
    [[Analytics sharedAnalytics] screen:kViewKeyboard];
    self.phoneNumberField.text = nil;
    [self setUpDefaultTemplate];
}

- (void) viewTapped {
    [self hideView:self.addContactView direction:DIRECTIONLEFT];
    [self hideView:self.templatesTableView direction:DIRECTIONLEFT];
    [self showView:self.keyboardView];
    [self.nameTextField resignFirstResponder];
    [self.messageTextView resignFirstResponder];
}

- (IBAction) nextPressed:(id)sender {
    [[Analytics sharedAnalytics] track:kEventKeyboardNext];
    [self hideView:self.keyboardView direction:DIRECTIONRIGHT];
    [self showView:self.addContactView];
    [self.nameTextField becomeFirstResponder];
}

- (IBAction)chooseTemplatePressed:(id)sender {
    [[Analytics sharedAnalytics] track:kEventKeyboardChooseTemplate];
    if ([[self.fetchedResultsController fetchedObjects] count]) {
        [self.templatesTableView reloadData];
        [self hideView:self.addContactView direction:DIRECTIONRIGHT];
        [self showView:self.templatesTableView];
        [self.nameTextField resignFirstResponder];
        [self.messageTextView resignFirstResponder];
    } else {
        [self displayNoTemplatesMessage];
    }
}

- (void) showView:(UIView*)view {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [view setFrame:CGRectMake(0, view.frame.origin.y, view.frame.size.width, view.frame.size.height)];
    [UIView commitAnimations];
}

- (void) hideView:(UIView*)view direction:(Direction)direction {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    if (direction == DIRECTIONLEFT)
        [view setFrame:CGRectMake(-view.frame.size.width, view.frame.origin.y, view.frame.size.width, view.frame.size.height)];
    else
        [view setFrame:CGRectMake(view.frame.size.width, view.frame.origin.y, view.frame.size.width, view.frame.size.height)];
    [UIView commitAnimations];
}

- (void) setUpDefaultTemplate {
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kDefaultMessagetIsOn] boolValue])
        [self.defaultSwitch setOn:YES];
    else
        [self.defaultSwitch setOn:NO];
    
    NSArray *templates = [_fetchedResultsController fetchedObjects];
    for (Template *template in templates) {
        if ([template.isDefault boolValue])
            self.defaultMessage = template.message;
        
    }
    
    if (self.defaultSwitch.isOn) {
        if (self.defaultMessage != nil)
            self.messageTextView.text = self.defaultMessage;
        else
            [self.defaultSwitch setOn:NO];
    } else
        self.messageTextView.text = nil;
}

- (IBAction) saveAndSendPressed:(id)sender {
    [[Analytics sharedAnalytics] track:kEventKeyboardSaveAndSend];
    if (self.nameTextField.text.length) {
        if (self.phoneNumberField.text.length) {
            if ([self saveContact]) {
                [self displaySMSViewWithMessage:self.messageTextView.text];
                self.phoneNumberField.text = nil;
                self.nameTextField.text = nil;
                self.messageTextView.text = nil;
                [self.nameTextField resignFirstResponder];
                [self.messageTextView resignFirstResponder];
            } else {
                [self displayFailedMessage];
            }
        } else {
            [self displayNoNumberMessage];
        }
    } else {
        [self displayNoNameMessage];
    }
}

- (IBAction) savePressed:(id)sender {
    [[Analytics sharedAnalytics] track:kEventKeyboardSave];
    if (self.nameTextField.text.length) {
        if (self.phoneNumberField.text.length) {
            if ([self saveContact]) {
                [self displaySuccessMessage];
                [self hideView:self.addContactView direction:DIRECTIONLEFT];
                [self showView:self.keyboardView];
                self.phoneNumberField.text = nil;
                self.nameTextField.text = nil;
                self.messageTextView.text = nil;
                [self.nameTextField resignFirstResponder];
                [self.messageTextView resignFirstResponder];
            } else {
                [self displayFailedMessage];
            }
        } else {
            [self displayNoNumberMessage];
        }
    } else {
        [self displayNoNameMessage];
    }
}

- (BOOL) saveContact {
    NSArray *names = [self.nameTextField.text componentsSeparatedByString:@" "];
    NSDictionary *params;
    if (names.count > 1) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  [names objectAtIndex:0], @"firstName",
                  [names objectAtIndex:1], @"lastName",
                  self.phoneNumberField.text, @"number",
                  nil];
    } else {
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  self.nameTextField.text, @"firstName",
                  self.phoneNumberField.text, @"number",
                  nil];
        
    }

    ContactManager *cm = [[ContactManager alloc]  initWithParams:params];
    return [cm save];
}

- (void) displayNoNameMessage {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Name" message:@"Please enter a name." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
}

- (void) displayNoNumberMessage {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Number" message:@"Please enter a number." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
}

- (void) displayNoTemplatesMessage {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Templates" message:@"Go to the Templates tab to add templates." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
}

- (void) displayNoDefaultTemplateMessage {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Default Template" message:@"Go to the Templates tab to set a default template." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
}

- (IBAction) keyPadNumberPressed:(id)sender {
    if ([sender tag] < 10) { // only add if it is a number (not for star or pound key)
        NSRange range = NSMakeRange(self.phoneNumberField.text.length, 0);
        NSString *replaceString = [NSString stringWithFormat:@"%d", [sender tag]];
        [self textField:self.phoneNumberField shouldChangeCharactersInRange:range replacementString:replaceString];
    }
}

- (IBAction) backButtonPressed:(id)sender {
    NSRange range = NSMakeRange(self.phoneNumberField.text.length, 1);
    [self textField:self.phoneNumberField shouldChangeCharactersInRange:range replacementString:@""];
}

- (IBAction) callPressed:(id)sender {
    NSString *rawNumber = [Util replaceFormatCharsInPhoneNumber:self.phoneNumberField.text];
    NSString *telString = [NSString stringWithFormat:@"tel:%@", rawNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:telString]];
}

- (void) displaySMSViewWithMessage:(NSString*)message {
    MFMessageComposeViewController *smsViewController = [[MFMessageComposeViewController alloc] init];
    smsViewController.messageComposeDelegate = self;
    smsViewController.recipients = [NSArray arrayWithObject:self.phoneNumberField.text];
    smsViewController.body = message;
    [self presentViewController:smsViewController animated:YES completion:nil];
}

- (NSString*) getDefaultTemplateMessage {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Template" inManagedObjectContext:self.appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"isDefault == %@", [NSNumber numberWithBool:YES]];
    [fetchRequest setPredicate:fetchPredicate];
    
    NSError *error;
    NSArray *templates = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (!error) {
        Template *template = [templates objectAtIndex:0];
        return template.message;
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    return nil;
}

#pragma mark - MessageUI protocol
- (void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) displaySuccessMessage {
    UIAlertView *successAlertview = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Contact Saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [successAlertview show];
}

- (void) displayFailedMessage {
    UIAlertView *failedAlertView = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"Sorry, something went wrong" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [failedAlertView show];
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* totalString = [NSString stringWithFormat:@"%@%@",textField.text,string];
    // if it's the phone number textfield format it.
    if(textField.tag==0) {
        if (range.length == 1) {
            // Delete button was hit.. so tell the method to delete the last char.
            textField.text = [Util formatPhoneNumber:totalString deleteLastChar:YES];
        } else {
            textField.text = [Util formatPhoneNumber:totalString deleteLastChar:NO];
        }
        return NO;
    }
    return YES;
}

- (IBAction) defaultSwitchChanged:(id)sender {
    if (self.defaultSwitch.isOn) {
        if ([[self.fetchedResultsController fetchedObjects] count]) {
            if (self.defaultMessage != nil) {
                [[Analytics sharedAnalytics] track:kEventKeyboardToggleDefaultTemplateOn];
                self.messageTextView.text = self.defaultMessage;
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultMessagetIsOn];
            } else {
                [self displayNoDefaultTemplateMessage];
                [self.defaultSwitch setOn:NO];
            }
        } else {
            [self displayNoTemplatesMessage];
            [self.defaultSwitch setOn:NO];
        }
    } else {
        [[Analytics sharedAnalytics] track:kEventKeyboardToggleDefaultTemplateOff];
        self.messageTextView.text = nil;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultMessagetIsOn];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - tableViewController

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView*)tableView {
    
    // Configure the cell ...
    Template *template = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = template.title;
    
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell ...
    [self configureCell:cell atIndexPath:indexPath forTableView:tableView];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Template *template = [_fetchedResultsController objectAtIndexPath:indexPath];
    self.messageTextView.text = template.message;
    [self hideView:self.templatesTableView direction:DIRECTIONLEFT];
    [self showView:self.addContactView];
}


#pragma mark - fetchedResultsController

- (NSFetchedResultsController *) fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:self.searchFetchRequest
                                        managedObjectContext:self.appDelegate.managedObjectContext sectionNameKeyPath:@"title"
                                                   cacheName:nil];
    
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
    
}

- (NSFetchRequest *) searchFetchRequest {
    if (_searchFetchRequest != nil) {
        return _searchFetchRequest;
    }
    
    _searchFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Template" inManagedObjectContext:self.appDelegate.managedObjectContext];
    [_searchFetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [_searchFetchRequest setSortDescriptors:sortDescriptors];
    
    return _searchFetchRequest;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.templatesTableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.templatesTableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath forTableView:tableView];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.templatesTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.templatesTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.templatesTableView endUpdates];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
