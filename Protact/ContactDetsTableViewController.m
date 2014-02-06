//
//  ContactDetsTableViewController.m
//  Protact
//
//  Created by Ryan Lindbeck on 1/8/14.
//  Copyright (c) 2014 Inndevers LLC. All rights reserved.
//

#import "ContactDetsTableViewController.h"
#import <MessageUI/MessageUI.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MapKit/MapKit.h>
#import "AppDelegate.h"
#import "ContactManager.h"
#import "Util.h"
#import "Constants.h"

@interface ContactDetsTableViewController () <MFMessageComposeViewControllerDelegate, UITextFieldDelegate, UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate, UITextViewDelegate, UIAlertViewDelegate, MKMapViewDelegate>
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (strong, nonatomic) UITextField *textFieldFirstName;
@property (strong, nonatomic) UITextField *textFieldLastName;
@property (strong, nonatomic) UITextField *textFieldNumber;
@property (strong, nonatomic) UILabel *labelStatus;
@property (strong, nonatomic) UILabel *labelVenue;
@property (strong, nonatomic) UILabel *labelDateCreated;
@property (strong, nonatomic) UISlider *looksSlider;
@property (strong, nonatomic) UISlider *personalitySlider;
@property (strong, nonatomic) UITextView *notesTextView;
@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) UIToolbar *keyboardToolBar;
@property BOOL contactIsNew;

- (void) displayAddressBook;
- (IBAction) sliderValueChanged:(UISlider *)sender;

@end

@implementation ContactDetsTableViewController
@synthesize contact, textFieldFirstName, textFieldLastName, textFieldNumber, appDelegate, contactIsNew, labelStatus, labelVenue, labelDateCreated;
@synthesize looksSlider, personalitySlider, notesTextView, mapView;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(venueSelected:) name:kVenueSelected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusSelected:) name:kStatusSelected object:nil];
    
    [self initControls];
    
    self.contactIsNew = NO;
    if (self.contact == nil) {
        self.contactIsNew = YES;
        [self.textFieldFirstName becomeFirstResponder];
        self.contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.appDelegate.managedObjectContext];
        self.contact.createdDate = [NSDate date];
        self.contact.latitude = [NSNumber numberWithFloat:appDelegate.currentLocation.coordinate.latitude];
        self.contact.longitude = [NSNumber numberWithFloat:appDelegate.currentLocation.coordinate.longitude];
    }
}

/*
- (void) viewDidAppear:(BOOL)animated {
    //contactIsNew = NO;
    if (self.contact == nil) {
        //self.contactIsNew = YES;
        [self.textFieldFirstName becomeFirstResponder];
        self.contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.appDelegate.managedObjectContext];
        self.contact.createdDate = [NSDate date];
        self.contact.latitude = [NSNumber numberWithFloat:appDelegate.currentLocation.coordinate.latitude];
        self.contact.longitude = [NSNumber numberWithFloat:appDelegate.currentLocation.coordinate.longitude];
    }
}
*/
- (void) initControls {

    self.textFieldFirstName = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 280, 30)];
    self.textFieldLastName = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 280, 30)];
    self.textFieldNumber = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 280, 30)];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(10, 10, 300, 100)];
    self.notesTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, 200, 200)];
    self.notesTextView.font = [UIFont fontWithName:@"Arial" size:14.0];
    
    self.keyboardToolBar = [[UIToolbar alloc] init];
    [self.keyboardToolBar sizeToFit];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(keyboardDoneButtonPressed)];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.keyboardToolBar setItems:[NSArray arrayWithObjects:flexBarButton, doneBarButton, nil]];
    
    self.textFieldFirstName.inputAccessoryView = self.keyboardToolBar;
    self.textFieldLastName.inputAccessoryView = self.keyboardToolBar;
    self.textFieldNumber.inputAccessoryView = self.keyboardToolBar;
    self.notesTextView.inputAccessoryView = self.keyboardToolBar;
    
    self.textFieldFirstName.placeholder = @"First Name";
    self.textFieldFirstName.borderStyle = UITextBorderStyleNone;
    self.textFieldFirstName.delegate = self;
    
    self.textFieldLastName.placeholder = @"Last Name";
    self.textFieldLastName.borderStyle = UITextBorderStyleNone;
    self.textFieldLastName.delegate = self;
    
    self.textFieldNumber.placeholder = @"Number";
    self.textFieldNumber.borderStyle = UITextBorderStyleNone;
    self.textFieldNumber.delegate = self;
    
    
    
    

}

- (void) keyboardDoneButtonPressed {
    
    [self.textFieldFirstName resignFirstResponder];
    [self.textFieldLastName resignFirstResponder];
    [self.textFieldNumber resignFirstResponder];
    [self.notesTextView resignFirstResponder];
    
}

