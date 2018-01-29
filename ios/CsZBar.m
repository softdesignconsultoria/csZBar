#import "CsZBar.h"
#import <AVFoundation/AVFoundation.h>
#import "AlmaZBarReaderViewController.h"

#pragma mark - State

@interface CsZBar ()
@property bool scanInProgress;
@property NSString *scanCallbackId;
@property AlmaZBarReaderViewController *scanReader;

@end

#pragma mark - Synthesize

@implementation CsZBar

@synthesize scanInProgress;
@synthesize scanCallbackId;
@synthesize scanReader;

#pragma mark - Cordova Plugin

- (void)pluginInitialize {
    self.scanInProgress = NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    return;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}

#pragma mark - Plugin API

- (void)scan: (CDVInvokedUrlCommand*)command;
{
    if (self.scanInProgress) {
        [self.commandDelegate
         sendPluginResult: [CDVPluginResult
                            resultWithStatus: CDVCommandStatus_ERROR
                            messageAsString:@"A scan is already in progress."]
         callbackId: [command callbackId]];
    } else {
        self.scanInProgress = YES;
        self.scanCallbackId = [command callbackId];
        self.scanReader = [AlmaZBarReaderViewController new];

        self.scanReader.readerDelegate = self;
        self.scanReader.supportedOrientationsMask = ZBarOrientationMask(UIInterfaceOrientationPortrait);

        // Get user parameters
        NSDictionary *params = (NSDictionary*) [command argumentAtIndex:0];
        NSString *camera = [params objectForKey:@"camera"];
        if([camera isEqualToString:@"front"]) {
            // We do not set any specific device for the default "back" setting,
            // as not all devices will have a rear-facing camera.
            self.scanReader.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;

        NSString *flash = [params objectForKey:@"flash"];

        if ([flash isEqualToString:@"on"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        } else if ([flash isEqualToString:@"off"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        }else if ([flash isEqualToString:@"auto"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        }

        // Hack to hide the bottom bar's Info button... originally based on http://stackoverflow.com/a/16353530
	NSInteger infoButtonIndex;
        if ([[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending) {
            infoButtonIndex = 1;
        } else {
            infoButtonIndex = 3;
        }
        UIView *infoButton = [[[[[self.scanReader.view.subviews objectAtIndex:2] subviews] objectAtIndex:0] subviews] objectAtIndex:infoButtonIndex];
        [infoButton setHidden:YES];

        //UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; [button setTitle:@"Press Me" forState:UIControlStateNormal]; [button sizeToFit]; [self.view addSubview:button];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;

        UILabel *textTitleLabel =[[UILabel alloc] initWithFrame:CGRectMake(10, 10, screenWidth - 20, 20)];
        [textTitleLabel setText:[params objectForKey:@"text_title"]];
        [textTitleLabel setTextAlignment:NSTextAlignmentCenter];
        [textTitleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [textTitleLabel setTextColor:[UIColor whiteColor]];
        [textTitleLabel setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.2]];
        [textTitleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:24]];
        [textTitleLabel setNumberOfLines:0];
        [textTitleLabel sizeToFit];
        int x = (screenWidth - textTitleLabel.frame.size.width) / 2;
        textTitleLabel.frame = CGRectMake(x, 10, textTitleLabel.frame.size.width, textTitleLabel.frame.size.height);

        int buttonsWidth = 80;
        int buttonsHeight = 30;

        UIView *superv  = [[[infoButton superview]superview]superview];

        [superv.subviews.firstObject setFrame:CGRectMake(0, 0, screenWidth, screenHeight - buttonsHeight - 20)]; // reposiciona o painel da camera
        [superv.subviews.lastObject removeFromSuperview]; //remove a barra dos botoes nativos da camera

        UIView *newBar = [[UIView alloc]initWithFrame:CGRectMake(0,
                                               screenHeight - buttonsHeight - 20,
                                               screenWidth,
                                                buttonsHeight + 20)];
        [newBar setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.8]];
        [superv addSubview:newBar];

        UILabel *textInstructionsLabel =[[UILabel alloc] initWithFrame:CGRectMake(10, 10, screenWidth - 20, 20)];
        [textInstructionsLabel setText:[params objectForKey:@"text_instructions"]];
        [textInstructionsLabel setTextAlignment:NSTextAlignmentCenter];
        [textInstructionsLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [textInstructionsLabel setTextColor:[UIColor whiteColor]];
        [textInstructionsLabel setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.2]];
        [textInstructionsLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16]];
        [textInstructionsLabel setNumberOfLines:0];
        [textInstructionsLabel sizeToFit];
        x = (screenWidth - textInstructionsLabel.frame.size.width) / 2;
        int y = screenHeight - newBar.frame.size.height - textInstructionsLabel.frame.size.height - 10;
        textInstructionsLabel.frame = CGRectMake(x, y, textInstructionsLabel.frame.size.width, textInstructionsLabel.frame.size.height);

        UIButton *buttonFlash = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [buttonFlash addTarget:self action:@selector(toggleflash) forControlEvents:UIControlEventTouchUpInside];
        [buttonFlash setTitle:@"Flash" forState:UIControlStateNormal];
        [buttonFlash setFrame:CGRectMake(screenWidth - buttonsWidth - 10,
                                         (newBar.frame.size.height - buttonsHeight) / 2,
                                         buttonsWidth,
                                         buttonsHeight)];
        [newBar addSubview:buttonFlash];

        UIButton *buttonCancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [buttonCancel addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [buttonCancel setTitle:@"Cancelar" forState:UIControlStateNormal];
        [buttonCancel setFrame:CGRectMake(10,
                                         (newBar.frame.size.height - buttonsHeight) / 2,
                                         buttonsWidth,
                                         buttonsHeight)];
        [newBar addSubview:buttonCancel];

        BOOL drawSight = [params objectForKey:@"drawSight"] ? [[params objectForKey:@"drawSight"] boolValue] : true;

        if (drawSight) {
            CGFloat dim = screenWidth < screenHeight ? screenWidth / 1.1 : screenHeight / 1.1;
            UIView *polygonView = [[UIView alloc] initWithFrame: CGRectMake  ( (screenWidth/2) - (dim/2), (screenHeight/2) - (dim/2), dim, dim)];

            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0,dim / 2, dim, 1)];
            lineView.backgroundColor = [UIColor redColor];
            [polygonView addSubview:lineView];

            self.scanReader.cameraOverlayView = polygonView;
        }

        [self.scanReader.cameraOverlayView.superview addSubview:textTitleLabel];
        [self.scanReader.cameraOverlayView.superview addSubview:textInstructionsLabel];

        [self.viewController presentViewController:self.scanReader animated:YES completion:nil];
    }
}

- (void)toggleflash {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    [device lockForConfiguration:nil];
    if (device.torchAvailable == 1) {
        if (device.torchMode == 0) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
        }
    }

    [device unlockForConfiguration];

}

- (void)cancel {
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_ERROR
                               messageAsString: @"cancelled"]];
    }];
}

#pragma mark - Helpers

- (void)sendScanResult: (CDVPluginResult*)result {
    [self.commandDelegate sendPluginResult: result callbackId: self.scanCallbackId];
}

#pragma mark - ZBarReaderDelegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    return;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
    if ([self.scanReader isBeingDismissed]) {
        return;
    }

    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];

    ZBarSymbol *symbol = nil;
    for (symbol in results) break; // get the first result

    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsString: symbol.data]];
    }];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController*)picker {
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                                resultWithStatus: CDVCommandStatus_ERROR
                                messageAsString: @"cancelled"]];
    }];
}

- (void) readerControllerDidFailToRead:(ZBarReaderController*)reader withRetry:(BOOL)retry {
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                                resultWithStatus: CDVCommandStatus_ERROR
                                messageAsString: @"Failed"]];
    }];
}

@end
