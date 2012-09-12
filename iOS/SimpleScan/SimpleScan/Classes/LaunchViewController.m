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
@synthesize spinner;

@synthesize sfdcProductID, sfdcProduct, sfdcQuantity;

@synthesize contactInfo;
@synthesize contactStatus;
@synthesize nameLabel;
@synthesize emailLabel;
@synthesize checkinButton;
@synthesize quantityLabel;
@synthesize quantityInput;
@synthesize quantityStepper;
@synthesize scanButton;
// @synthesize presenceToUpdate;

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
    self.title = @"Simple Inventory";

    UINavigationBar *navBar = [[self navigationController] navigationBar];
    UIImage *backgroundImage = [UIImage imageNamed:@"navigation_bar"];
    [navBar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
    [self resetUI];
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
    // [self setQuantityToUpdate:nil];
    
    // [self setCreateProductHistory:nil];
    [self setSfdcProduct:nil];
    [self setSfdcProductID:nil];
    
    [self setSpinner:nil];
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
    // [quantityToUpdate release];
    // [createProductHistory release];
    [sfdcProductID release];
    [sfdcProduct release];
    
    [spinner release];
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
    checkinButton.hidden = NO;
    quantityStepper.hidden = NO;
    sfdcQuantity = 0;
    quantityInput.text = @"0";
    quantityInput.hidden = NO;
    quantityLabel.hidden = NO;
    
    // NSLog(@"parseContactData called. returnedArray: \n %@",returnedArray);
    for (NSDictionary *obj in returnedArray) {
        /* 
         // Contacts
        contactInfo = [[NSDictionary alloc] initWithDictionary:[obj objectForKey:@"Contact__r"]];
        contactStatus = [[NSString alloc] initWithFormat:@"%@",[obj objectForKey:@"Status__c"]];
        NSLog(@"contactStatus: %@",contactStatus);
        nameLabel.text = [[[NSString alloc] initWithFormat:@"%@ %@",[contactInfo objectForKey:@"FirstName"],[contactInfo objectForKey:@"LastName"],nil] autorelease];
        if ([contactStatus isEqualToString:@"Attended"]){
            // checkinButton.hidden = YES;
            emailLabel.text = @"Is Already Checked In";
            return;
        } else {
            emailLabel.text = [contactInfo objectForKey:@"Email"];
            checkinButton.hidden = NO;
        }
        */
        
        // Products
        sfdcProductID = [[NSString alloc] initWithFormat:@"%@",[obj objectForKey:@"Id"]];
        NSLog(@"sfdcProductID: %@",sfdcProductID);
        
        sfdcProduct = [[NSString alloc] initWithFormat:@"%@",[obj objectForKey:@"Name"]];
        nameLabel.text = sfdcProduct;
        emailLabel.text = [obj objectForKey:@"ProductCode"];
    }
    // [returnedArray release];
}
//-(void)setpresenceID:(NSString *)returnedPresenceID{
//    presenceToUpdate = returnedPresenceID;
//}

#pragma mark - User Actions
- (void)quantityChanged:(id)sender {
    sfdcQuantity = quantityStepper.value;
    [self updateQuantity];
}
- (IBAction)quantityInputChanged:(id)sender {
    sfdcQuantity = [quantityInput.text doubleValue];
    [self updateQuantity];
}

- (IBAction)backGroundTap:(id)sender {
    [quantityInput resignFirstResponder];
}

-(void)updateQuantity {
    NSLog(@"Quantity: %f",sfdcQuantity);
    quantityInput.text = [NSString stringWithFormat:@"%@",[NSNumber numberWithDouble:sfdcQuantity]];
    quantityStepper.value = sfdcQuantity;
}

