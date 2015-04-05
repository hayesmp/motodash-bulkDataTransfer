/*
 Copyright (c) 2013 OpenSourceRF.com.  All right reserved.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
This is the matching iPhone for the bulk data transfer sketch.  This
application has been included for completeness, and to demonstrate
how you could verify that no data was dropped.  Its really for
educational use only - it's output is to the debug window, and it
doesn't have a UI.

If you would like to test bulk data transfer with one of the existing
apps, you can use the ColorWheel application.  Open the sketch in 
Arduino, compile and open the Serial Monitor.  Open the ColorWheel
application and connect to the sketch.  Once connected, the sketch
will start transferring the data (The ColorWheel application receives
the data, but ignores it).  After the transfer is complete, the
Serial Monitor will display the start time, end time, elapsed time,
and kbps.
*/

#import <QuartzCore/QuartzCore.h>
#import "AppViewController.h"


@implementation AppViewController
{
    int packets;
    char ch;
    int packet;
    double start;
}

@synthesize rfduino, mapView;

+ (void)load
{
    // customUUID = @"c97433f0-be8f-4dc8-b6f0-5343e6100eb4";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        UIButton *backButton = [UIButton buttonWithType:101];  // left-pointing shape
        [backButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(disconnect:) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [[self navigationItem] setLeftBarButtonItem:backItem];
        
        [[self navigationItem] setTitle:@"RFduino Bulk"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
 
    [rfduino setDelegate:self];
    mapView.delegate = self;
    
    packets = 500;
    ch = 'A';
    packet = 0;
    
    //mapView
    
    recievingUpdates = false;
    
//    [mapView.userLocation addObserver:self
//                               forKeyPath:@"location"
//                                  options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
//                                  context:NULL];
    locationManager = [[CLLocationManager alloc] init];
    if(IS_OS_8_OR_LATER) {
        [locationManager requestWhenInUseAuthorization];
        [locationManager requestAlwaysAuthorization];
    }
    
    locationManager.headingFilter = kCLHeadingFilterNone;
    locationManager.headingOrientation = CLDeviceOrientationPortrait;
    locationManager.distanceFilter = kCLLocationAccuracyBestForNavigation;
    //    locationManager.distanceFilter = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    [locationManager startUpdatingHeading];
    [locationManager startUpdatingLocation];
    
    locationDelay = [NSTimer scheduledTimerWithTimeInterval:(4.0) target:self selector:@selector(located:) userInfo:nil repeats:false];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:true];
    
//    MKCoordinateRegion region;
//    region.center = mapView.userLocation.coordinate;
//    
//    MKCoordinateSpan span;
//    span.latitudeDelta  = 0.005f; // Change these values to change the zoom
//    span.longitudeDelta = 0.005f;
//    region.span = span;
//    
//    NSLog(@"Region center %f %f", region.center.latitude, region.center.longitude);
//    
//    [mapView setRegion:region animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)disconnect:(id)sender
{
    NSLog(@"disconnect pressed");

    [rfduino disconnect];
}

- (void)didReceive:(NSData *)data
{
     //NSLog(@"RecievedRX");

    
    uint8_t *p = (uint8_t*)[data bytes];
    NSUInteger len = [data length];
    
    NSMutableString *s = [[NSMutableString alloc] init];
    
    for (int i = 0; i < len; i++)
      if (isprint(p[i]))
          [s appendFormat:@"%c", p[i]];

    //NSLog(@"%@", s);
    
    NSMutableArray *dataArray = (NSMutableArray *)[s componentsSeparatedByString:@" "];
    [dataArray removeObject:@""];
    
    
    
    
    if (packet == 0)
    {
        NSLog(@"start");
        start = CACurrentMediaTime();
    }
    
    p = (uint8_t*)[data bytes];
    len = [data length];
    
    if (len != 15)
        NSLog(@"len issue");
    
//    for (int i = 0; i < 20; i++)
//    {
//        if (p[i] != ch)
//            NSLog(@"ch issue");
//        ch++;
//        if (ch > 'Z')
//            ch = 'A';
//    }
    packet++;
    
    int x_scale = [dataArray[0] intValue];
    int y_scale = [dataArray[1] intValue];
    
    double lat = currentCenter.latitude;
    double lon = currentCenter.longitude;
    
    //NSLog(@"current loc: %f %f",lat, lon);
    
    if (x_scale > 950)
        lat += .002;
    else if (x_scale < 50)
        lat -= .002;
    
    if (y_scale > 950)
        lon += .002;
    else if (y_scale < 50)
        lon -= .002;
    
    if ([self joystickMovedByLattitude:lat andLongitude:lon])
    {
        [self updateMapviewFromData:lat lon:lon];
    }
//    if (packet >= packets)
//    {
//        NSLog(@"end");
//        double end = CACurrentMediaTime();
//        float secs = (end - start);
//        int bps = ((packets * 20) * 8) / secs;
//        NSLog(@"start: %f", start);
//        NSLog(@"end: %f", end);
//        NSLog(@"elapsed: %f", secs);
//        NSLog(@"kbps: %f", bps / 1000.0);
//    }

}

- (double)unsignMe:(double)val
{
    if (val < 0)
        val = val * -1;
    return val;
}

- (BOOL)joystickMovedByLattitude:(double)x andLongitude:(double)y
{
    double x_diff = 0; double y_diff = 0;
    double unsigned_lat = [self unsignMe:currentCenter.latitude];
    double unsigned_lon = [self unsignMe:currentCenter.longitude];
    double unsigned_x = [self unsignMe:x];
    double unsigned_y = [self unsignMe:y];
    x_diff = unsigned_lat - unsigned_x;
    y_diff = unsigned_lon - unsigned_y;
    NSLog(@"diff %f=%f-%f %f=%f-%f", x_diff, currentCenter.latitude, x, y_diff, currentCenter.longitude, y);
    NSLog(@"diff %f=%f-%f %f=%f-%f", x_diff, unsigned_lat, unsigned_x, y_diff, unsigned_lon, unsigned_y);
    if (x != currentCenter.latitude ||  y != currentCenter.longitude)
        if (!(x_diff > .002 || y_diff > .002))
            return true;
    return false;
}

- (void)updateMapviewFromData:(double)lat lon:(double)lon
{
    if (recievingUpdates==true)
    {
        MKCoordinateRegion region;
        region.center = CLLocationCoordinate2DMake(lat, lon);
        
        MKCoordinateSpan span;
        span.latitudeDelta  = 0.005f; // Change these values to change the zoom
        span.longitudeDelta = 0.005f;
        region.span = span;
        
//        CLLocationCoordinate2D startCoord = CLLocationCoordinate2DMake(lat, lon);
//        MKCoordinateRegion adjustedRegion = [mapView regionThatFits:MKCoordinateRegionMakeWithDistance(startCoord, 200, 200)];
        //[mapView setRegion:adjustedRegion animated:YES];
        
        [mapView setRegion:region animated:false];
        
        //NSLog(@"current loc: %@",adjustedRegion);
    }
}


#pragma mark -
//===================================================================================
//===================================================================================
#pragma mark MapKit





#pragma mark -
//===================================================================================
//===================================================================================
#pragma mark Core Location

- (IBAction)located:(id)sender
{
    MKCoordinateRegion region;
    region.center = mapView.userLocation.coordinate;
    
    MKCoordinateSpan span;
    span.latitudeDelta  = 0.005f; // Change these values to change the zoom
    span.longitudeDelta = 0.005f;
    region.span = span;
    
    NSLog(@"Region center %f %f", region.center.latitude, region.center.longitude);
    
    [mapView setRegion:region animated:YES];
    
    currentCenter = CLLocationCoordinate2DMake(locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);

    recievingUpdates = true;
}

//Observer location change & setup span
- (void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
    
    if ([keyPath isEqualToString:@"location"])
    {
        if (recievingUpdates==false)
        {
            MKCoordinateRegion region;
            region.center = mapView.userLocation.coordinate;
            
            MKCoordinateSpan span;
            span.latitudeDelta  = 0.005f; // Change these values to change the zoom
            span.longitudeDelta = 0.005f;
            region.span = span;
            
            NSLog(@"Region center %f %f", region.center.latitude, region.center.longitude);
            
            [mapView setRegion:region animated:YES];
            
            recievingUpdates = true;
        }
    }
}

//locationManager didUpdateHeading
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    int headingRot = 180;
    //[mapView setTransform:CGAffineTransformMakeRotation(-1 * newHeading.trueHeading * 3.14159 / headingRot)];
}

//locationManager didUpdateLocation
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
//    if (recievingUpdates==false)
//    {
//        MKCoordinateRegion region;
//        CLLocationCoordinate2D startCoord = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
//        region.center = startCoord;
//        
//        MKCoordinateSpan span;
//        span.latitudeDelta  = 0.005f; // Change these values to change the zoom
//        span.longitudeDelta = 0.005f;
//        region.span = span;
//        
//        NSLog(@"Region center %f %f", region.center.latitude, region.center.longitude);
//        
//        [mapView setRegion:region animated:YES];
//        
//        recievingUpdates = true;
//    }

}

//locationManager didFailWithError
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
}

#pragma mark -
//===================================================================================
//===================================================================================
#pragma mark Accelerometer

//- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
//{
//    UIAccelerationValue x, y, z;
//    x = acceleration.x;
//    y = acceleration.y;
//    z = acceleration.z;
//    NSLog(@"Acceleration: %f %f %f", x, y, x);
//    if (x > 0.1 && y > 0.1 && z > 0.1) {
//        isMoving = YES;
//    } else {
//        isMoving = NO;
//    }
//}


@end