- (void) mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    [self centerMapView];
}

- (void) centerMapView {
    
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = 0.008; //0.1162;
    span.longitudeDelta = 0.008; //0.1160;
    
    CLLocationCoordinate2D location;
    
    if (self.contactIsNew) {
        
        location.latitude = self.appDelegate.currentLocation.coordinate.latitude;
        location.longitude = self.appDelegate.currentLocation.coordinate.longitude;
        
    } else {
        
        location.latitude = [self.contact.latitude floatValue];    // 65.494806;
        location.longitude = [self.contact.longitude floatValue];  // -23.577569;
        
    }
    
    region.span = span;
    region.center = CLLocationCoordinate2DMake(location.latitude - (span.latitudeDelta/5.0),location.longitude);
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = location;
    
    [self.mapView addAnnotation:annotation];
    [self.mapView setRegion:region animated:YES];
    [self.mapView regionThatFits:region];
}

#pragma mark - UITextField Delegate

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString* totalString = [NSString stringWithFormat:@"%@%@",textField.text,string];
    
    // if it's the phone number textfield format it.
    if(textField.tag==2) {
        
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

- (void) textFieldDidEndEditing:(UITextField *)textField {
    
    if (textField == self.textFieldFirstName) {
        
        self.contact.firstName = self.textFieldFirstName.text;
    }
    
    if (textField == self.textFieldLastName) {
        
        self.contact.lastName = self.textFieldLastName.text;
    }
    
    if (textField == self.textFieldNumber) {
        
        self.contact.number = self.textFieldNumber.text;
        
    }
}

- (void) setContactMainInfo {
    
    if (self.textFieldFirstName.text != nil) {
        
        self.contact.firstName = self.textFieldFirstName.text;
        
    }
    
    if (self.textFieldLastName.text != nil) {
        
        self.contact.lastName = self.textFieldLastName.text;
        
    }
    
    if (self.textFieldNumber.text != nil) {
        self.contact.number = self.textFieldNumber.text;
    }
    
}

- (void) removeContact {
    ContactManager *cm = [[ContactManager alloc] initWithContact:self.contact];
    if ([cm remove]) {
        NSLog(@"Contact deleted");
    } else {
        NSLog(@"Contact failed to delete");
    }
}

#pragma mark - UITextView Delegate

- (void) textViewDidChange:(UITextView *)textView {
    self.contact.notes = self.notesTextView.text;
}

- (IBAction) sliderValueChanged:(UISlider *)sender {
    
    int value = (int)sender.value;
    
    if (sender == self.looksSlider) {
        self.contact.looks = [NSNumber numberWithInt:value];
    }
    
    if (sender == self.personalitySlider) {
        self.contact.personality = [NSNumber numberWithInt:value];
    }
}

- (IBAction) saveButtonPressed:(id)sender {
    
    [self setContactMainInfo];
    
    ContactManager *cm = [[ContactManager alloc] initWithContact:self.contact];
    
    if ([cm save]) {
        
        [self displaySuccessMessage];
        
    } else {
        
        [self displayFailedMessage];
        
    }
    
}

- (void) venueSelected:(NSNotification*)notification {
    
    NSString *venueName = [[notification userInfo] objectForKey:@"venueName"];
    
    self.contact.venue = venueName;
    
    [self.tableView reloadData];
    
}

- (void) statusSelected:(NSNotification*)notification {
    
    NSLog(@"Received Status");
    
    NSString *status = [[notification userInfo] objectForKey:@"status"];
    
    self.contact.status = status;
    
    [self.tableView reloadData];
    
}

- (void) displaySuccessMessage {
    UIAlertView *successAlertview = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Contact Saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [successAlertview show];
}

- (void) displayFailedMessage {
    UIAlertView *failedAlertView = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"Sorry, something went wrong" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [failedAlertView show];
}

- (void) displayMessageUIWithRecipients:(NSArray*)recipients andBody:(NSString*)body {
    MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
    messageComposer.messageComposeDelegate = self;
    messageComposer.recipients = recipients;
    [self presentViewController:messageComposer animated:YES completion:nil];
}

#pragma mark - MessageUI protocol
- (void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) displayAddressBook {
    
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
    
}

#pragma mark - AddressBookUI protocol
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    
    NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
    
    ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, 0);
    CFRelease(multiPhones);
    NSString *phoneNumber = (__bridge NSString *) phoneNumberRef;
    
    NSLog(@"%@", firstName);
    NSLog(@"%@", lastName);
    NSLog(@"%@", phoneNumber);
    NSLog(@"%d", ABRecordGetRecordID(person));
    
    self.contact.firstName = firstName;
    self.contact.lastName = lastName;
    self.contact.number = phoneNumber;
    
    ABRecordID recId = ABRecordGetRecordID(person);
    self.contact.abRecId = [NSNumber numberWithInt:(int)recId];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    return NO;
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
   
    NSString *title;
    
    switch (section) {
            
        case 0: // Send Text
            title = @"SMS";
            break;
            
        case 1: // Contact Info
            title = @"Contact Info";
            break;
            
        case 2: // Status
            title = @"Status";
            break;
            
        case 3: // Location
            title = @"Location";
            break;
            
        case 4: // Notes
            title = @"Notes";
            break;
            
        case 5: // Date Created
            title = @"Date Created";
            break;
            
        case 6: // Deleted
            title = @"Delete";
            break;
            
        default:
            break;
    }
    
    return title;
   
}

