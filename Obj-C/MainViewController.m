//
//  MainViewController.m
//  VerIDSampleObjC
//
//  Created by Jakub Dolejs on 07/12/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

// MARK: - Interface builder views

@property(weak) IBOutlet UIImageView *imageView;
@property(weak) IBOutlet UITextView *textView;
@property(weak) IBOutlet UIButton *registerButton;
@property(weak) IBOutlet UIButton *authenticateButton;

// MARK: -

/// Settings to use for user registration
@property VerIDRegistrationSessionSettings *registrationSettings;

// MARK: -

@end

@implementation MainViewController

// MARK: - Override from UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.registrationSettings = [[VerIDRegistrationSessionSettings alloc] initWithUserId:[VerIDUser defaultUserId] livenessDetection:VerIDLivenessDetectionRegular showGuide:YES showResult:YES];
    [self updateDisplay];
}

// MARK: -


/**
 Find out whether the user registered their face. If the user is registered display their profile photo and enable the Authenticate button.
 */
- (void)updateDisplay {
    // Do not block the main queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        // Load the registered users
        NSArray<VerIDUser *> *users = [[VerID shared] registeredVerIDUsersAndReturnError:&error];
        if (error == NULL) {
            NSEnumerator *userEnumerator = [users objectEnumerator];
            VerIDUser *user;
            // Enumerate over users and see if our user is registered
            while (user = [userEnumerator nextObject]) {
                if ([[user userId] isEqualToString:[VerIDUser defaultUserId]]) {
                    // The user is registered
                    // Load the user's profile picture
                    UIImage *image = [[VerID shared] userProfilePicture:[VerIDUser defaultUserId]];
                    // Update the registration session settings to append the faces to the current user when registering more faces
                    [self registrationSettings].appendIfUserExists = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self imageView] setImage:image];
                        [[self textView] setHidden:YES];
                        [[self imageView] setHidden:NO];
                        [[self registerButton] setTitle:@"Register more faces" forState:UIControlStateNormal];
                        // Enable the Authenticate button
                        [[self authenticateButton] setEnabled:YES];
                        // Add a Reset button to enable deleting the registered user
                        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(reset:)]];
                    });
                    return;
                }
            }
            // Update the registration settings to create a new user when registering faces
            [self registrationSettings].appendIfUserExists = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self imageView] setHidden:YES];
                [[self textView] setHidden:NO];
                [[self registerButton] setTitle:@"Register" forState:UIControlStateNormal];
                // Disable the authentication button. The user must be registered to authenticate.
                [[self authenticateButton] setEnabled:NO];
                [[self navigationItem] setRightBarButtonItem:NULL];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Show the error view controller and let the user reload Ver-ID.
                UIViewController *errorViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"error"];
                [[self navigationController] setViewControllers:@[errorViewController] animated:NO];
            });
        }
    });
}

// MARK: - Button actions

/**
 Reset the registration

 @discussion This will delete the registered user
 
 @param sender Sender of the action
 */
- (IBAction)reset:(id)sender {
    [[VerID shared] deregisterUser:[VerIDUser defaultUserId] callback:^void(NSError *error){
        [self updateDisplay];
    }];
}

/**
 Register faces
 
 @discussion Add more faces if the user is already registered

 @param sender Sender of the action
 */
- (IBAction)registerFaces:(id)sender {
    VerIDRegistrationSession *session = [[VerIDRegistrationSession alloc] initWithSettings:[self registrationSettings]];
    [session setDelegate:self];
    [session start];
}

/**
 Authenticate the registered user

 @param sender Sender of the action
 */
- (IBAction)authenticate:(id)sender {
    NSInteger requiredPoseCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"livenessDetectionPoses"];
    VerIDAuthenticationSessionSettings *settings = [[VerIDAuthenticationSessionSettings alloc] initWithUserId:[VerIDUser defaultUserId] livenessDetection:VerIDLivenessDetectionRegular];
    [settings setShowGuide:YES];
    [settings setShowResult:YES];
    [settings setNumberOfResultsToCollect:requiredPoseCount + 1];
    VerIDAuthenticationSession *session = [[VerIDAuthenticationSession alloc] initWithSettings:settings];
    [session setDelegate:self];
    [session start];
}

// MARK: - VerIDSessionDelegate

/**
 Called when a Ver-ID session finishes
 
 @discussion Inspect the session result to find out more about the outcome of the session and to get the collected images

 @param session The session that finished
 @param result The session result
 */
- (void)session:(VerIDSession * _Nonnull)session didFinishWithResult:(VerIDSessionResult * _Nonnull)result {
    [self updateDisplay];
}

@end
