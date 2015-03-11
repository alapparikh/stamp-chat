//
//  SCViewController.m
//  StampChat
//
//  Created by Tim Novikoff on 1/25/14.
//  Copyright (c) 2014 Tim Novikoff. All rights reserved.
//

#import "SCViewController.h"
#import <MessageUI/MessageUI.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface SCViewController () <MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet UITextField *theTextField;
@property (strong, nonatomic) NSArray *fontNameArray;
@property (strong, nonatomic) NSArray *fontArray;
//@property (strong, nonatomic) IBOutlet UITableView *fontTableView;
@property (assign, nonatomic) BOOL isAlreadyDragging;
@property (assign, nonatomic) CGPoint oldTouchPoint;
@property (strong, nonatomic) UIImageView *theImageView;

@property (strong, nonatomic) IBOutlet UIButton *drawButton;
@property (strong, nonatomic) IBOutlet UIButton *textButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) IBOutlet UIButton *stampButton;
@property (strong, nonatomic) IBOutlet UISlider *colorSlider;
@property (strong, nonatomic) IBOutlet UIButton *emailButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *stampSegControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *drawSegControl;
@property (strong, nonatomic) UIColor *buttonBackgroundColor;
@property NSUInteger fontPointer;
@property BOOL photoClicked;

@property (nonatomic, strong) MFMailComposeViewController *mailComposeViewController;
@property (strong, nonatomic) UIImagePickerController *pickerController;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CMMotionManager *motionManager;

@end

@implementation SCViewController

