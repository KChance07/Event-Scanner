//
//  LaunchViewController.m
//  SimpleScan
//
//  Created by Michael Critz on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LaunchViewController.h"
#import "ScanViewController.h"

@interface LaunchViewController ()

@end

@implementation LaunchViewController

@synthesize contactInfo;
@synthesize contactStatus;
@synthesize nameLabel;
@synthesize emailLabel;
@synthesize checkinButton;
@synthesize quantityLabel;
@synthesize quantityInput;
@synthesize quantityStepper;
@synthesize quantityScanned;
@synthesize scanButton;
@synthesize presenceToUpdate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [quantityStepper setMinimumValue:0];
    [quantityStepper setContinuous:YES];
    self.title = @"Simple Scan";

    UINavigationBar *navBar = [[self navigationController] navigationBar];
    UIImage *backgroundImage = [UIImage imageNamed:@"navigation_bar"];
    [navBar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];

    checkinButton.hidden = YES;
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - Memory Management

- (void)viewDidUnload
{
    [self setNameLabel:nil];
    [self setEmailLabel:nil];
    [self setCheckinButton:nil];
    [self setScanButton:nil];
    [self setQuantityStepper:nil];
    [self setQuantityLabel:nil];
    [self setQuantityInput:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
- (void)dealloc {
    [nameLabel release];
    [emailLabel release];
    [checkinButton release];
    [scanButton release];
    [contactStatus release];
    [contactInfo release];
    [quantityStepper release];
    [quantityLabel release];
    [quantityInput release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Scan Action
- (void)scanButtonPressed:(id)sender {
    NSLog(@"Scan Button Pressed");
    ScanViewController *scanView = [[ScanViewController alloc] init];
    scanView.delegate = self;
    [self presentViewController:scanView animated:YES completion:^{}];
}

#pragma mark - Deal with Results
-(void)parseContactData:(NSArray *)returnedArray {
    checkinButton.hidden = YES;
    // NSLog(@"parseContactData called. returnedArray: \n %@",returnedArray);
    for (NSDictionary *obj in returnedArray) {
        // NSLog(@"presenceID: %@",presenceID);
        contactInfo = [[NSDictionary alloc] initWithDictionary:[obj objectForKey:@"Contact__r"]];
        contactStatus = [[NSString alloc] initWithFormat:@"%@",[obj objectForKey:@"Status__c"]];
        NSLog(@"contactStatus: %@",contactStatus);
        // NSLog(@"contactInfo: %@",contactInfo);
        nameLabel.text = [[[NSString alloc] initWithFormat:@"%@ %@",[contactInfo objectForKey:@"FirstName"],[contactInfo objectForKey:@"LastName"],nil] autorelease];
        if ([contactStatus isEqualToString:@"Attended"]){
            // checkinButton.hidden = YES;
            emailLabel.text = @"Is Already Checked In";
            return;
        } else {
            emailLabel.text = [contactInfo objectForKey:@"Email"];
            checkinButton.hidden = NO;
        }
        
    }
    // nameLabel.text = [[returnedArray objectForKey:@"Property__r"] objectForKey:@"Name"];
}
-(void)setpresenceID:(NSString *)returnedPresenceID{
    presenceToUpdate = returnedPresenceID;
}

#pragma mark - User Actions
- (void)quantityChanged:(id)sender {
    quantityScanned = quantityStepper.value;
    [self updateQuantity];
}
- (IBAction)quantityInputChanged:(id)sender {
    quantityScanned = [quantityInput.text doubleValue];
    [self updateQuantity];
}

- (IBAction)backGroundTap:(id)sender {
    [quantityInput resignFirstResponder];
}

-(void)updateQuantity {
    NSLog(@"Quantity: %f",quantityScanned);
    quantityInput.text = [NSString stringWithFormat:@"%@",[NSNumber numberWithDouble:quantityScanned]];
    quantityStepper.value = quantityScanned;
}

- (IBAction)checkinButtonPressed:(UIButton *)sender {
    NSLog(@"checkinButtonPressed");
     
     // tell sfdc to change status to "Attended"
     NSDictionary *updatedFields = [NSDictionary dictionaryWithObjectsAndKeys:@"Attended", @"Status__c", nil];
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForUpdateWithObjectType:@"Presence__c" objectId:presenceToUpdate fields:updatedFields];
    [[SFRestAPI sharedInstance] send:request delegate:self];
    // requestForUpdateWithObjectType does not return a json.
    
    // second request to confirm change in status
    NSString *confirmationQuery = [NSString stringWithFormat:@"Select id, Status__c  From Presence__c WHERE ID = '%@'",presenceToUpdate];
    SFRestRequest *requestToConfirmUpdate = [[SFRestAPI sharedInstance] requestForQuery:confirmationQuery];
    [[SFRestAPI sharedInstance] send:requestToConfirmUpdate delegate:self];
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    NSLog(@"requestToConfirmUpdate: %@",jsonResponse);

    NSArray *sfdcResponse = [jsonResponse objectForKey:@"records"];
    NSLog(@"request:didLoadResponse: # of records: %d", sfdcResponse.count);
    for (NSDictionary *obj in sfdcResponse) {
        NSLog(@"obj: %@",obj);
        NSString *presenseStatus = [[[NSString alloc] initWithFormat:@"%@",[obj objectForKey:@"Status__c"]] autorelease];
        if ([presenseStatus isEqualToString:@"Attended"]) {
            NSLog(@"presenseStatus == Attended");
            [self sucessfulConfirmation];
        } else {
            NSLog(@"presenseStatus != 'Attended' actual value: %@",presenseStatus);
            [self sucessfulConfirmation];
        }
    }
}


#pragma mark - SFDC SDK Error Handling

- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    NSLog(@"request:didFailLoadWithError: %@", error);
    [self alertOnFailedRequest];
}

- (void)requestDidCancelLoad:(SFRestRequest *)request {
    NSLog(@"requestDidCancelLoad: %@", request);
    [self alertOnFailedRequest];
}

- (void)requestDidTimeout:(SFRestRequest *)request {
    NSLog(@"requestDidTimeout: %@", request);
    [self alertOnFailedRequest];
}

- (void)alertOnFailedRequest {
    checkinButton.hidden = YES;

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"I didn't understand that code." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
}

- (void)failConfirmation {
    checkinButton.hidden = NO;
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"So Sorry!" message:@"I wasn't able to confirm this invite. Try again in a minute." delegate:self cancelButtonTitle:@"D’oh!" otherButtonTitles:nil] autorelease];
    [alert show];
}

- (void)sucessfulConfirmation {
    checkinButton.hidden = YES;

    NSString *sucessMessage = [NSString stringWithFormat:@"%@ is checked in.",[contactInfo objectForKey:@"FirstName"]];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Sucess!" message:sucessMessage delegate:self cancelButtonTitle:@"Thank You" otherButtonTitles: nil] autorelease];
    [alert show];
    
    nameLabel.text = @"Scan to Check-In";
    emailLabel.text = @"";
}
@end
