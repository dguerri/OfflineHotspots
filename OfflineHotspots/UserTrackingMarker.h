//
//  UserTrackingMarker.h
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

#import "RMMapLayer.h"
#import "RMMapView.h"


@protocol UserTrackingStatusDelegate <NSObject>

enum userTrackingStatusValues {dontFollowUserLocation, followUserLocation, followUserLocationAndHeading};

@optional

- (void)userTrackingStatusWillChangeToValue:(enum userTrackingStatusValues)newValue fromValue:(enum userTrackingStatusValues)oldValue;
- (void)userTrackingStatusDidChangeToValue:(enum userTrackingStatusValues)value;

@end


@interface UserTrackingMarker : RMMapLayer <RMMovingMapLayer, CLLocationManagerDelegate>

@property (weak, nonatomic) id<UserTrackingStatusDelegate> userTrackingStatusDelegate;

@property (weak, nonatomic) RMMapView *mapView;
@property (assign, nonatomic) enum userTrackingStatusValues follow;

//RMMovingMapLayer protocol
@property (assign, nonatomic) RMProjectedPoint projectedLocation;
@property (assign) BOOL enableDragging;
@property (assign) BOOL enableRotation;

- (id)initWithMapView:(RMMapView *)aMapView latLong:(RMLatLong)newLatLong;

- (void)UIInterfceOrientationChanged:(UIInterfaceOrientation)newOrientation;
- (void)stopLocationServices;
- (void)resetLocationServices;
- (void)resetPosition;
- (void)resetRotation;

@end


