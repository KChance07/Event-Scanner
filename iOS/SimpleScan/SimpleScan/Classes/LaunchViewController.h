//
//  LaunchViewController.h
//  SimpleScan
//
//  Created by Michael Critz on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScanViewController.h"
#import "SFRestAPI.h"

@interface LaunchViewController : UIViewController <scanViewDataSource,SFRestDelegate>
{
    // NSString *presenceID;
    NSArray *contactArray;
}

// Inventory

// @property (nonatomic, retain) NSDictionary *createProductHistory;
@property (nonatomic, retain) NSString *sfdcProductID;
@property (nonatomic, retain) NSString *sfdcProduct;
@property (nonatomic, assign) double sfdcQuantity;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

// @property (nonatomic, retain) NSString *quantityToUpdate;

// Contacts
@property (nonatomic, retain) NSDictionary *contactInfo;
@property (nonatomic, retain) NSString *contactStatus;
// @property (nonatomic, retain) NSString *presenceToUpdate;


@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UILabel *emailLabel;
@property (retain, nonatomic) IBOutlet UIButton *checkinButton;
- (IBAction)checkinButtonPressed:(UIButton *)sender;
@property (retain, nonatomic) IBOutlet UILabel *quantityLabel;
- (IBAction)quantityInputChanged:(id)sender;
@property (retain, nonatomic) IBOutlet UITextField *quantityInput;
- (IBAction)backGroundTap:(id)sender;
@property (retain, nonatomic) IBOutlet UIStepper *quantityStepper;
- (IBAction)quantityChanged:(id)sender;
@property (nonatomic, retain) IBOutlet UIButton *scanButton;
-(IBAction)scanButtonPressed:(id)sender;
- (void)alertOnFailedRequest;
- (void)alertOnSuccess;
- (void)failConfirmation;

@end
