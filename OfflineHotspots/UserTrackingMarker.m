//
//  UserTrackingMarker.m
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

#import "UserTrackingMarker.h"
#import "RMProjection.h"
#import "RMMercatorToScreenProjection.h"
#import "RMLayerCollection.h"
#import "RMPixel.h"
#import "RMMarkerManager.h"

#pragma mark - Macros

#define cDefaultImage [UIImage imageNamed:@"user.png"]
#define cZPosition 2.0f
#define cLocationAccuracyFillColor [UIColor colorWithRed:0.0f green:0.1f blue:0.4f alpha:0.1f]
#define cLocationAccuracyLineColor [UIColor colorWithRed:0.0f green:0.2f blue:0.6f alpha:0.7f]
#define cLocationAccuracyLineWidth 1.0f
#define cHeadingAccuracyFillColor [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:0.6f]
#define cHeadingAccuracyLineColor [UIColor colorWithRed:0.7f green:0.7f blue:0.7f alpha:0.9f]
#define cHeadingAccuracyLineWidth 1.0f
#define cHeadingAccuracyLineLength 80.0f
#define cTransformationTimerInterval 0.05f
#define cHeadingFilter 1.5f
#define cDistanceFilter 2.5f

#pragma mark - Private interface

@interface UserTrackingMarker() {
    NSTimer *transformationTimer;
    CGFloat rotationOffset;
}

@property (assign, nonatomic) RMLatLong location;
@property (assign, nonatomic) CGFloat locationAccuracy;
@property (assign, nonatomic) CGFloat heading;
@property (assign, nonatomic) CGFloat headingAccuracy;
@property (assign, nonatomic) RMLatLong currentLocation;
@property (assign, nonatomic) CGFloat currentLocationAccuracy;
@property (assign, nonatomic) CGFloat currentHeading;
@property (assign, nonatomic) CGFloat currentHeadingAccuracy;
@property (strong, nonatomic) CALayer *imageLayer;
@property (strong, nonatomic) CAShapeLayer *locationAccuracyIndicatorLayer;
@property (strong, nonatomic) CAShapeLayer *headingAccuracyIndicatorLayer;
@property (strong, nonatomic) CLLocationManager *locationManager;

- (RMMapContents *)mapContents;
- (CGPoint)screenCoordinates;
- (void)moveToLatLong:(RMLatLong)newLatLong;
- (void)rotateToAngle:(CGFloat)angle;
- (void)updateLocationAccuracyIndicator;
- (void)updateHeadingAccuracyIndicator;
- (void)doTransformations;
- (void)resetTransformations;
- (BOOL)locationChanged;
- (BOOL)headingChanged;
- (BOOL)locationAccuracyChanged;
- (BOOL)headingAccuracyChanged;

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation;

- (void)locationManager:(CLLocationManager *)manager 
       didFailWithError:(NSError *)error;

- (void)locationManager:(CLLocationManager *)manager 
       didUpdateHeading:(CLHeading *)newHeading;

@end

#pragma mark - Implementation

@implementation UserTrackingMarker

#pragma mark - Properties synthetization

@synthesize userTrackingStatusDelegate = _userTrackingStatusDelegate;
@synthesize location = _location;
@synthesize locationAccuracy = _locationAccuracy;
@synthesize heading = _heading;
@synthesize headingAccuracy = _headingAccuracy;
@synthesize currentLocation = _currentLocation;
@synthesize currentLocationAccuracy = _currentLocationAccuracy;
@synthesize currentHeading = _currentHeading;
@synthesize currentHeadingAccuracy = _currentHeadingAccuracy;
@synthesize follow = _follow;
@synthesize imageLayer = _imageLayer;
@synthesize locationAccuracyIndicatorLayer = _locationAccuracyIndicatorLayer;
@synthesize headingAccuracyIndicatorLayer = _headingAccuracyIndicatorLayer;
@synthesize mapView = _mapView;
@synthesize projectedLocation = _projectedLocation;
@synthesize enableDragging = _enableDragging;
@synthesize enableRotation = _enableRotation;
@synthesize locationManager = _locationManager;

#pragma mark Constructors

