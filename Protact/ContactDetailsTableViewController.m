//
//  ContactDetailsTableViewController.m
//  Protact
//
//  Created by Ryan Lindbeck on 11/8/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "ContactDetailsTableViewController.h"
#import <MessageUI/MessageUI.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MapKit/MapKit.h>
#import "AppDelegate.h"
#import "ContactManager.h"
#import "Util.h"
#import "Constants.h"
#import "VenuesTablesViewController.h"

@interface ContactDetailsTableViewController () <MFMessageComposeViewControllerDelegate, UITextFieldDelegate, UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate, UITextViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (weak, nonatomic) IBOutlet UITextField *textFieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLastName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
@property (weak, nonatomic) IBOutlet UILabel *labelVenue;
@property (weak, nonatomic) IBOutlet UILabel *labelDateCreated;
@property (weak, nonatomic) IBOutlet UILabel *labelTopAction;
@property (weak, nonatomic) IBOutlet UISlider *looksSlider;
@property (weak, nonatomic) IBOutlet UISlider *personalitySlider;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) UIToolbar *keyboardToolBar;
@property (weak, nonatomic) IBOutlet UIButton *buttonCall;
@property (weak, nonatomic) IBOutlet UIButton *buttonText;
@property (weak, nonatomic) IBOutlet UIButton *buttonImport;
@property ABRecordID importedRecId;

- (void) displayAddressBook;
- (IBAction) callButtonPressed:(id)sender;
- (IBAction) textButtonPressed:(id)sender;
- (IBAction) importButtonPressed:(id)sender;

@end

@implementation ContactDetailsTableViewController
@synthesize contact, textFieldFirstName, textFieldLastName, textFieldNumber, appDelegate, labelStatus, labelVenue, labelDateCreated, importedRecId;
@synthesize looksSlider, personalitySlider, notesTextView, mapView;
@synthesize buttonCall, buttonText, buttonImport;

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
    
    self.keyboardToolBar = [[UIToolbar alloc] init];
    [self.keyboardToolBar sizeToFit];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(keyboardDoneButtonPressed)];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.keyboardToolBar setItems:[NSArray arrayWithObjects:flexBarButton, doneBarButton, nil]];
    
    self.textFieldFirstName.inputAccessoryView = self.keyboardToolBar;
    self.textFieldLastName.inputAccessoryView = self.keyboardToolBar;
    self.textFieldNumber.inputAccessoryView = self.keyboardToolBar;
    self.notesTextView.inputAccessoryView = self.keyboardToolBar;
    
    if (self.contact != nil) {
        [self populateFieldsWithContactInfo];
        self.buttonImport.hidden = YES;
        self.buttonCall.hidden = NO;
        self.buttonText.hidden = NO;
    } else {
        [self.textFieldFirstName becomeFirstResponder];
        self.buttonImport.hidden = NO;
        self.buttonCall.hidden = YES;
        self.buttonText.hidden = YES;
    }
    
    NSLog(@"contact: %@", self.contact);
    
}

- (void) viewDidAppear:(BOOL)animated {
    [[Analytics sharedAnalytics] screen:kViewProtactDetails];
    [self centerMapView];
}

- (void) keyboardDoneButtonPressed {
    [self.textFieldFirstName resignFirstResponder];
    [self.textFieldLastName resignFirstResponder];
    [self.textFieldNumber resignFirstResponder];
    [self.notesTextView resignFirstResponder];
}

- (void) populateFieldsWithContactInfo {
    
    self.labelTopAction.text = @"Send Text Message";
    
    self.textFieldFirstName.text = self.contact.firstName;
    self.textFieldLastName.text = self.contact.lastName;
    self.textFieldNumber.text = self.contact.number;
    
    self.labelStatus.text = self.contact.status;
    self.labelVenue.text = self.contact.venue;
    self.notesTextView.text = self.contact.notes;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    labelDateCreated.text = [dateFormatter stringFromDate:self.contact.createdDate];
    
}

