//
//  RouteMeMapDelegate.m
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

#import "RMOpenAerialMapSource.h"
#import "RMOpenStreetMapSource.h"
#import "RouteMeMapDelegate.h"
#import "AccessPoint.h"
#import "AccessPointsManager.h"
#import "AppDelegate.h"
#import "AccessPointMarker.h"
#import "RMDBMapSource.h"
#import "RMLayerCollection.h"

#pragma mark - Macros

#define cMapTileSourceFile @"ProvinciaDiRomaMap.db"
#define cMapInitialZoom 13.0f
#define cMapInitialLat 41.863617f
#define cMapInitialLon 12.540894f

#define cMapMaxZoom 16.3f
#define cMapMinZoom 10.0f
#define cMapOverviewZoom 16.0f
#define cMapSWLatLimit 40.979900f
#define cMapSWLonLimit 11.250000f
#define cMapNELatLimit 42.553082f
#define cMapNELonLimit 14.062500f

#pragma mark - Private interface

@interface RouteMeMapDelegate()

@property (strong, nonatomic) RMMapView *mapView;
@property (weak, nonatomic) RMMarker *previouslyTappedMarker;

@end

#pragma mark - Implementation

@implementation RouteMeMapDelegate

#pragma mark - Properties synthetization

@synthesize accessPointDetailDelegate;

@synthesize mapViewContainer = _mapViewContainer;

@synthesize mapView = _mapView;
@synthesize userMarker = _userMarker;
@synthesize previouslyTappedMarker = _previouslyTappedMarker;

#pragma mark - Constructors

- (id)init
{
    self = [super init];
    
    if (self) {
        // For offline map use:
        RMDBMapSource *tileSource = [[RMDBMapSource alloc] initWithPath:cMapTileSourceFile];
        // For online map change the above source with
        //RMOpenStreetMapSource *tileSource = [[RMOpenStreetMapSource alloc] init];
        
        self.mapView = [[RMMapView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 200.0f)];    
        [self.mapView setBackgroundColor:[UIColor grayColor]];
        [self.mapView setDeceleration:NO];
        [self.mapView setUserInteractionEnabled:TRUE];
        [self.mapView setEnableRotate:TRUE];
        [self.mapView setDelegate:self];
        
        [self.mapView setConstraintsSW:CLLocationCoordinate2DMake(cMapSWLatLimit, cMapSWLonLimit)
                                    NE:CLLocationCoordinate2DMake(cMapNELatLimit, cMapNELonLimit)];
        
        RMMapContents *mapContent = [[RMMapContents alloc] initWithView:self.mapView]; 
        
        [mapContent setMaxZoom:cMapMaxZoom];
        [mapContent setMinZoom:cMapMinZoom];
        [mapContent setZoom:cMapInitialZoom];
        
        [mapContent setTileSource:tileSource];
        // For offline map use:
        [mapContent setMapCenter:[tileSource centerOfCoverage]];
        // For online map use
        //[mapContent setMapCenter:CLLocationCoordinate2DMake(41.89025, 12.492313)];
                
        self.userMarker = [[UserTrackingMarker alloc] init];
        self.userMarker.follow = NO;
        self.userMarker.hidden = NO;
        self.userMarker.zPosition = 1.0f;
        [self.userMarker setUserTrackingStatusDelegate:self];
        
        self.previouslyTappedMarker = nil;
    }
    
    return self;
}

- (void)dealloc {
    [self setAccessPointDetailDelegate:nil];
    [self setMapViewContainer:nil];
}

#pragma mark - Custom accessors

- (void)setMapViewContainer:(UIView *)view {
    if (_mapViewContainer) {
        [self.mapView removeFromSuperview];
    }
    
    _mapViewContainer = view;
    
    if (view) {
        [_mapViewContainer addSubview:self.mapView];	
        [self resetMapViewBounds];
        [self resetMapViewCenter];
        [self resetMarkers];
        [self.userMarker setMapView:self.mapView];
        [self.userMarker resetLocationServices];
    }
}

