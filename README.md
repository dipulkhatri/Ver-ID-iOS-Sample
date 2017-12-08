
# Ver-ID Face Authentication SDK

## Introduction
Ver-ID gives your application the ability to authenticate users by their faces. Ver-ID replaces the need to remember and type passwords. Ver-ID stores all its assets on the client making the entire face authentication process available offline.

Your application will interact with Ver-ID in two tasks:

1. To register the user's faces and add them as templates for future authentication,
2. To authenticate the user on subsequent visits.

## Tasks

### User registration
Before the user can authenticate Ver-ID needs to acquire a number of images of the user's face. These images serve as templates used for comparison at the time of authentication.
Your app instructs Ver-ID to register the user. Ver-ID then attempts to register the user and returns a result of the registration session. After successful registration the user is able to authenticate using her/his face.

Your app may register additional faces for an authenticated user to extend the probability of positive authentication under varying ambient lighting conditions.

### Authentication
Ver-ID can only authenticate users who have previously registered (see previous section).
Your app can ask Ver-ID to either authenticate a specific user or to identify and authenticate any registered user. This means your registered users may not even need to enter their user name to authenticate.

### Liveness Detection
If you need ensure that the user in front of the camera is a live person and not a picture or video impersonation you can use Ver-ID's liveness detection feature. Ver-ID will ask the user to turn in random directions.

## Adding Ver-ID in Your Xcode Project

Follow these steps to add Ver-ID to your Xcode project:

