//
//  AppDelegate.m
//  Ver-ID Sample Obj-C
//
//  Created by Jakub Dolejs on 05/12/2016.
//  Copyright © 2016 Applied Recognition, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <VerID/VerID-Swift.h>

@interface AppDelegate ()

@property BOOL observingUserDefaults;

@end

@implementation AppDelegate

static void *VerIDLoadedContext = &VerIDLoadedContext;
static void *UserDefaultsContext = &UserDefaultsContext;

// MARK: - Application delegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Load Ver-ID
    // API secret is read from the app's Info.plist
    [[VerID shared] load:NULL callback:NULL];
    // Observe `isLoaded` property of the `VerID` singleton instance
    [[VerID shared] addObserver:self forKeyPath:@"isLoaded" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld) context:VerIDLoadedContext];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Remove Ver-ID load observer
    [[VerID shared] removeObserver:self forKeyPath:@"isLoaded"];
    // Unload Ver-ID
    [[VerID shared] unload];
    // Remove user defaults observer
    if ([self observingUserDefaults]) {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"securityLevel"];
        [self setObservingUserDefaults:NO];
    }
}

// MARK: - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == VerIDLoadedContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
            UIStoryboard *storyboard = navigationController.storyboard;
            UIViewController *initialViewController;
            if ([[VerID shared] isLoaded]) {
                // Ver-ID successfully finished loading.
                // Register and observe user defaults.
                NSInteger secLevel = [[VerID shared] securityLevel];
                [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjects:@[[NSString stringWithFormat:@"%ld", (long)secLevel],@"1"] forKeys:@[@"securityLevel",@"livenessDetectionPoses"]]];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"securityLevel" options:NSKeyValueObservingOptionNew context:&UserDefaultsContext];
                [self setObservingUserDefaults:YES];
                // Instantiate the main view controller.
                initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"start"];
            } else if ([[VerID shared] loadError] != NULL) {
                // Ver-ID failed to load. Instantiate the error view controller.
                initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"error"];
            } else {
                return;
            }
            [navigationController setViewControllers:@[initialViewController] animated:NO];
        });
    } else if (context == UserDefaultsContext) {
        [[VerID shared] setSecurityLevel:[[NSUserDefaults standardUserDefaults] integerForKey:keyPath]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
