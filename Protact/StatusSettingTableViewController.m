//
//  StatusSettingTableViewController.m
//  Protact
//
//  Created by Ryan Lindbeck on 11/12/13.
//  Copyright (c) 2013 Inndevers LLC. All rights reserved.
//

#import "StatusSettingTableViewController.h"
#import "AppDelegate.h"
#import "Constants.h"

@interface StatusSettingTableViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSMutableArray *statuses;

@end

@implementation StatusSettingTableViewController
@synthesize appDelegate, statuses;

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
    self.statuses = [[NSUserDefaults standardUserDefaults] objectForKey:kStatuses];
}

- (IBAction)addNewStatus:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add Status" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.delegate = self;
    [alertView show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1)
        [self saveNewStatus:[alertView textFieldAtIndex:0].text];
}

- (void) saveNewStatus:(NSString*)status {
    [self.statuses addObject:status];
    [[NSUserDefaults standardUserDefaults] setObject:self.statuses forKey:kStatuses];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.statuses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath forTableView:tableView];
    
    return cell;
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView*)tableView {
    
    // Configure the cell ...
    NSString *status = [self.statuses objectAtIndex:indexPath.row];
    cell.textLabel.text = status;
    
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.navigationController popViewControllerAnimated:YES];
    NSString *status = [self.statuses objectAtIndex:indexPath.row];
    NSDictionary *dic = [NSDictionary dictionaryWithObject:status forKey:@"status"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kStatusSelected object:self userInfo:dic];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