- (float) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    float height = 0;
    
    switch (indexPath.section) {
        
        case 0: // Send Text
            height = 44;
            break;
            
        case 1: // Contact Info
            height = 44;
            break;
            
        case 2: // Status
            height = 44;
            break;
            
        case 3: // Location
            if (indexPath.row == 0) {
                height = 44;
            } else if (indexPath.row == 1) {
                height = 120;
            }
            break;
            
        case 4: // Notes
            height = 88;
            break;
            
        case 5: // Date Created
            height = 44;
            break;
            
        case 6: // Deleted
            height = 44;
            break;
            
        default:
            break;
    }
    
    return height;
    
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numOfSections = 0;
    
    switch (section) {
        case 0:
            numOfSections = 1; // Send Text / Import Contact
            break;
            
        case 1:
            numOfSections = 3; // Contact Info
            break;
            
        case 2:
            numOfSections = 1; // Status
            break;
            
        case 3:
            numOfSections = 2; // Location
            break;
            
        case 4:
            numOfSections = 1; // Notes
            break;
            
        case 5:
            numOfSections = 1; // Date Created
            break;
            
        case 6:
            numOfSections = 1; // Delete
            break;
            
        default:
            break;
    }
    
    return numOfSections;
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView*)tableView {
    
    // Configure the cell ...
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (indexPath.section) {
        
        case 0: // Send Text
        {
            if (self.contactIsNew)
                cell.textLabel.text = @"Import From Address Book";
            else
                cell.textLabel.text = @"Send Text Message";
            cell.backgroundColor = [UIColor colorWithRed:152.0f/255.0f green:227.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        }
        break;
            
        case 1: // Contact Info
            if (indexPath.row == 0) {
                if (![self.textFieldFirstName isDescendantOfView:cell]) {
                    [cell addSubview:self.textFieldFirstName];
                }
            }
            if (indexPath.row == 1) {
                if (![self.textFieldLastName isDescendantOfView:cell]) {
                    [cell addSubview:self.textFieldLastName];
                }
            }
            if (indexPath.row == 2) {
                if (![self.textFieldNumber isDescendantOfView:cell]) {
                    [cell addSubview:self.textFieldNumber];
                }
            }
            self.textFieldFirstName.text = contact.firstName;
            self.textFieldLastName.text = contact.lastName;
            self.textFieldNumber.text = contact.number;
            break;
            
        case 2: // Status
            cell.textLabel.text = contact.status;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case 3: // Location
            if (indexPath.row == 0) {
                cell.textLabel.text = contact.venue;
            }
            if (indexPath.row == 1) {
                if (![self.mapView isDescendantOfView:cell]) {
                    [cell addSubview:self.mapView];
                }
            }
            break;
            
        case 4: // Notes
            if (![self.notesTextView isDescendantOfView:cell]) {
                [cell addSubview:self.notesTextView];
            }
            self.notesTextView.text = contact.notes;
            break;
            
        case 5: // Date Created
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterLongStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            cell.textLabel.text = [dateFormatter stringFromDate:self.contact.createdDate];
        }
            break;
            
        case 6: // Delete
        {
            cell.textLabel.text = @"Delete";
            cell.backgroundColor = [UIColor colorWithRed:252.0f/255.0f green:69.0f/255.0f blue:78.0f/255.0f alpha:1.0f];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        }
            break;
            
        default:
            break;
    }
    
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
    
    switch (indexPath.section) {
        case 0:
            if (self.contactIsNew)
                [self displayAddressBook];
            else
                [self displayMessageUIWithRecipients:[NSArray arrayWithObject:self.contact.number] andBody:nil];
            break;
            
        case 1:
            
            break;
            
        case 7: // Delete Contact
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Delete this contact?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [alertView show];
        }
            break;
            
        default:
            break;
    }
    
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self removeContact];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