- (void)viewDidLoad
{
    _red = 255.0/255.0;
    _green = 0.0/255.0;
    _blue = 0.0/255.0;
    _brush = 5.0;
    _opacity = 1.0;
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //initialize an array with the font names (for display in the table view cells)
    self.fontNameArray = [[NSArray alloc] initWithObjects:@"AppleGothic",
                          @"HelveticaNeue-UltraLight",
                          @"MarkerFelt-Thin",
                          @"Georgia",
                          @"Courier",
                          @"Verdana-Bold",
                          nil];
    
    //initialize an array of fonts for use in setting the font of the textField
    int fontSize = 20;    UIFont *appleGothic = [UIFont fontWithName:@"AppleGothic" size:fontSize];
    UIFont *ultraLight = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:fontSize];
    UIFont *markerFelt = [UIFont fontWithName:@"MarkerFelt-Thin" size:fontSize];
    UIFont *georgia = [UIFont fontWithName:@"Georgia" size:fontSize];
    UIFont *courier = [UIFont fontWithName:@"Courier" size:fontSize];
    UIFont *verdana = [UIFont fontWithName:@"Verdana-Bold" size:fontSize];
    self.fontArray = [[NSArray alloc]initWithObjects:appleGothic,ultraLight,markerFelt,georgia,courier,verdana, nil];
    
    //add gesture recognizer to the text field
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureDidDrag:)];
    [self.theTextField addGestureRecognizer:panGestureRecognizer];
    
    //add an image.
    UIImage *image = [UIImage imageNamed:@"ios_stampchat"];
    self.theImageView = [[UIImageView alloc] initWithImage:image];
    [self.view insertSubview:self.theImageView atIndex:0];
    
    //Default slider track colors
    [self.colorSlider setMinimumTrackTintColor:[UIColor colorWithRed:_red green:_green blue:_blue alpha:1.0]];
    [self.colorSlider setMaximumTrackTintColor:[UIColor colorWithRed:_red green:_green blue:_blue alpha:1.0]];
    
    //Default button background color
    self.buttonBackgroundColor = [UIColor colorWithRed:_red green:_green blue:_blue alpha:0.3];
    
    //Default text color
    [self.theTextField setTextColor:[UIColor colorWithRed:_red green:_green blue:_blue alpha:1.0]];
    
    // Set button background colors
    [self.clearButton setBackgroundImage:[self imageWithColor:[UIColor blackColor]] forState:UIControlStateHighlighted];
    [self.stampButton setBackgroundImage:[self imageWithColor:[UIColor blackColor]] forState:UIControlStateHighlighted];
    
    [self.clearButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    [self.stampButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    [self.drawButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    [self.textButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    [self.saveButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    [self.emailButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    
    // Visibility Setup
    self.stampSegControl.center = CGPointMake(161.0, 0.0);
    self.stampSegControl.alpha = 0.0;
    self.drawSegControl.center = CGPointMake(161.0, 0.0);
    self.drawSegControl.alpha = 0.0;
    self.stampButton.center = CGPointMake(33.5, 600.0);
    self.stampButton.alpha = 0.0;
    self.colorSlider.center = CGPointMake(160.0, 600.0);
    self.colorSlider.alpha = 0.0;
    [self.theTextField setHidden:YES];
    
    // Location/GPS stuff
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    // Accelerometer stuff
    self.motionManager = [[CMMotionManager alloc] init];
    
    self.photoClicked = false;
}

- (void)viewDidAppear:(BOOL)animated{
    NSLog(@"viewDidAppear loaded successfully");
    
    if (self.photoClicked == false){
        
        // Initialize camera
        [self initializeCamera];
        self.photoClicked = true;
    }
    else {
        // Visibility Setup
        self.stampSegControl.center = CGPointMake(161.0, 0.0);
        self.stampSegControl.alpha = 0.0;
        self.drawSegControl.center = CGPointMake(161.0, 0.0);
        self.drawSegControl.alpha = 0.0;
        self.stampButton.center = CGPointMake(33.5, 600.0);
        self.stampButton.alpha = 0.0;
        self.colorSlider.center = CGPointMake(160.0, 600.0);
        self.colorSlider.alpha = 0.0;
        [self.theTextField setHidden:YES];
        
        self.drawButton.selected = NO;
        self.drawSegControl.selectedSegmentIndex = 0;
        [self drawButtonAnimations];
        [self.drawButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
        self.textButton.selected = NO;
        self.stampSegControl.selectedSegmentIndex = 0;
        [self textButtonAnimations];
        [self.textButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    }
    
}

- (UIImage *) burnText: (NSString *) text intoImage: (UIImage *) image{
    
    //boilerplate for beginning an image context
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, YES, 0.0);

    //draw the image in the image context
    CGRect aRectangle = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height);
    [image drawInRect:aRectangle];
    
    //draw the text in the image context
    NSDictionary *attributes = @{ NSFontAttributeName: self.theTextField.font,
                                  NSForegroundColorAttributeName: [UIColor colorWithRed:_red green:_green blue:_blue alpha:1.0]};
    CGSize size = [self.theTextField.text sizeWithAttributes:attributes];//get size of text
    CGPoint center = self.theTextField.center;//get the center
    CGRect rect = CGRectMake(center.x - size.width/2, center.y - size.height/2, size.width, size.height);//create the rect for the text
    [text drawInRect:rect withAttributes:attributes];

    //get the image to be returned before ending the image context
    UIImage *theImage=UIGraphicsGetImageFromCurrentImageContext();

    //boilerplate for ending an image context
    UIGraphicsEndImageContext();

    return theImage;
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
//    UIImageView *imageView = [[UIImageView alloc]initWithImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
//    imageView.frame = CGRectMake(0, 0, 320, 568);
//    [self.view addSubview:imageView];
//    [self.view sendSubviewToBack:imageView];
    
    self.theImageView.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void) panGestureDidDrag: (UIPanGestureRecognizer *) sender{

    //get the touch point from the sender
    CGPoint newTouchPoint = [sender locationInView:self.view];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            //initialize oldTouchPoint for this drag
            self.oldTouchPoint = newTouchPoint;
            break;
        }
        case UIGestureRecognizerStateChanged:{
            //calculate the change in position since last call of panGestureDidDrag (for this drag)
            float dx = newTouchPoint.x - self.oldTouchPoint.x;
            float dy = newTouchPoint.y - self.oldTouchPoint.y;
    
            //move the center of the text field by the same amount that the finger moved
            self.theTextField.center = CGPointMake(self.theTextField.center.x + dx, self.theTextField.center.y + dy);

            //set oldTouchPoint
            self.oldTouchPoint = newTouchPoint;
            break;
        }
        default:
            break;
    }
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
//    
//    //boilerplate for table views
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//    }
//    
//    //add the appropriate font name to the cell
//    cell.textLabel.text = [self.fontNameArray objectAtIndex:indexPath.row];
//    
//    return cell;
//}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//    return MAX(self.fontArray.count, self.fontNameArray.count);//note that this allows for easily adding more fonts. a better way to set things up might have been an array of dictionaries so you don't have to worry about matching the two arrays as you expand to add more fonts.
//}
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    //change the font of the text field
//    self.theTextField.font = [self.fontArray objectAtIndex:indexPath.row];
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)stampSegControlValueChanged:(id)sender {
    
    if (self.stampSegControl.selectedSegmentIndex == 1) {
        
        [self.motionManager stopAccelerometerUpdates];
        CLLocation *location = [self.locationManager location];
        self.theTextField.text = [NSString stringWithFormat:@"%.2f, %.2f", location.coordinate.latitude, location.coordinate.longitude];
    }
    else if (self.stampSegControl.selectedSegmentIndex == 2) {
        
        // Set text as current accelerometer data
        //CMAccelerometerData *latestData = [self.motionManager accelerometerData];
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            
            double x = accelerometerData.acceleration.x;
            double y = accelerometerData.acceleration.y;
            double z = accelerometerData.acceleration.z;
            
            self.theTextField.text = [NSString stringWithFormat:@"%.1f, %.1f, %.1f", x, y, z];
        }];
        
    }
    else {
        [self.motionManager stopAccelerometerUpdates];
        self.theTextField.text = @"Enter text";
    }
}

// Stamp either entered text, GPS location, or accelerometer data on image
- (IBAction)stampButtonPressed:(id)sender {
    
    //get the new image, with the latest text burned into the latest position
    UIImage *image = [self burnText:self.theTextField.text intoImage:self.theImageView.image];
    
    //show the new image
    self.theImageView.image = image;
}

- (IBAction)saveButtonPressed:(id)sender {

    //save the image to the photo roll. note that the middle two parameters could have been left nil if we didn't want to do anything particular upon the save completing.
    UIImageWriteToSavedPhotosAlbum(self.theImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);

}

- (void)               image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo{
    //this method is being called once saving to the photoroll is complete.
    NSLog(@"photo saved!");
    
}

- (IBAction)textFieldDidEndOnExit:(id)sender {
    [sender resignFirstResponder];    //hide the keyboard
}

// Send image as attachment in email
- (IBAction)emailButtonPressed:(id)sender {
    
    //initialize the mail compose view controller
    self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
    self.mailComposeViewController.mailComposeDelegate = self;//this requires that this viewController declares that it adheres to <MFMailComposeViewControllerDelegate>, and implements a couple of delegate methods which we did not implement in class
    
    //set a subject for the email
    [self.mailComposeViewController setSubject:@"Check out my snapsterpiece"];
    
    // get the image data and add it as an attachment to the email
    NSData *imageData = UIImagePNGRepresentation(self.theImageView.image);
    [self.mailComposeViewController addAttachmentData:imageData mimeType:@"image/png" fileName:@"snapsterpiece"];

    // Show mail compose view controller
    [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
}

// Change color of drawing
- (IBAction)sliderChanged:(id)sender {
    
    UISlider *slider = (UISlider *)sender;
    float val = slider.value;
    UIColor *color = [UIColor colorWithHue:val saturation:1.0 brightness:1.0 alpha:1.0];
    [color getRed:&_red green:&_green blue:&_blue alpha:&_opacity];
    
    //Change slider bar color. This is a workaround solution as there seem to be problems with certain properties of UISlider (setMinimumTrackTintColor has issues)
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [slider setMaximumTrackImage:image forState:UIControlStateNormal];
    [slider setMinimumTrackImage:image forState:UIControlStateNormal];
    
    // Change button background colors
    self.buttonBackgroundColor = [UIColor colorWithRed:_red green:_green blue:_blue alpha:0.3];
    if (self.drawButton.selected == YES){
        [self.drawButton setBackgroundColor:self.buttonBackgroundColor];
    }
    if (self.textButton.selected == YES){
        [self.textButton setBackgroundColor:self.buttonBackgroundColor];
    }
//    [self.stampButton setBackgroundImage:[self imageWithColor:self.buttonBackgroundColor] forState:UIControlStateHighlighted];
    
    // Change text color
    [self.theTextField setTextColor:color];
}

// MFMailComposeViewControllerDelegate method
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {//gets called after user sends or cancels
    
    //dismiss the mail compose view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)drawButtonPressed:(id)sender {
    if (self.drawButton.selected == NO){
        self.drawButton.selected = YES;
        
        [self drawButtonAnimations];
        
        [self.drawButton setBackgroundColor:self.buttonBackgroundColor];
    }
    else {
        self.drawButton.selected = NO;
        
        [self drawButtonAnimations];
        
        [self.drawButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    }
}

// Cycle through font
- (IBAction)textButtonPressed:(id)sender {
    
//    self.theTextField.font = [self.fontArray objectAtIndex:self.fontPointer];
//    self.fontPointer = self.fontPointer + 1;
//    if (self.fontPointer >= [self.fontArray count]){
//        self.fontPointer = 0;
//    }
    
    if (self.textButton.selected == YES) {
        
        self.textButton.selected = NO;
        
        // Switch visibility
        [self.theTextField setHidden:YES];
        [self textButtonAnimations];
        
        // Set background color
        [self.textButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
        
    } else {
        
        self.textButton.selected = YES;
        
        // Switch visibility
        [self.theTextField setHidden:NO];
        [self textButtonAnimations];
        
        // Set background color of button
        [self.textButton setBackgroundColor:self.buttonBackgroundColor];
    }
    
}

// Clear everything on screen and go back to taking a picture
- (IBAction)clearButtonPressed:(id)sender {
    
    [self.motionManager stopAccelerometerUpdates];
    [self initializeCamera];
}

//From tutorial (with minor edits)
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.drawButton.selected == YES && self.drawSegControl.selectedSegmentIndex == 0){
        _mouseSwiped = NO;
        UITouch *touch = [touches anyObject];
        _lastPoint = [touch locationInView:self.theImageView];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.drawButton.selected == YES && self.drawSegControl.selectedSegmentIndex == 0){
    
    _mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.theImageView];
    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [self.theImageView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), _lastPoint.x, _lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), _brush );
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), _red, _green, _blue, 1.0);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
    
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.theImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    [self.theImageView setAlpha:_opacity];
    UIGraphicsEndImageContext();
    
    _lastPoint = currentPoint;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(!_mouseSwiped) {
        UIGraphicsBeginImageContext(self.view.frame.size);
        [self.theImageView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), _brush);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), _red, _green, _blue, _opacity);
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), _lastPoint.x, _lastPoint.y);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), _lastPoint.x, _lastPoint.y);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        CGContextFlush(UIGraphicsGetCurrentContext());
        self.theImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
