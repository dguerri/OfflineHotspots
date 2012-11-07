//
//  AccessPoint.m
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

#import "AccessPoint.h"
#import "AccessPointMarker.h"

@implementation AccessPoint

@dynamic title;
@dynamic lat;
@dynamic lon;
@dynamic category;
@dynamic city;
@dynamic address;

@synthesize marker = _marker;

#pragma mark - Initializations

//Invoked automatically by the Core Data framework after the receiver has been fetched.
- (void)awakeFromFetch
{
    [super awakeFromFetch];
    if (self.marker)
        [self.marker updateImage];
    else {
        self.marker = [[AccessPointMarker alloc] init];
        [self.marker setAccessPoint:self];
    }
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    if (self.marker)
        [self.marker updateImage];
    else {
        self.marker = [[AccessPointMarker alloc] init];
        [self.marker setAccessPoint:self];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    [super setValue:value forKey:key];
    
    if (key == @"category" && self.marker) {
        [self.marker updateImage];
    }
}

#pragma mark - Other methods

- (CLLocationCoordinate2D)getCLLocationCoordinate2D
{
    return CLLocationCoordinate2DMake([self.lat doubleValue], [self.lon doubleValue]);
}

@end