- (IBAction)checkinButtonPressed:(UIButton *)sender {
    NSLog(@"checkinButtonPressed");
    checkinButton.hidden = YES;
    spinner.hidden = NO;
    [spinner startAnimating];
     // tell sfdc to change status to "Attended"
    /* 
     NSDictionary *updatedFields = [NSDictionary dictionaryWithObjectsAndKeys:@"Attended", @"Status__c", nil];
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForUpdateWithObjectType:@"Presence__c" objectId:presenceToUpdate fields:updatedFields];
    [[SFRestAPI sharedInstance] send:request delegate:self];
    // requestForUpdateWithObjectType does not return a json.
    */
    
    NSDictionary *productHistoryFields = [NSDictionary dictionaryWithObjectsAndKeys:
                                          sfdcProductID, @"Product__c",
                                          [[[NSString alloc] initWithFormat:@"%f",sfdcQuantity] autorelease], @"Quantity__c",
                                          nil];

    NSLog(@"createProductHistory: %@",productHistoryFields);
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForCreateWithObjectType:@"Inventory_History__c"
                                fields:productHistoryFields];
    [[SFRestAPI sharedInstance] send:request delegate:self];
     
    // second request to confirm change in status
    /*
     NSString *confirmationQuery = [NSString stringWithFormat:@"Select id, Status__c  From Presence__c WHERE ID = '%@'",presenceToUpdate];
    SFRestRequest *requestToConfirmUpdate = [[SFRestAPI sharedInstance] requestForQuery:confirmationQuery];
    [[SFRestAPI sharedInstance] send:requestToConfirmUpdate delegate:self];
     */
    /*
     NSDictionary *fields = [NSDictionary dictionaryWithObjectsAndKeys:
     @"John", @"FirstName",
     lastName, @"LastName",
     nil];
     
     SFRestRequest* request = [[SFRestAPI sharedInstance] requestForCreateWithObjectType:@"Contact" fields:fields];
     [self sendSyncRequest:request];
     STAssertEqualObjects(_requestListener.returnStatus, kTestRequestStatusDidLoad, @"request failed");
     
     // make sure we got an id
     NSString *contactId = [[[(NSDictionary *)_requestListener.jsonResponse objectForKey:@"id"] retain] autorelease];
     STAssertNotNil(contactId, @"id not present");
     */
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    NSLog(@"requestToConfirmUpdate: %@",jsonResponse);

    NSArray *errors = [jsonResponse objectForKey:@"errors"];
    NSLog(@"request:didLoadResponse: # of errors: %@", errors);
    NSString *updateSuccess = [[[NSString alloc] initWithFormat:@"%@",[jsonResponse objectForKey:@"success"]]autorelease];
    NSLog(@"updateSuccess: %@", updateSuccess);
    
    if ([updateSuccess isEqualToString:@"1"]) {
        [self alertOnSuccess];
    } else {
        [self alertOnFailedRequest];
    }
    /*
     // Contacts
    NSLog(@"request:didLoadResponse: # of records: %d", sfdcResponse.count);
    for (NSDictionary *obj in sfdcResponse) {
        NSLog(@"obj: %@",obj);
        NSString *presenseStatus = [[[NSString alloc] initWithFormat:@"%@",[obj objectForKey:@"Status__c"]] autorelease];
        if ([presenseStatus isEqualToString:@"Attended"]) {
            NSLog(@"presenseStatus == Attended");
            [self successfulConfirmation];
        } else {
            NSLog(@"presenseStatus != 'Attended' actual value: %@",presenseStatus);
            [self successfulConfirmation];
        }
    }
     */
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
    [self resetUI];

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"I didn't understand that code." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
    
}

- (void)failConfirmation {
    spinner.hidden = YES;
    [spinner stopAnimating];
    checkinButton.hidden = NO;
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"So Sorry!" message:@"I wasn't able to confirm this scan. Try again in a minute." delegate:self cancelButtonTitle:@"D’oh!" otherButtonTitles:nil] autorelease];
    [alert show];
}

- (void)alertOnSuccess {
    spinner.hidden = YES;
    checkinButton.hidden = YES;

    NSString *sucessMessage = [NSString stringWithFormat:@"%d %@ confirmed in inventory.",(int)sfdcQuantity,sfdcProduct];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Sucess!" message:sucessMessage delegate:self cancelButtonTitle:@"Thank You" otherButtonTitles: nil] autorelease];
    [alert show];
    [self resetUI];
}
- (void)resetUI {
    spinner.hidden = YES;
    [spinner stopAnimating];
    sfdcQuantity = 0;
    nameLabel.text = @"Ready to Scan";
    emailLabel.text = @"UPC";
    quantityLabel.hidden = YES;
    quantityInput.text = 0;
    quantityInput.hidden = YES;
    quantityStepper.value = 0;
    quantityStepper.hidden = YES;
    checkinButton.hidden = YES;
}
@end