//    UIGraphicsBeginImageContext(self.mainImage.frame.size);
//    [self.mainImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
//    [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:opacity];
//    self.mainImage.image = UIGraphicsGetImageFromCurrentImageContext();
//    self.tempDrawImage.image = nil;
//    UIGraphicsEndImageContext();
}

- (IBAction)drawSegControlValueChanged:(id)sender {
    
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    
    if (seg.selectedSegmentIndex == 1){
        
        // Initialize beginning point to center of screen
        _lastPoint = CGPointMake((self.view.frame.size.width)/2, (self.view.frame.size.height)/2);
        
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            
            double x = accelerometerData.acceleration.x;
            double y = accelerometerData.acceleration.y;
            
            CGPoint currentPoint = CGPointMake(_lastPoint.x, _lastPoint.y);
            
            // Define drawing relation to accelerometer
            if (fabs(x) > 0.1){
                currentPoint.x += x;
            }
            if (fabs(y) > 0.1){
                currentPoint.y -= y;
            } 
            
            // Keep drawing within the frame of the screen
            if (currentPoint.x > self.view.frame.size.width){
                currentPoint.x = self.view.frame.size.width;
            } else if (currentPoint.x < 0) {
                currentPoint.x = 0;
            }
            if (currentPoint.y > self.view.frame.size.height){
                currentPoint.y = self.view.frame.size.height;
            } else if (currentPoint.y < 0) {
                currentPoint.y = 0;
            }
            
            // Draw
            UIGraphicsBeginImageContext(self.view.frame.size);
            [self.theImageView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), _lastPoint.x, _lastPoint.y);
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), _brush );
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), _red, _green, _blue, 1.0);
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
            
            CGContextStrokePath(UIGraphicsGetCurrentContext());
            self.theImageView.image = UIGraphicsGetImageFromCurrentImageContext();
            [self.theImageView setAlpha:_opacity];
            UIGraphicsEndImageContext();
            
            _lastPoint = currentPoint;

        }];
    } else {
        [self.motionManager stopAccelerometerUpdates];
    }
}

