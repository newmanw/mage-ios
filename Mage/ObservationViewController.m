//
//  ObservationViewerViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationViewController.h"
#import "GeoPoint.h"
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "ObservationPropertyTableViewCell.h"
#import <User.h>
#import "AttachmentCell.h"
#import "Attachment+FICAttachment.h"
#import <FICImageCache.h>
#import "AppDelegate.h"
#import "ImageViewerViewController.h"

@interface ObservationViewController ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation ObservationViewController

- (NSDateFormatter *) dateFormatter {
	if (_dateFormatter == nil) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
		[_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	}
	
	return _dateFormatter;
}

- (void) viewDidLoad {
    [super viewDidLoad];
	
	NSString *name = [_observation.properties valueForKey:@"type"];
	self.navigationItem.title = name;

	[_mapView setDelegate:self];
	CLLocationDistance latitudeMeters = 500;
	CLLocationDistance longitudeMeters = 500;
	GeoPoint *point = _observation.geometry;
	NSDictionary *properties = _observation.properties;
	id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
	if (accuracyProperty != nil) {
		double accuracy = [accuracyProperty doubleValue];
		latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
		longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
		
		MKCircle *circle = [MKCircle circleWithCenterCoordinate:point.location.coordinate radius:accuracy];
		[_mapView addOverlay:circle];
	}

	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(point.location.coordinate, latitudeMeters, longitudeMeters);
	MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
	[_mapView setRegion:viewRegion];
	
	ObservationAnnotation *annotation = [[ObservationAnnotation alloc] initWithObservation:_observation];
	[_mapView addAnnotation:annotation];
    
    self.userLabel.text = _observation.user.name;
    self.locationLabel.text = [NSString stringWithFormat:@"%f, %f", point.location.coordinate.latitude, point.location.coordinate.longitude];
    
    self.userLabel.text = [NSString stringWithFormat:@"%@ (%@)", _observation.user.name, _observation.user.username];
	self.timestampLabel.text = [self.dateFormatter stringFromDate:_observation.timestamp];
	
	self.locationLabel.text = [NSString stringWithFormat:@"%.6f, %.6f", point.location.coordinate.latitude, point.location.coordinate.longitude];
    
    [self.propertyTable setDelegate:self];
    [self.propertyTable setDataSource:self];
    [self.attachmentCollection setDataSource:self];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	CAGradientLayer *maskLayer = [CAGradientLayer layer];
    
    //this is the anchor point for our gradient, in our case top left. setting it in the middle (.5, .5) will produce a radial gradient. our startPoint and endPoints are based off the anchorPoint
    maskLayer.anchorPoint = CGPointZero;
    
    // Setting our colors - since this is a mask the color itself is irrelevant - all that matters is the alpha.
	// A clear color will completely hide the layer we're masking, an alpha of 1.0 will completely show the masked view.
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:.25];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    
    // An array of colors that dictatates the gradient(s)
    maskLayer.colors = @[(id)outerColor.CGColor, (id)outerColor.CGColor, (id)innerColor.CGColor, (id)innerColor.CGColor];
    
    // These are percentage points along the line defined by our startPoint and endPoint and correspond to our colors array.
	// The gradient will shift between the colors between these percentage points.
    maskLayer.locations = @[@0.0, @0.0, @.35, @.35f];
    maskLayer.bounds = _mapView.frame;
	UIView *view = [[UIView alloc] initWithFrame:_mapView.frame];
    
    view.backgroundColor = [UIColor blackColor];
    
    [self.view insertSubview:view belowSubview:self.mapView];
    self.mapView.layer.mask = maskLayer;
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
    if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
		ObservationAnnotation *observationAnnotation = annotation;
        UIImage *image = [ObservationImage imageForObservation:observationAnnotation.observation scaledToWidth:[NSNumber numberWithFloat:35]];
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
        
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[image accessibilityIdentifier]];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            if (image == nil) {
                annotationView.image = [self imageWithImage:[UIImage imageNamed:@"defaultMarker"] scaledToWidth:35];
            } else {
                annotationView.image = image;
            }
		} else {
            annotationView.annotation = annotation;
        }
		
        return annotationView;
    }
	
    return nil;
}

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (MKOverlayRenderer *) mapView:(MKMapView *) mapView rendererForOverlay:(id < MKOverlay >) overlay {
	MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:overlay];
	renderer.lineWidth = 1.0f;
	
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_observation.timestamp];
	if (interval <= 600) {
		renderer.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:.1f];
		renderer.strokeColor = [UIColor blueColor];
	} else if (interval <= 1200) {
		renderer.fillColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:.1f];
		renderer.strokeColor = [UIColor yellowColor];
	} else {
		renderer.fillColor = [UIColor colorWithRed:1 green:.5 blue:0 alpha:.1f];
		renderer.strokeColor = [UIColor orangeColor];
	}
	
	return renderer;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_observation.properties count];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	ObservationPropertyTableViewCell *observationCell = (ObservationPropertyTableViewCell *) cell;
    id value = [[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    id title = [observationCell.fieldDefinition objectForKey:@"title"];
    if (title == nil) {
        
        title = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
//        [_propertyTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:NO];
    }
    [observationCell populateCellWithKey:title andValue:value];
}

- (ObservationPropertyTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    id key = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    
    for (id field in [form objectForKey:@"fields"]) {
        NSString *fieldName = [field objectForKey:@"name"];
        if ([key isEqualToString: fieldName]) {
            NSString *type = [field objectForKey:@"type"];
            NSString *CellIdentifier = [NSString stringWithFormat:@"observationCell-%@", type];
            ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                CellIdentifier = @"observationCell-generic";
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            }
            cell.fieldDefinition = field;
            return cell;
        }
    }
    
    NSString *CellIdentifier = @"observationCell-generic";
    ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
	[self configureCell: cell atIndexPath:indexPath];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
    return [cell getCellHeightForValue:[[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]]];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AttachmentCell *cell = [_attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [[_observation.attachments allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
 
    FICImageCacheCompletionBlock completionBlock = ^(id <FICEntity> entity, NSString *formatName, UIImage *image) {
        cell.image.image = image;
        [cell.image.layer addAnimation:[CATransition animation] forKey:kCATransition];
        cell.image.layer.cornerRadius = 5;
        cell.image.clipsToBounds = YES;
    };
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BOOL imageExists = [delegate.imageCache retrieveImageForEntity:attachment withFormatName:AttachmentSmallSquare completionBlock:completionBlock];
    
    if (imageExists == NO) {
        cell.image.image = [UIImage imageNamed:@"download"];
    }
    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _observation.attachments.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AttachmentCell *cell = [_attachmentCollection dequeueReusableCellWithReuseIdentifier:@"AttachmentCell" forIndexPath:indexPath];
    Attachment *attachment = [[_observation.attachments allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    NSLog(@"clicked attachment %@", attachment.url);
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"viewImageSegue"])
    {
        // Get reference to the destination view controller
        ImageViewerViewController *vc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        [vc setAttachment:sender];
    }
}

@end
