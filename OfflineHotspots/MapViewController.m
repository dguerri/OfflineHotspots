//
//  ViewController.m
//  OfflineHotspots
//
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//  Created by Davide Guerri on 12/01/12.
//  Copyright (c) 2012 __Davide Guerri__. All rights reserved.
//

#import "MapViewController.h"
#import "AppDelegate.h"
#import "RouteMeMapDelegate.h"
#import "AccessPointDetailsController.h"

#pragma mark - Macros

#define cFollowPositionButtonLocationIcon [UIImage imageNamed:@"location.png"]
#define cFollowPositionButtonHeadingIcon  [UIImage imageNamed:@"location_and_heading.png"]

#pragma mark - Private interface

@interface MapViewController()

@property (weak, nonatomic) RouteMeMapDelegate *routeMeMapDelegate; 

- (void)setFollowPositionStatus:(enum userTrackingStatusValues)value;

@end

#pragma mark - Implementation

@implementation MapViewController

#pragma mark - Properties synthetization

@synthesize followPositionButton = _followPositionButton;
@synthesize mapViewContainer = _mapViewContainer;

@synthesize routeMeMapDelegate = _routeMeMapDelegate;

#pragma mark - System methods

- (void)didReceiveMemoryWarning
{
    // Release any cached data, images, etc that aren't in use.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.routeMeMapDelegate = [delegate routeMeMapDelegate];
    
    [self.routeMeMapDelegate.userMarker setUserTrackingStatusDelegate:self];
    [self setFollowPositionStatus:[self.routeMeMapDelegate.userMarker follow]];
    [self.routeMeMapDelegate setAccessPointDetailDelegate:self];
}

- (void)viewDidUnload
{
    [self setMapViewContainer:nil];
    [self setFollowPositionButton:nil];

    [self.routeMeMapDelegate setAccessPointDetailDelegate:nil];
    [self.routeMeMapDelegate.userMarker setUserTrackingStatusDelegate:nil];    
    [self.routeMeMapDelegate setMapViewContainer:nil];
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;

    [self.routeMeMapDelegate setMapViewContainer:self.mapViewContainer];
    [self.routeMeMapDelegate setUserInteractionEnabled:YES];
    [self.routeMeMapDelegate resetMapViewBounds];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.routeMeMapDelegate UIInterfceOrientationChanged:self.interfaceOrientation];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    return [delegate rotationAllowed] && (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.routeMeMapDelegate UIInterfceOrientationChanged:self.interfaceOrientation];
}

- (void)setFollowPositionStatus:(enum userTrackingStatusValues)value
{
    [self.routeMeMapDelegate setFollow:value];
}

- (IBAction)followPositionPressed:(UIBarButtonItem *)sender
{
    switch ([self.routeMeMapDelegate.userMarker follow]) {
        case dontFollowUserLocation:
            [self setFollowPositionStatus:followUserLocation];
            break;
        case followUserLocation:
            [self setFollowPositionStatus:followUserLocationAndHeading];
            break;
        default: //followUserLocationAndHeading
            [self setFollowPositionStatus:dontFollowUserLocation];
            break;
    }
}

#pragma mark - User Tracking Status Delegate

- (void)userTrackingStatusDidChangeToValue:(enum userTrackingStatusValues)value
{
    switch ([self.routeMeMapDelegate.userMarker follow]) {
        case followUserLocationAndHeading:
            [self.followPositionButton setImage:cFollowPositionButtonHeadingIcon];
            [self.followPositionButton setTintColor:[UIColor lightGrayColor]];
            break;
        case followUserLocation:
            [self.followPositionButton setImage:cFollowPositionButtonLocationIcon];
            [self.followPositionButton setTintColor:[UIColor lightGrayColor]];
            break;
        default: //dontFollowUserLocation
            [self.followPositionButton setImage:cFollowPositionButtonLocationIcon];
            [self.followPositionButton setTintColor:[UIColor clearColor]];
            break;
    }
}

#pragma mark - Access Point Detail Delegate

- (void)detailRequestedForAccessPoint:(AccessPoint *)accessPoint
{
    [self performSegueWithIdentifier:@"accessPointDetailsFromMapSegue" sender:accessPoint];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"accessPointDetailsFromMapSegue"])
    {
        // Get reference to the destination view controller
        AccessPointDetailsController *accessPointDetailsController = [segue destinationViewController];
        AccessPoint *accessPoint = (AccessPoint *)sender;
        
        [accessPointDetailsController setAccessPoint:accessPoint];        
    }
}

@end
