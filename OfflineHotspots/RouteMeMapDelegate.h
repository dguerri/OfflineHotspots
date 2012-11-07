//
//  RouteMeMapDelegate.h
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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RMMapView.h"
#import "RMMarkerManager.h"
#import "UserTrackingMarker.h"
#import "AccessPoint.h"
#import "AccessPointMarker.h"

@protocol AccessPointDetailDelegate <NSObject>

@optional

- (void)detailRequestedForAccessPoint:(AccessPoint *)accessPoint;

@end

@interface RouteMeMapDelegate : NSObject <RMMapViewDelegate, UserTrackingStatusDelegate>

@property (weak, nonatomic) id<AccessPointDetailDelegate> accessPointDetailDelegate;
@property (weak, nonatomic) UIView *mapViewContainer;
@property (strong, nonatomic) UserTrackingMarker *userMarker;

- (void)releaseUnnecessaryResources;
- (void)resetMapViewCenter;
- (void)resetMapViewBounds;
- (void)resetMarkers;
- (enum userTrackingStatusValues)getFollow;
- (void)setFollow:(enum userTrackingStatusValues)value;
- (void)UIInterfceOrientationChanged:(UIInterfaceOrientation)newOrientation;
- (void)setMapCenterAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)setMapZoomToOverview;
- (void)setUserInteractionEnabled:(BOOL)value;

@end
