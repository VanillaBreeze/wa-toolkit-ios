/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "WALocationHandler.h"

@implementation WALocationHandler

@synthesize selectedCoordinate = _selectedCoordinate;
@synthesize delegate;

- (void)startUpdatingCurrentLocation
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return;
    }
    
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        _locationManager.distanceFilter = 10.0f; //we don't need to be any more accurate than 10m
        _locationManager.purpose = @"This may be used to obtain your current location coordinates.";
    }
    
    [_locationManager startUpdatingLocation];
}

- (void)stopUpdatingCurrentLocation
{
    [_locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate - Location updates

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{		
    // if the location is older than 30s ignore
    if (fabs([newLocation.timestamp timeIntervalSinceDate:[NSDate date]]) > 30 ) {
        return;
    }
    
    _selectedCoordinate = [newLocation coordinate];
    [self stopUpdatingCurrentLocation];
    if ([self.delegate respondsToSelector:@selector(locationController:didSelectLocation:)]) {
        [self.delegate locationController:self didSelectLocation:_selectedCoordinate];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    
    [self stopUpdatingCurrentLocation];    
    _selectedCoordinate = kCLLocationCoordinate2DInvalid;
    if ([self.delegate respondsToSelector:@selector(locationController:didFailWithError:)]) {
        [self.delegate locationController:self didFailWithError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{ }
@end