-(void)initializeCamera {
    self.pickerController = [[UIImagePickerController alloc] init];
    self.pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    //    self.pickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    self.pickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    self.pickerController.delegate = self;
    [self presentViewController:self.pickerController animated:YES completion:^{
        
        NSLog(@"The image picker has completed presenting");
    }];

}

// Location Delegate method
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    //CLLocation *location = [locations lastObject];
    
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

/*
 ANIMATIONS
 */

// Push save and email buttons out
- (void) animateSaveAndEmailButtonsOut {
    
    [UIView animateWithDuration:0.5 animations:^{
        self.saveButton.center = CGPointMake(360.0, 537.5);
    }];
    [UIView animateWithDuration:0.5 animations:^{
        self.emailButton.center = CGPointMake(360.0, 484.5);
    }];
    [UIView animateWithDuration:0.5 animations:^{
        self.colorSlider.center = CGPointMake(160.0, 540.5);
        self.colorSlider.alpha = 1.0;
    }];
}

// Bring save and email buttons in
- (void) animateSaveAndEmailButtonsIn {
    
    // Animate saveButton and emailButton and colorSlider
    [UIView animateWithDuration:0.5 animations:^{
        self.saveButton.center = CGPointMake(282.5, 537.5);
    }];
    [UIView animateWithDuration:0.5 animations:^{
        self.emailButton.center = CGPointMake(282.5, 484.5);
    }];
    [UIView animateWithDuration:0.5 animations:^{
        self.colorSlider.center = CGPointMake(160.0, 640.0);
        self.colorSlider.alpha = 0.0;
    }];
}

