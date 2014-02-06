//
//  ContactsTableViewController.m
//  Protact
//
//  Created by Ryan Lindbeck on 11/8/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "ContactsTableViewController.h"
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "ContactDetailsTableViewController.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "JPSThumbnailAnnotation.h"

@interface ContactsTableViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate, MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet UISegmentedControl *sortBySegmentControl;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (nonatomic, strong) AppDelegate *appDelegate;

@property (nonatomic, strong) NSFetchRequest *searchFetchRequest;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (IBAction) sortByChanged:(id)sender;

@end

@implementation ContactsTableViewController
@synthesize appDelegate, filteredContacts, sortBySegmentControl, mapView;
@synthesize searchFetchRequest = _searchFetchRequest;
@synthesize fetchedResultsController = _fetchedResultsController;

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
    [self.view addSubview:self.mapView];
    [self.searchDisplayController.searchResultsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self loadContacts];
}

- (void) viewDidAppear:(BOOL)animated {
    [[Analytics sharedAnalytics] screen:kViewProtacts];
}

- (void) loadContacts {
    NSError *error;
    //self.fetchedResultsController = nil;
    //self.searchFetchRequest = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
}

- (IBAction) sortByChanged:(id)sender {
    if (self.sortBySegmentControl.selectedSegmentIndex == 1) {
        [[Analytics sharedAnalytics] screen:kViewProtactsMap];
        self.mapView.hidden = NO;
        [self.tableView bringSubviewToFront:self.mapView];
        [self.mapView addAnnotations:[self generateAnnotations]];
        //[self zoomInMapView];
    } else {
        self.mapView.hidden = YES;
    }
}

- (NSArray *)generateAnnotations {
    NSMutableArray *annotations = [[NSMutableArray alloc] init];
    NSArray *fetchedContacts = [self.fetchedResultsController fetchedObjects];
    for (Contact *contact in fetchedContacts) {
        JPSThumbnail *jpsContact = [[JPSThumbnail alloc] init];
        jpsContact.contact = contact;
        jpsContact.image = [UIImage imageNamed:@"protact-avatar"];
        jpsContact.title = contact.name;
        jpsContact.subtitle = contact.venue;
        jpsContact.coordinate = CLLocationCoordinate2DMake([contact.latitude floatValue], [contact.longitude floatValue]);
        jpsContact.disclosureBlock = ^{ [self pushToContactDetails:jpsContact.contact]; };
        [annotations addObject:[[JPSThumbnailAnnotation alloc] initWithThumbnail:jpsContact]];
    }
    
    return annotations;
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view conformsToProtocol:@protocol(JPSThumbnailAnnotationViewProtocol)]) {
        [((NSObject<JPSThumbnailAnnotationViewProtocol> *)view) didSelectAnnotationViewInMap:mapView];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view conformsToProtocol:@protocol(JPSThumbnailAnnotationViewProtocol)]) {
        [((NSObject<JPSThumbnailAnnotationViewProtocol> *)view) didDeselectAnnotationViewInMap:mapView];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation conformsToProtocol:@protocol(JPSThumbnailAnnotationProtocol)]) {
        return [((NSObject<JPSThumbnailAnnotationProtocol> *)annotation) annotationViewInMap:mapView];
    }
    return nil;
}

- (void) zoomInMapView {
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.1162;
    span.longitudeDelta = 0.1160;
    CLLocationCoordinate2D location;
    
    if (self.appDelegate.currentLocation == nil) {
        location.latitude = 38.617759;
        location.longitude = -90.210114;
    } else {
        location.latitude = self.appDelegate.currentLocation.coordinate.latitude;
        location.longitude = self.appDelegate.currentLocation.coordinate.longitude;
    }
    
    region.span = span;
    region.center = CLLocationCoordinate2DMake(location.latitude - (span.latitudeDelta/5.0),location.longitude);
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView regionThatFits:region];
}

