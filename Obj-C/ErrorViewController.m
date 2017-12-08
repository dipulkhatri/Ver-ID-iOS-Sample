//
//  ErrorViewController.m
//  VerIDSampleObjC
//
//  Created by Jakub Dolejs on 08/12/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

#import "ErrorViewController.h"
#import <VerID/VerID-Swift.h>

@interface ErrorViewController ()

@end

@implementation ErrorViewController

/**
 Reload Ver-ID
 
 @discussion The @c [[VerID @c shared] @c isLoaded] property observer in the app delegate will update the view controller if the loading succeeds.

 @param sender Sender of the action
 */
- (IBAction)reloadVerID:(id)sender {
    [[VerID shared] load:NULL callback:NULL];
}

@end