// Animations for draw button selection/deselection
- (void) drawButtonAnimations {
    
    if (self.drawButton.selected == YES) {
        [self animateSaveAndEmailButtonsOut];
        
        [UIView animateWithDuration:0.25 animations:^{self.textButton.alpha = 0.0;}];
        
        // Animate UISegmentedControl in
        [UIView animateWithDuration:0.5 animations:^{
            self.drawSegControl.center = CGPointMake(161.0, 43.5);
            self.drawSegControl.alpha = 1.0;
        }];
    }
    else {
        [self animateSaveAndEmailButtonsIn];
        
        [UIView animateWithDuration:0.25 animations:^{self.textButton.alpha = 1.0;}];
        
        // Animate UISegmentedControlOut
        [UIView animateWithDuration:0.5 animations:^{
            self.drawSegControl.center = CGPointMake(161.0, 0.0);
            self.drawSegControl.alpha = 0.0;
        }];
    }
}

// Animations for text button selection/deselection
- (void) textButtonAnimations {
    
    if (self.textButton.selected == YES) {
        [self animateSaveAndEmailButtonsOut];
        
        [UIView animateWithDuration:0.25 animations:^{self.drawButton.alpha = 0.0;}];
        
        //Animate segControl in
        [UIView animateWithDuration:0.5 animations:^{
            self.stampSegControl.center = CGPointMake(161.0, 43.5);
            self.stampSegControl.alpha = 1.0;
        }];
        
        // Animate stamp button in
        [UIView animateWithDuration:0.5 animations:^{
            self.stampButton.center = CGPointMake(33.5, 537.5);
            self.stampButton.alpha = 1.0;
        }];
        
        // Animate textButton
        [UIView animateWithDuration:0.5 animations:^{
            self.textButton.center = CGPointMake(282.5, 42.5);
        }];
    }
    else {
        [self animateSaveAndEmailButtonsIn];
        
        [UIView animateWithDuration:0.25 animations:^{self.drawButton.alpha = 1.0;}];
        
        //Animate segControl out
        [UIView animateWithDuration:0.5 animations:^{
            self.stampSegControl.center = CGPointMake(161.0, 0.0);
            self.stampSegControl.alpha = 0.0;
        }];
        
        // Animate stamp button out
        [UIView animateWithDuration:0.5 animations:^{
            self.stampButton.center = CGPointMake(33.5, 600.0);
            self.stampButton.alpha = 0.0;
        }];
        
        // Animate textButton
        [UIView animateWithDuration:0.5 animations:^{
            self.textButton.center = CGPointMake(223.5, 42.5);
        }];
    }
}

// 

@end