- (enum userTrackingStatusValues)getFollow
{
    return self.userMarker.follow;
}

- (void)setFollow:(enum userTrackingStatusValues)value
{
    [self.userMarker setFollow:value];
}

#pragma mark - Public methods

- (void)releaseUnnecessaryResources 
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses]; 
    [self.mapView.contents removeAllCachedImages];
}

- (void)resetMapViewCenter
{
    if (!self.mapViewContainer)
        return;
    
    [self.mapView setCenter:self.mapViewContainer.center];
}

- (void)resetMapViewBounds
{
    if (!self.mapViewContainer)
        return;
    
    // If the userMarker if in follow-heading-mode, we need to reset the rotation and then set the new bounds
    [self.userMarker resetRotation];
    // Using the screen diagonal allow the view to rotate
    CGFloat diagonal = sqrtf(powf(self.mapViewContainer.bounds.size.width, 2) + pow(self.mapViewContainer.bounds.size.height,2));
    [self.mapView setFrame:CGRectMake(-(diagonal - self.mapViewContainer.bounds.size.width) / 2, 
                                      -(diagonal - self.mapViewContainer.bounds.size.height) / 2, 
                                      diagonal, 
                                      diagonal)];
    // [self.mapView setFrame:self.mapViewContainer.bounds];
}

- (void)resetAccessPointMarkers
{
    [self.mapView.markerManager removeMarkers];
    
    // Setup Access Point markers
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    AccessPointsManager *accessPointsManager = [delegate accessPointsManager];
    
    for (AccessPoint *accessPoint in [accessPointsManager accessPoints]) {        
        [self.mapView.markerManager addMarker:accessPoint.marker AtLatLong:[accessPoint getCLLocationCoordinate2D]];  
    }
}

- (void)resetMarkers
{
    [self.userMarker setFollow:dontFollowUserLocation];
    [self resetAccessPointMarkers];
    [self.userMarker setMapView:self.mapView];
}

- (void)setMapZoomToOverview
{
    [self.mapView.contents setZoom:cMapOverviewZoom];
}

- (void)setMapCenterAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self.userMarker setFollow:dontFollowUserLocation];
    [self.mapView moveToLatLong:coordinate];
}

- (void)setUserInteractionEnabled:(BOOL)value
{
    [self.mapView setUserInteractionEnabled:value];
}

#pragma mark - Route Me

- (void)tapOnMarker:(RMMarker*)marker
              onMap:(RMMapView*)map 
{
    if ([marker conformsToProtocol:@protocol(TappableRMMarker)]) {
        if (self.previouslyTappedMarker) {
            [(RMMarker <TappableRMMarker> *) self.previouslyTappedMarker tapped];
        }
        
        if (self.previouslyTappedMarker == marker) {
            self.previouslyTappedMarker = nil;
        } else {
            [(RMMarker <TappableRMMarker> *) marker tapped];
            self.previouslyTappedMarker = marker;
        }
    }
}

- (void) tapOnLabelForMarker:(RMMarker*)marker 
                       onMap:(RMMapView*)map
                     onLayer:(CALayer *)layer
{
    [self tapOnMarker:marker onMap:map];
    
    if ((marker.class == AccessPointMarker.class) && (layer.name == cCODetailsBottonLayerName)) {
        AccessPointMarker *accessPointMarker = (AccessPointMarker *)marker;
        if ([(NSObject*) self.accessPointDetailDelegate respondsToSelector: @selector(detailRequestedForAccessPoint:)])
            [self.accessPointDetailDelegate detailRequestedForAccessPoint:accessPointMarker.accessPoint];
    }
}

#pragma mark - Misc

- (void)UIInterfceOrientationChanged:(UIInterfaceOrientation)newOrientation
{
    [self.userMarker UIInterfceOrientationChanged:newOrientation];
    [self resetMapViewBounds];
}


@end