- (void) searchForText:(NSString *)searchText
{
    if (self.appDelegate.managedObjectContext)
    {
        NSString *predicateFormat = @"%K BEGINSWITH[cd] %@";
        NSString *searchAttribute = @"lastName";
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchAttribute, [searchText uppercaseString]];
        [self.searchFetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        self.filteredContacts = [self.appDelegate.managedObjectContext executeFetchRequest:self.searchFetchRequest error:&error];
    }
}


#pragma mark - Search Display Controller delegate

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self searchForText:searchString];
    return YES;
}

- (void) searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.rowHeight = 64;
}


- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    NSString *searchString = controller.searchBar.text;
    [self searchForText:searchString];
    return YES;
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.tableView)
    {
        return [[self.fetchedResultsController sections] count];
    }
    else
    {
        return 1;
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView)
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
    else
    {
        return [self.filteredContacts count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (tableView == self.tableView)
    {
        if (index > 0)
        {
            return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index-1];
        }
        else
        {
            self.tableView.contentOffset = CGPointZero;
            return NSNotFound;
        }
    }
    else
    {
        return 0;
    }
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == self.tableView && self.sortBySegmentControl.selectedSegmentIndex == 1)
    {
        NSMutableArray *index = [NSMutableArray arrayWithObject:UITableViewIndexSearch];
        NSArray *initials = [self.fetchedResultsController sectionIndexTitles];
        [index addObjectsFromArray:initials];
        return index;
    }
    else
    {
        return nil;
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (tableView == self.tableView && self.sortBySegmentControl.selectedSegmentIndex == 1)
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo indexTitle];
    }
    
    return nil;
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView*)tableView {
    
    // Configure the cell ...
    Contact *contact;
    if (tableView == self.tableView)
    {
        contact = [_fetchedResultsController objectAtIndexPath:indexPath];
    }
    else
    {
        contact = [self.filteredContacts objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = contact.name;
    
    if (self.sortBySegmentControl.selectedSegmentIndex == 0) {
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        cell.detailTextLabel.text = [dateFormatter stringFromDate:contact.createdDate];
    
    } else {
        
        cell.detailTextLabel.text = nil;
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
    
    Contact *contact;
    if (tableView == self.tableView)
    {
        contact = [_fetchedResultsController objectAtIndexPath:indexPath];
    }
    else
    {
        contact = [self.filteredContacts objectAtIndex:indexPath.row];
    }
    
    [self pushToContactDetails:contact];
}

- (void) pushToContactDetails:(Contact*)contact {
    ContactDetailsTableViewController *contactDetails = [self.storyboard instantiateViewControllerWithIdentifier:@"contactDetails"];
    [contactDetails setContact:contact];
    [self.navigationController pushViewController:contactDetails animated:YES];
}

#pragma mark - fetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
    
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
     
    NSFetchedResultsController *theFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.searchFetchRequest
                                                                                                  managedObjectContext:self.appDelegate.managedObjectContext sectionNameKeyPath:nil
                                                                                                             cacheName:nil];
    
    /*
    if (self.sortBySegmentControl.selectedSegmentIndex == 0) {
        
        theFetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:self.searchFetchRequest
                                            managedObjectContext:self.appDelegate.managedObjectContext sectionNameKeyPath:nil
                                                       cacheName:nil];
        
    } else {
        
        theFetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:self.searchFetchRequest
                                            managedObjectContext:self.appDelegate.managedObjectContext sectionNameKeyPath:@"nameInitial"
                                                       cacheName:nil];
    }
    */
    
    
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
    
}

- (NSFetchRequest *) searchFetchRequest {
    
    if (_searchFetchRequest != nil) {
        return _searchFetchRequest;
    }
    
    _searchFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:self.appDelegate.managedObjectContext];
    [_searchFetchRequest setEntity:entity];
    
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:NO];
    
    /*
    if (self.sortBySegmentControl.selectedSegmentIndex == 0) {
        
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:NO];
        
    } else {
        
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    }
     */
    
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [_searchFetchRequest setSortDescriptors:sortDescriptors];
    
    return _searchFetchRequest;
    
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
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
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