- (void) centerMapView {
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.008; //0.1162;
    span.longitudeDelta = 0.008; //0.1160;
    CLLocationCoordinate2D location;
    
    if (self.contact == nil) {
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
    if (textField == self.textFieldFirstName)
        self.contact.firstName = self.textFieldFirstName.text;
    
    if (textField == self.textFieldLastName)
        self.contact.lastName = self.textFieldLastName.text;
    
    if (textField == self.textFieldNumber)
        self.contact.number = self.textFieldNumber.text;
}

- (void) setContactInfo {
    
    if (self.contact == nil)
        self.contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.appDelegate.managedObjectContext];
    
    if (self.textFieldFirstName.text != nil)
        self.contact.firstName = self.textFieldFirstName.text;
    
    if (self.textFieldLastName.text != nil)
        self.contact.lastName = self.textFieldLastName.text;
    
    if (self.textFieldNumber.text != nil)
        self.contact.number = self.textFieldNumber.text;
    
    if (self.notesTextView.text != nil)
        self.contact.notes = self.notesTextView.text;
    
    if (self.labelStatus.text != nil)
        self.contact.status = self.labelStatus.text;
    
    if (self.labelVenue.text != nil)
        self.contact.venue = self.labelVenue.text;
    
    if (self.contact.createdDate == nil)
        self.contact.createdDate = [NSDate date];
    
    if (self.contact.latitude == nil)
        self.contact.latitude = [NSNumber numberWithFloat:appDelegate.currentLocation.coordinate.latitude];
    
    if (self.contact.longitude == nil)
        self.contact.longitude = [NSNumber numberWithFloat:appDelegate.currentLocation.coordinate.longitude];
    
    if (self.importedRecId)
        self.contact.abRecId = [NSNumber numberWithInt:(int)self.importedRecId];
        
    
}

- (IBAction) saveButtonPressed:(id)sender {
    [self setContactInfo];
    ContactManager *cm = [[ContactManager alloc] initWithContact:self.contact];
    
    if ([cm save]) {
        self.buttonImport.hidden = YES;
        self.buttonCall.hidden = NO;
        self.buttonText.hidden = NO;
        [self populateFieldsWithContactInfo];
        [self displaySuccessMessage];
    }
    else
        [self displayFailedMessage];
}

- (IBAction) callButtonPressed:(id)sender {
    NSString *rawNumber = [Util replaceFormatCharsInPhoneNumber:self.contact.number];
    NSString *telString = [NSString stringWithFormat:@"tel:%@", rawNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:telString]];
}

- (IBAction) textButtonPressed:(id)sender {
    [self displayMessageUIWithRecipients:[NSArray arrayWithObject:self.contact.number] andBody:nil];
}

- (IBAction) importButtonPressed:(id)sender {
    [self displayAddressBook];
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

- (void) venueSelected:(NSNotification*)notification {
    NSString *venueName = [[notification userInfo] objectForKey:@"venueName"];
    self.labelVenue.text = venueName;
    
}

- (void) statusSelected: (NSNotification*) notification {
    NSString *status = [[notification userInfo] objectForKey:@"status"];
    self.labelStatus.text = status;
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
    
    self.textFieldFirstName.text = firstName;
    self.textFieldLastName.text = lastName;
    self.textFieldNumber.text = phoneNumber;
    
    ABRecordID recId = ABRecordGetRecordID(person);
    self.importedRecId = recId;

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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 3:
            if (indexPath.row == 0) {
                VenuesTablesViewController *venuesTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"venues"];
                if (self.contact == nil) {
                    venuesTableViewController.latitude = self.appDelegate.currentLocation.coordinate.latitude;
                    venuesTableViewController.longitude = self.appDelegate.currentLocation.coordinate.longitude;
                } else {
                    NSLog(@"Contact Latitude: %f", [self.contact.latitude floatValue]);
                    NSLog(@"Contact Longitude: %f", [self.contact.longitude floatValue]);
                    venuesTableViewController.latitude = [self.contact.latitude floatValue];
                    venuesTableViewController.longitude = [self.contact.longitude floatValue];
                }
                [self.navigationController pushViewController:venuesTableViewController animated:YES];
            }
            break;
        case 6: // Delete Contact
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
