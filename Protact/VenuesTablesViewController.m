//
//  VenuesTablesViewController.m
//  FRManagement
//
//  Created by Ryan Lindbeck on 9/2/13.
//  Copyright (c) 2013 Inndevers. All rights reserved.
//

#import "VenuesTablesViewController.h"
#import "AppDelegate.h"
#import "Constants.h"

@interface VenuesTablesViewController ()
@property (nonatomic, strong) NSArray *venues;

@end

@implementation VenuesTablesViewController
@synthesize venues;
@synthesize latitude, longitude;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"lat: %f", self.latitude);
    NSLog(@"long: %f", self.longitude);
    
}

- (void) viewDidAppear:(BOOL)animated {
    [[Analytics sharedAnalytics] screen:kViewVenues];
    [self requestNearbyVenues];
}

- (void) requestNearbyVenues {
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSString *strUrl = [NSString stringWithFormat:@"%@?ll=%f,%f&client_id=%@&client_secret=%@&v=20130804", kFoursquareVenuesSearchUrl, self.latitude, self.longitude, kFoursquareClientId, kFoursquareClientSecret];
    
    NSLog(@"%@", strUrl);
    
    NSURL *url = [NSURL URLWithString:strUrl];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"JSON: %@", JSON);
        
        NSDictionary *jsonDict = (NSDictionary *) JSON;
        NSDictionary *fsReponse = [jsonDict objectForKey:@"response"];
        NSArray *fsResponseVenues = [fsReponse objectForKey:@"venues"];
        
        self.venues = fsResponseVenues;
        
        [self.tableView reloadData];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        if(error) {
            
            NSLog(@"fs error: %@", [error localizedDescription]);
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    }];
    
    [operation start];
    
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.venues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    cell.textLabel.text = [[self.venues objectAtIndex:indexPath.row] objectForKey:@"name"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController popViewControllerAnimated:YES];
    
    NSString *venueName = [[self.venues objectAtIndex:indexPath.row] objectForKey:@"name"];
    
    NSDictionary *dic = [NSDictionary dictionaryWithObject:venueName forKey:@"venueName"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kVenueSelected object:self userInfo:dic];
}

@end
