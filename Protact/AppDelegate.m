//
//  AppDelegate.m
//  Protact
//
//  Created by Ryan Lindbeck on 11/7/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "AppDelegate.h"
#import <AddressBook/AddressBook.h>
#import "Constants.h"

@implementation AppDelegate
@synthesize locationManager, currentLocation;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self prePopulateStatuses];
    [self checkAndSetFirstOpen];
    [self initLocationManager];
    [self addressBookRequestAccess];
    
    //[Analytics debug:YES];
    [Analytics initializeWithSecret:kSegmentWriteKey];
    [Appsee start:kAppSeeAppKey];
    
    return YES;
    
}

- (void) checkAndSetFirstOpen {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kFirstOpen]) {
        [defaults setBool:YES forKey:kFirstOpen];
        [defaults synchronize];
    }
}

- (BOOL) appHasOpenedBefore {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kFirstOpen])
        return YES;
    
    return NO;
}

- (void) prePopulateStatuses {
    NSArray *statuses = [NSArray arrayWithObjects:@"New", @"Follow Up", @"In Pursuit", @"Pending", @"Closed", nil];
    if (![self appHasOpenedBefore]) {
        NSLog(@"prePopulateStatuses");
        [[NSUserDefaults standardUserDefaults] setObject:statuses forKey:kStatuses];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) initLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyKilometer];
    [self.locationManager setDistanceFilter:500];
    [self.locationManager startUpdatingLocation];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Location: %@", locations);
    NSLog(@"Lat: %f", manager.location.coordinate.latitude);
    NSLog(@"Lat: %f", manager.location.coordinate.longitude);
    self.currentLocation = manager.location;
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location Manager Failed: %@", error);
}

- (void) addressBookRequestAccess {
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            // First time access has been granted, add the contact
            NSLog(@"Address Book Access Granted? %d", granted);
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        NSLog(@"Address Book Access Granted.");
    } else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
        NSLog(@"Address Book Access Denied.");
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Protacts.sqlite"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        //Replace this implementation with code to handle the error appropriately.
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    UIViewController* root = _window.rootViewController;
    UITabBarController* tabBarController = (UITabBarController*)root;
    
    [tabBarController setSelectedIndex:2];
    
    UINavigationController *navController = (UINavigationController*)[tabBarController.viewControllers objectAtIndex:2];
    
    [navController popToRootViewControllerAnimated:NO];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