1. [Request an API secret](https://dev.ver-id.com/admin/register) for your app.
1. In Xcode open your project's **Info.plist** file and add the following entry,  substituting `[your API secret]` for the API secret received in step 1.

~~~xml
<key>com.appliedrec.verid.apiSecret</key>
<string>[your API secret]</string>
~~~
1. Select your app target, click on the **General** tab and scroll down to **Embedded binaries**.
1. Click the **+** button on the bottom of the pane and add **VerID.framework**.

## Getting Started with the Ver-ID API
There are 4 steps you will follow in a normal Ver-ID session:

1. Load Ver-ID
	- If you specify the Ver-ID API secret in your Info.plist file you can skip this step and let Ver-ID load implicitly.
	- You may explicitly load Ver-ID if you want to show a loading page while Ver-ID loads and present a specific view controller depending on the success of the load operation. See `AppDelegate` in the Ver-ID SDK sample app for an example.
	- To load Ver-ID call `VerID.shared.load`.
1. Launch a Ver-ID session
	- Implement `VerIDSessionDelegate` in your view controller.
	- Create an settings object for your particular session (e.g. `VerIDRegistrationSessionSettings`)
	- Create an instance of a `VerIDSession` subclass (e.g. `VerIDRegistrationSession`) with the settings object created in the previous step.
	- Set your view controller as the delegate of the session instance.
	- Start the session by calling the session's `start` method.
1. Receive a result from the session
	- When the session finishes it will call `session:_:didFinishWithResult` on your view controller.
	- Inspect the `result` object for details of the session's outcome.
1. Unload Ver-ID
	- You may call `VerID.shared.unload` to free up disk resources used by Ver-ID.
    
### <a name="registration"></a>Registration
Following are the exact steps your application should take to register a user.

1. Ensure your view controller implements `VerIDSessionDelegate`.
1. Check that your user is not already registered. Do not run this code on the main queue as it may hold up your app.

    #### Swift

    ~~~swift
    let userId = "myUserId"
    do {
        if try VerID.shared.isUserRegistered(userId) == true {
            // User is registered
        } else {
            // User is not registered
        }
    } catch {
        // The call failed
    }
    ~~~
    #### Objective-C
	
    ~~~objc
    NSString *userId = @"myUserId";
    NSError *error;
    // Load the registered users
    NSArray<VerIDUser *> *users = [[VerID shared] registeredVerIDUsersAndReturnError:&error];
    if (error == NULL) {
        NSEnumerator *userEnumerator = [users objectEnumerator];
        VerIDUser *user;
        // Enumerate over users and see if our user is registered
        while (user = [userEnumerator nextObject]) {
            if ([[user userId] isEqualToString:[VerIDUser defaultUserId]]) {
                // User is registered
                return;
            }
        }
        // User is not registered
    } else {
        // The call failed
    }
	~~~
1. If the user is already registered authenticate her/him before registering new faces. See <a href="#authentication">Authentication</a>.
1. Create registration settings.

	#### Swift
	
	~~~swift
	let settins = VerIDRegistrationSessionSettings(userId: userId)
	// If you wish to show a guide on how to register to the user
	settings.showGuide = true
	// If you wish to show the result of the session to the user
	settings.showResult = true
	~~~
	
	#### Objective-C
	
	~~~objc
	VerIDRegistrationSessionSettings *settings = [[VerIDRegistrationSessionSettings alloc] initWithUserId:[VerIDUser defaultUserId] livenessDetection:VerIDLivenessDetectionRegular showGuide:NO showResult:NO];
	// If you wish to show a guide on how to register to the user
	settings.showGuide = YES;
	// If you wish to show the result of the session to the user
	settings.showResult = YES;
	~~~
1. Create a registration session instance, set its delegate and start the session.

	#### Swift
	
	~~~swift
	let session = VerIDRegistrationSession(settings: settings)
	session.delegate = self
	session.start()
	~~~
    
    #### Objective-C
    
    ~~~objc
    VerIDRegistrationSession *session = [[VerIDRegistrationSession alloc] initWithSettings:settings];
    [session setDelegate:self];
    [session start];
    ~~~
1. Receive the result of the session in your view controller.

	#### Swift
	
	~~~swift
	func session(_ session: VerIDSession, didFinishWithResult result: VerIDSessionResult) {
        // Inspect the result
        // Some examples:
        if result.positive {
        	// The user finished the registration
        }
        if let imageURL = result.images.first {
        	// This is the URL of the first "selfie" image collected in the session
        	// The image will be deleted next time Ver-ID is loaded or when you call unload. 
        	// Copy it somewhere if you wish to retain it across sessions.
        }
    }
	~~~
    
	#### Objective-C
	    
	~~~objc
	- (void)session:(VerIDSession * _Nonnull)session didFinishWithResult:(VerIDSessionResult * _Nonnull)result {
	    // Inspect the result
		// Some examples:
		if ([result positive]) {
		    // The user finished the registration
		}
		NSURL *imageURL = [[result images] firstObject];
		if (imageURL != NULL) {
		    // This is the URL of the first "selfie" image collected in the session
		    // The image will be deleted next time Ver-ID is loaded or when you call unload. 
		    // Copy it somewhere if you wish to retain it across sessions.
		}
	}
	~~~

### <a name="authentication"></a>Authentication
Follow these steps to authenticate any user who previously registered in your app without asking for a user name or password.

1. Ensure the user is registered (see step 2 of [Registration](#registration))
1. Create authentication settings.
	#### Swift
	
	~~~swift
	let settings = VerIDAuthenticationSessionSettings(userId: userId)
	// If you wish to show a guide on how to authenticate to the user
	settings.showResult = true
	// If you wish to show the result of the session to the user
	settings.showGuide = true
	~~~
	
	#### Objective-C

	~~~objc
	VerIDAuthenticationSessionSettings *settings = [[VerIDAuthenticationSessionSettings alloc] initWithUserId:userId livenessDetection:VerIDLivenessDetectionRegular];
	// If you wish to show a guide on how to authenticate to the user
	settings.showGuide = YES;
	// If you wish to show the result of the session to the user
	settings.showResult = YES;
	~~~
1. Create an authentication session instance, set its delegate and start the session.

	#### Swift
	
	~~~swift
	let session = VerIDAuthenticationSession(settings: settings)
	session.delegate = self
	session.start()
	~~~
	
	#### Objective-C

	~~~objc
	VerIDAuthenticationSession *session = [[VerIDAuthenticationSession alloc] initWithSettings:settings];
	[session setDelegate:self];
	[session start];
	~~~
1. Receive the result of the session in your view controller.

	#### Swift
	
	~~~swift
	func session(_ session: VerIDSession, didFinishWithResult result: VerIDSessionResult) {
        // Inspect the result
        // Some examples:
        if result.positive {
        	// The user has authenticated
        }
        if let imageURL = result.images.first {
        	// This is the URL of the first "selfie" image collected in the session
        	// The image will be deleted next time Ver-ID is loaded or when you call unload. 
        	// Copy it somewhere if you wish to retain it across sessions.
        }
    }
	~~~
    
	#### Objective-C
	    
	~~~objc
	- (void)session:(VerIDSession * _Nonnull)session didFinishWithResult:(VerIDSessionResult * _Nonnull)result {
	    // Inspect the result
		// Some examples:
		if ([result positive]) {
		    // The user has authenticated
		}
		NSURL *imageURL = [[result images] firstObject];
		if (imageURL != NULL) {
		    // This is the URL of the first "selfie" image collected in the session
		    // The image will be deleted next time Ver-ID is loaded or when you call unload. 
		    // Copy it somewhere if you wish to retain it across sessions.
		}
	}
	~~~

### <a name="liveness_detection"></a>Liveness Detection
Follow these steps to ensure the user holding the device is a live person.

1. Create a liveness detection session instance, set its delegate and start the session.

	#### Swift
	
	~~~swift
	let session = VerIDLivenessDetectionSession(settings: nil)
	session.delegate = self
	session.start()
	~~~
	
	#### Objective-C

	~~~objc
	VerIDLivenessDetectionSession *session = [[VerIDLivenessDetectionSession alloc] initWithSettings:NULL];
	[session setDelegate:self];
	[session start];
	~~~
1. Receive the result of the session in your view controller.

	#### Swift
	
	~~~swift
	func session(_ session: VerIDSession, didFinishWithResult result: VerIDSessionResult) {
        // Inspect the result
        // Some examples:
        if result.positive {
        	// The user provided a live "selfie"
        }
        if let imageURL = result.images.first {
        	// This is the URL of the first "selfie" image collected in the session
        	// The image will be deleted next time Ver-ID is loaded or when you call unload. 
        	// Copy it somewhere if you wish to retain it across sessions.
        }
    }
	~~~
    
	#### Objective-C
	    
	~~~objc
	- (void)session:(VerIDSession * _Nonnull)session didFinishWithResult:(VerIDSessionResult * _Nonnull)result {
	    // Inspect the result
		// Some examples:
		if ([result positive]) {
		    // The user provided a live "selfie"
		}
		NSURL *imageURL = [[result images] firstObject];
		if (imageURL != NULL) {
		    // This is the URL of the first "selfie" image collected in the session
		    // The image will be deleted next time Ver-ID is loaded or when you call unload. 
		    // Copy it somewhere if you wish to retain it across sessions.
		}
	}
	~~~

<!--## Documentation

Full API documentation is available on the project's [Github page](https://appliedrecognition.github.io/Ver-ID-iOS-Sample/com.appliedrec.ver_id.VerID.html).-->

