//
//  MageSplitViewController.m
//  MAGE
//
//  Created by William Newman on 9/15/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageSplitViewController.h"
#import "UserUtility.h"
#import "HttpManager.h"
#import "MapViewController_iPad.h"
#import "MageTabBarController.h"
#import "ObservationTableViewController.h"
#import "PeopleTableViewController.h"
#import "MapCalloutTappedSegueDelegate.h"

@interface MageSplitViewController () <MapCalloutTapped>
    @property(nonatomic, weak) MageTabBarController *tabBarController;
    @property(nonatomic, weak) MapViewController_iPad *mapViewController;
    @property(nonatomic, weak) UIBarButtonItem *masterViewButton;
    @property(nonatomic, weak) UIPopoverController *masterViewPopover;
    @property(nonatomic, strong) NSArray *mapCalloutDelegates;
@end

@implementation MageSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startServices];
    
    self.delegate = self;
    
    UINavigationController *masterViewController = [self.viewControllers firstObject];
    self.mapViewController = [self.viewControllers lastObject];
    self.tabBarController = (MageTabBarController *) [masterViewController topViewController];
    
    self.mapViewController.mapDelegate.mapCalloutDelegate = self;
    
    ObservationTableViewController *observationTableViewController = (ObservationTableViewController *) [self.tabBarController.viewControllers objectAtIndex:0];
    observationTableViewController.observationDataStore.observationSelectionDelegate = self.mapViewController.mapDelegate;
    
    PeopleTableViewController *peopleTableViewController = (PeopleTableViewController *) [self.tabBarController.viewControllers objectAtIndex:1];
    peopleTableViewController.peopleDataStore.personSelectionDelegate = self.mapViewController.mapDelegate;

    UITabBarItem *observationsTabBar = [[[self.tabBarController tabBar] items] objectAtIndex:0];
    [observationsTabBar setSelectedImage:[UIImage imageNamed:@"observations_selected.png"]];
    
    UITabBarItem *peopleTabBar = [[[self.tabBarController tabBar] items] objectAtIndex:1];
    [peopleTabBar setSelectedImage:[UIImage imageNamed:@"people_selected.png"]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startServices {
    _locationService = [[LocationService alloc] initWithManagedObjectContext:self.contextHolder.managedObjectContext];
    [_locationService start];
    
    NSOperation *usersPullOp = [User operationToFetchUsersWithManagedObjectContext:self.contextHolder.managedObjectContext];
    NSOperation *startLocationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the location fetch service");
        [self.fetchServicesHolder.locationFetchService start];
    }];
    
    NSOperation *startObservationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the observation fetch service");
        [self.fetchServicesHolder.observationFetchService start];
    }];
    
    [startObservationFetchOp addDependency:usersPullOp];
    [startLocationFetchOp addDependency:usersPullOp];
    
    // Add the operations to the queue
    [[HttpManager singleton].manager.operationQueue addOperations:@[usersPullOp, startObservationFetchOp, startLocationFetchOp] waitUntilFinished:NO];
}

-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self.tabBarController.userMapCalloutTappedDelegate calloutTapped:calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self.tabBarController.observationMapCalloutTappedDelegate calloutTapped:calloutItem];
    }
    
    if (self.masterViewButton && self.masterViewPopover) {
        [self.masterViewPopover presentPopoverFromBarButtonItem:self.masterViewButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

-(void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *) button {
    self.masterViewButton = nil;
    self.masterViewPopover = nil;
    
    NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
    [items removeObject:button];
    [self.mapViewController.toolbar setItems:items];
}


-(void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)button forPopoverController:(UIPopoverController *) pc {
    self.masterViewButton = button;
    self.masterViewPopover = pc;
    
    button.image = [UIImage imageNamed:@"bars"];
    
    NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
    if (!items) {
        items = [NSMutableArray arrayWithObject:button];
    } else {
        [items insertObject:button atIndex:0];
    }
    
    [self.mapViewController.toolbar setItems:items];
}

@end