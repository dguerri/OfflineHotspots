//
//  SettingsViewController.m
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

#import "SettingsViewController.h"
#import "AppDelegate.h"

#pragma make - Macros

#define cResetToFactoryAVTag 1
#define cUpdateAVTag 2

#pragma mark - Implementation

@implementation SettingsViewController

@synthesize blockRotation;

#pragma mark - Constructors

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - ...

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 }
 */

- (void)viewDidUnload
{
    [self setBlockRotation:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [blockRotation setOn:![delegate rotationAllowed]];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    return [delegate rotationAllowed] && (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
 
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    if ([[cell reuseIdentifier] isEqual:@"updateHotspotIdentifier"]) {
        UIAlertView *areYouSure = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) 
                                                             message:NSLocalizedString(@"New hotspot list download. Continue?", nil) 
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"No", nil) 
                                                   otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
        [areYouSure setTag:cUpdateAVTag];
        [areYouSure show];
    } else if ([[cell reuseIdentifier] isEqual:@"resetHotspotIdentifier"]) {
        UIAlertView *areYouSure = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
                                                             message:NSLocalizedString(@"Reset to factory default. Continue?", nil)
                                                            delegate:self 
                                                   cancelButtonTitle:NSLocalizedString(@"No", nil) 
                                                   otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
        [areYouSure setTag:cResetToFactoryAVTag];
        [areYouSure show];
        
    } else 
        return;    
}

# pragma mark - IBActions

- (IBAction)blockRotationValueChanged:(UISwitch *) sender
{
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate]; 
    [delegate setRotationAllowed:!blockRotation.on];
}

#pragma mark - UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
	// NO = 0, YES = 1
	if(buttonIndex == 1) {
        switch (alertView.tag) {
            case cResetToFactoryAVTag:
                [[delegate accessPointsManager] resetToFactory];
                break;
            case cUpdateAVTag:
                [[delegate accessPointsManager] updateAccessPoints];
                break;            
            default:
                break;
        }
        [[delegate routeMeMapDelegate] resetMarkers];
    }
}

@end