- (id)init
{
    self = [super init];
    
    if (self) {
        //Location manager initialization
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager setDelegate:self];
        
        self.locationAccuracyIndicatorLayer = [[CAShapeLayer alloc] init];
        [self addSublayer:self.locationAccuracyIndicatorLayer];
        
        self.headingAccuracyIndicatorLayer = [[CAShapeLayer alloc] init];
        [self addSublayer:self.headingAccuracyIndicatorLayer];
        
        //User location image initialization
        self.imageLayer = [CALayer layer];
        UIImage *image = cDefaultImage;
        [self.imageLayer setContents:(id)image.CGImage];
        [self.imageLayer setBounds:CGRectMake(0, 0, image.size.width, image.size.height)];
        [self addSublayer:self.imageLayer];
        
        self.masksToBounds = NO;
        
        self.follow = dontFollowUserLocation;
        self.enableDragging = YES;
        self.enableRotation = NO;
        self.hidden = NO;
        [self setZPosition:cZPosition]; 

        [self resetLocationServices];
        
        transformationTimer = [NSTimer scheduledTimerWithTimeInterval:cTransformationTimerInterval target:self selector:@selector(doTransformations) userInfo:nil repeats:YES];
    }
    return self;
}

- (id)initWithMapView:(RMMapView *)aMapView latLong:(RMLatLong)newLatLong
{
    self = [self init];
    
    if (self) {  
        self.mapView = aMapView;
        [self updateLocationAccuracyIndicator];
        [self updateHeadingAccuracyIndicator];
        [self moveToLatLong:newLatLong];
    }
    
    return self;
}

- (void)dealloc {
    [self setUserTrackingStatusDelegate:nil];
    [self setMapView:nil];
}

#pragma mark - Custom accessors

- (void)setMapView:(RMMapView *)mapView
{
    [self removeFromSuperlayer];
    
    _mapView = mapView;
    [[_mapView.contents overlay] addSublayer:self];
    [self resetLocationServices];
}

- (void)setFollow:(enum userTrackingStatusValues)value
{
    if (![CLLocationManager headingAvailable] && (value == followUserLocationAndHeading))
        value = dontFollowUserLocation;

    if (_follow == value) return;
    
    if ([(NSObject*) self.userTrackingStatusDelegate respondsToSelector: @selector(userTrackingStatusWillChangeToValue:)])
        [self.userTrackingStatusDelegate userTrackingStatusWillChangeToValue:value fromValue:_follow];
    
    _follow = value;
    if (_follow == followUserLocationAndHeading) {
        self.heading = self.locationManager.heading.trueHeading;
    }
    
    [self resetLocationServices];
    [self resetTransformations];
    
    if ([(NSObject*) self.userTrackingStatusDelegate respondsToSelector: @selector(userTrackingStatusDidChangeToValue:)])
        [self.userTrackingStatusDelegate userTrackingStatusDidChangeToValue:value];
    
}

- (void)stopLocationServices
{
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
    [self.locationAccuracyIndicatorLayer setHidden:YES];
    [self.imageLayer setHidden:YES];
    [self.headingAccuracyIndicatorLayer setHidden:YES];
    [self setHidden:YES];
    [self setFollow:dontFollowUserLocation];
}

- (void)resetLocationServices
{
    if([CLLocationManager locationServicesEnabled]) {
        [self setHidden:NO];
        //User location accuracy indicator initialization
        [self.locationManager setDistanceFilter:cDistanceFilter];
        [self.locationManager startUpdatingLocation];
        self.location = self.locationManager.location.coordinate;
        self.locationAccuracy = self.locationManager.location.horizontalAccuracy;
        [self.locationAccuracyIndicatorLayer setHidden:NO];
        [self.imageLayer setHidden:NO];
        if ([CLLocationManager headingAvailable]) {
            //User heading accuracy indicator initialization
            [self.locationManager setHeadingFilter:cHeadingFilter];
            [self.locationManager startUpdatingHeading];
            self.heading = 0;
            self.headingAccuracy = 0;
            self.heading = self.locationManager.heading.trueHeading;
            self.headingAccuracy = self.locationManager.heading.headingAccuracy;
            [self.headingAccuracyIndicatorLayer setHidden:NO];
        } else {
            [self.locationManager stopUpdatingHeading];
            [self.headingAccuracyIndicatorLayer setHidden:YES];
            if (self.follow == followUserLocationAndHeading)
                [self setFollow:followUserLocation];
        }
    } else {
        [self setHidden:YES];
        [self.locationManager stopUpdatingLocation];
        [self.locationAccuracyIndicatorLayer setHidden:YES];
        [self.imageLayer setHidden:YES];
        [self setFollow:dontFollowUserLocation];
    }
    [self resetTransformations];
}

