//
//  ViewController.h
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

#import <UIKit/UIKit.h>
#import "RouteMeMapDelegate.h"

@interface MapViewController : UIViewController <UserTrackingStatusDelegate, AccessPointDetailDelegate>

@property (weak, nonatomic) IBOutlet UIView *mapViewContainer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *followPositionButton;

- (IBAction)followPositionPressed:(UIBarButtonItem *)sender;

- (void)detailRequestedForAccessPoint:(AccessPoint *)accessPoint;

@end
