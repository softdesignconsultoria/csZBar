//
//  AlmaZBarReaderViewController.m
//  BarCodeMix
//
//  Created by eCompliance on 23/01/15.

#import "AlmaZBarReaderViewController.h"
#import "CsZbar.h"

@interface AlmaZBarReaderViewController ()

@end

@implementation AlmaZBarReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Techedge Changes NSS fase 2
- (void)buttonPressed: (UIButton *) button {
    CsZBar *obj = [[CsZBar alloc] init];

    [obj toggleflash];
}

- (BOOL)shouldAutorotate{
    return NO;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation) fromInterfaceOrientation {
    //
}

@end
