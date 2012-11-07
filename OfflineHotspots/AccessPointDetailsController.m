//
//  AccessPointDetailsController.m
//  Provinciawifi Offline Map
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

#import "AccessPointDetailsController.h"
#import "AppDelegate.h"
#import "Twitter/TWTweetComposeViewController.h"

#pragma mark - Private interface

//@interface AccessPointDetailsController()
//
//- (void)recalculateAccessPointImageShadow;
//
//@end

#pragma mark - Implementation

@implementation AccessPointDetailsController

#pragma mark - Properties synthetization

@synthesize titleLabel;
@synthesize addressLabel;
@synthesize cityLabel;
@synthesize accessPointImageView;

@synthesize accessPoint = _accessPoint;

#pragma mark - Constructors

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - System methods

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Private methods

//- (void)recalculateAccessPointImageShadow
//{
//    CGSize size = self.accessPointImageView.bounds.size;
//    CGFloat curlFactor = 15.0f;
//    CGFloat shadowDepth = 5.0f;
//    UIBezierPath *path = [UIBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(0.0f, 0.0f)];
//    [path addLineToPoint:CGPointMake(size.width, 0.0f)];
//    [path addLineToPoint:CGPointMake(size.width, size.height + shadowDepth)];
//    [path addCurveToPoint:CGPointMake(0.0f, size.height + shadowDepth)
//            controlPoint1:CGPointMake(size.width - curlFactor, size.height + shadowDepth - curlFactor)
//            controlPoint2:CGPointMake(curlFactor, size.height + shadowDepth - curlFactor)]; 
//    self.accessPointImageView.layer.shadowPath = path.CGPath;
//}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = NO;
    
    self.titleLabel.text = self.accessPoint.title;
    self.addressLabel.text = self.accessPoint.address;
    self.cityLabel.text = self.accessPoint.city;
    
    //    self.accessPointImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
    //    self.accessPointImageView.layer.shadowOpacity = 0.7f;
    //    self.accessPointImageView.layer.shadowOffset = CGSizeMake(10.0f, 10.0f);
    //    self.accessPointImageView.layer.shadowRadius = 2.0f;
    //    self.accessPointImageView.layer.masksToBounds = NO;
    //    self.accessPointImageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    //    self.accessPointImageView.layer.borderWidth = 12.0f;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.routeMeMapDelegate setMapViewContainer:self.accessPointImageView];
    [appDelegate.routeMeMapDelegate setMapCenterAtCoordinate:[self.accessPoint getCLLocationCoordinate2D]];
    [appDelegate.routeMeMapDelegate setMapZoomToOverview];
    [appDelegate.routeMeMapDelegate.userMarker stopLocationServices];
    [appDelegate.routeMeMapDelegate setUserInteractionEnabled:NO];
    [self.accessPointImageView setClipsToBounds:YES];
    [self.accessPointImageView setAlpha:0.0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //    [self recalculateAccessPointImageShadow];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [self.accessPointImageView setAlpha:1];
    [UIView commitAnimations];
}

- (void)viewDidUnload
{
    [self setAccessPoint:nil];
    [self setTitleLabel:nil];
    [self setAddressLabel:nil];
    [self setCityLabel:nil];
    [self setAccessPointImageView:nil];
    [self setView:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    return [delegate rotationAllowed] && (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    //    [self recalculateAccessPointImageShadow];
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([[cell reuseIdentifier] isEqual:@"shareOnTwitter"]) {
        UIImage *screenShot;
        
        UIGraphicsBeginImageContext(self.accessPointImageView.bounds.size);
        [self.self.accessPointImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
        screenShot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        TWTweetComposeViewController *twitter = [[TWTweetComposeViewController alloc] init];
        
        [twitter setInitialText:[NSString stringWithFormat:cDefaultTwitterShareFormatString, self.accessPoint.title, self.accessPoint.address, self.accessPoint.city]];
        [twitter addImage:screenShot];
        
        [self presentModalViewController:twitter animated:YES];
        
        twitter.completionHandler = ^(TWTweetComposeViewControllerResult result) 
        {
            if (result == TWTweetComposeViewControllerResultDone) {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tweet Status", nil) message:NSLocalizedString(@"Tweet sent", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
                [alertView show];
            }        
            [self dismissModalViewControllerAnimated:YES];
        };
    }
}

#pragma mark - IBActions

#pragma mark - Custom accessors

#pragma mark - Segues

@end