#pragma mark - Public methods

- (void)resetPosition
{
    [self moveToLatLong:self.location];
}

- (void)resetRotation
{
    self.heading = 0;
    [self.mapView setRotation:0];
}

- (BOOL)isWithinScreenBounds
{
    CGRect rect = [[self.mapContents mercatorToScreenProjection] screenBounds];
    CGPoint markerCoord = [self screenCoordinates];
	
	if (   markerCoord.x > rect.origin.x
		&& markerCoord.x < rect.origin.x + rect.size.width
		&& markerCoord.y > rect.origin.y
		&& markerCoord.y < rect.origin.y + rect.size.height)
	{
		return YES;
	}
	return NO;
}

- (void)moveBy:(CGSize)delta {
    
    [self setFollow:dontFollowUserLocation];
    
	if (self.enableDragging) {
        [super moveBy:delta];
	}
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center {
    
    if(self.enableDragging){
        [self setFollow:dontFollowUserLocation];
		self.position = RMScaleCGPointAboutPoint(self.position, zoomFactor, center);
        [self resetTransformations];
	}
}

- (BOOL)locationChanged
{
    return _location.latitude != _currentLocation.latitude && _location.longitude != _currentLocation.longitude;
}

- (BOOL)headingChanged
{
    return _heading != _currentHeading;
}

- (BOOL)locationAccuracyChanged
{
    return _locationAccuracy != _currentLocationAccuracy;
}

- (BOOL)headingAccuracyChanged
{
    return _headingAccuracy != _currentHeadingAccuracy;
}

#pragma mark - Private methods

- (RMMapContents *)mapContents
{
    return [self.mapView contents];
}

- (void)moveToLatLong:(RMLatLong)newLatLong
{
    if (!self.mapView) return;
    
    self.currentLocation = newLatLong;
	
    [self setProjectedLocation:[[self.mapContents projection] latLongToPoint:newLatLong]];
    
    if (self.follow > dontFollowUserLocation) {
        [self.mapContents moveToLatLong:newLatLong];
    }
}

- (void)rotateToAngle:(CGFloat)angle
{
    if (!self.mapView) return;
    
    self.currentHeading = angle;
    
    CGFloat indicatorRadians;
    
    if (self.follow == followUserLocationAndHeading) {
        [self.mapView setRotation:(- angle + rotationOffset) / 180.0 * M_PI];
        indicatorRadians = 0;
    } else {
        [self.mapView setRotation:0];
        indicatorRadians = (angle - rotationOffset) / 180.0 * M_PI;
    }
    
    //Disable all animations for performance reasons
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    [self.headingAccuracyIndicatorLayer setAffineTransform:CGAffineTransformMakeRotation(indicatorRadians)];
    
    [CATransaction commit];
    
}

- (void)updateLocationAccuracyIndicator 
{   
	CGMutablePathRef newPath = CGPathCreateMutable();
	
	CGFloat latRadians = self.location.latitude * M_PI / 180.0f;
	CGFloat pixelRadius = self.locationAccuracy / cos(latRadians) / [self.mapContents metersPerPixel];
    
    if (isnan(pixelRadius))
        pixelRadius = 0;
    
    CGRect rectangle = CGRectMake(self.locationAccuracyIndicatorLayer.position.x - pixelRadius,
								  self.locationAccuracyIndicatorLayer.position.y - pixelRadius, 
								  (pixelRadius * 2), 
								  (pixelRadius * 2));
    
	CGFloat offset = floorf(-cLocationAccuracyLineWidth / 2.0f) - 2;
    
	CGRect newBoundsRect = CGRectInset(rectangle, offset, offset);
	[self.locationAccuracyIndicatorLayer setBounds:newBoundsRect];
    
	CGPathAddEllipseInRect(newPath, NULL, rectangle);
    
	[self.locationAccuracyIndicatorLayer setPath:newPath];
	[self.locationAccuracyIndicatorLayer setFillColor:[cLocationAccuracyFillColor CGColor]];
	[self.locationAccuracyIndicatorLayer setStrokeColor:[cLocationAccuracyLineColor CGColor]];
	[self.locationAccuracyIndicatorLayer setLineWidth:cLocationAccuracyLineWidth];
    
    CGPathRelease(newPath);
    
    self.currentLocationAccuracy = self.locationAccuracy;
}

- (void)updateHeadingAccuracyIndicator
{
    CGMutablePathRef newPath = CGPathCreateMutable();
    
    CGFloat x = self.headingAccuracyIndicatorLayer.position.x;
    CGFloat y = self.headingAccuracyIndicatorLayer.position.y;
    
    CGFloat pixelAccuracy = (8 * cHeadingAccuracyLineLength * sin(self.headingAccuracy * M_PI / 360.0f)) / [self.mapContents metersPerPixel];
    
    CGPathMoveToPoint(newPath, NULL, x - pixelAccuracy, y - cHeadingAccuracyLineLength);
    CGPathAddLineToPoint(newPath, NULL, x, y);
    CGPathAddLineToPoint(newPath, NULL, x + pixelAccuracy, y - cHeadingAccuracyLineLength);
    //CGPathCloseSubpath(newPath);
    
    [self.headingAccuracyIndicatorLayer setPath:newPath];
	[self.headingAccuracyIndicatorLayer setFillColor:[cHeadingAccuracyFillColor CGColor]];
	[self.headingAccuracyIndicatorLayer setStrokeColor:[cHeadingAccuracyLineColor CGColor]];
	[self.headingAccuracyIndicatorLayer setLineWidth:cHeadingAccuracyLineWidth];
    
    CGPathRelease(newPath);
    
    self.currentHeadingAccuracy = self.headingAccuracy;
}

- (void)doTransformations {
    if ([self locationChanged])         [self moveToLatLong:self.location];
    if ([self headingChanged])          [self rotateToAngle:self.heading];    
    if ([self locationAccuracyChanged]) [self updateLocationAccuracyIndicator];
    if ([self headingAccuracyChanged])  [self updateHeadingAccuracyIndicator];
}

- (void)resetTransformations {
    [self moveToLatLong:self.location];
    [self rotateToAngle:self.heading];
    [self updateLocationAccuracyIndicator];
    [self updateHeadingAccuracyIndicator];
}

- (void)UIInterfceOrientationChanged:(UIInterfaceOrientation)newOrientation;
{
    switch (newOrientation) {
        case UIInterfaceOrientationLandscapeRight:
            rotationOffset = 270;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rotationOffset = 180;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rotationOffset = 90;
            break;
        case UIInterfaceOrientationPortrait:
        default:
            rotationOffset = 0;
            break;
    }
}

- (CGPoint)screenCoordinates
{
	return [[self.mapContents mercatorToScreenProjection] projectXYPoint:self.projectedLocation];
}

- (void)setProjectedLocation:(RMProjectedPoint)newProjectedLocation {
	_projectedLocation = newProjectedLocation;
    
	[self setPosition:[[self.mapContents mercatorToScreenProjection] projectXYPoint:_projectedLocation]];
}

#pragma mark - CoreLocation

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation;
{
    self.locationAccuracy = newLocation.horizontalAccuracy;    
    self.location = newLocation.coordinate;
    [self.locationAccuracyIndicatorLayer setHidden:NO];
    [self.imageLayer setHidden:NO];
    
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    self.locationAccuracy = 0;
    self.headingAccuracy = 0;
}

- (void)locationManager:(CLLocationManager *)manager 
       didUpdateHeading:(CLHeading *)newHeading
{
    self.headingAccuracy = newHeading.headingAccuracy;
    self.heading = newHeading.trueHeading;
    [self.headingAccuracyIndicatorLayer setHidden:NO];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    return YES;
}

@end