//
//  AppDelegate.m
//  urecord
//
//  Created by liangfen on 17/5/2.
//  Copyright © 2017年 Imagination Studio. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()<AVCaptureFileOutputDelegate, AVCaptureFileOutputRecordingDelegate>


@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *recordButton;
@property (weak) IBOutlet NSButton *replayButton;
@property (weak) IBOutlet NSTextField *timeLabel;

@property (retain) AVCaptureDeviceInput *audioDeviceInput;
@property (retain) AVCaptureAudioFileOutput *audioFileOutput;
@property (retain) AVCaptureSession *session;
@property (retain) AVAudioPlayer *player;

- (IBAction)beginToRecord:(id)sender;
- (IBAction)beginToReplay:(id)sender;
- (void)awakeFromNib;

@end

@implementation AppDelegate

@synthesize recordButton, replayButton, timeLabel;
@synthesize audioDeviceInput, audioFileOutput, session, player;

-(instancetype) init
{
    self = [super init];
    if(self)
    {
        NSLog(@"init the AppDelegate");
        [self initAudioRecord];
    }
    
    return self;
}

- (void)initAudioRecord {
    session = [[AVCaptureSession alloc] init];

    audioFileOutput = [[AVCaptureAudioFileOutput alloc] init];
    [audioFileOutput setDelegate:self];
    [session addOutput:audioFileOutput];

    [[self session] beginConfiguration];
    [[self session] setSessionPreset:AVCaptureSessionPresetHigh];

    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioDeviceInput) {
        [session addInput:audioDeviceInput];
    }
    else {
        // Handle the failure.
    }
    [[self session] commitConfiguration];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)beginToRecord:(id)sender {
    NSLog(@"begin to record sound...");

    NSString *tempName = @"/Volumes/DataDisk/Music/test.m4a";
    NSLog(@"%@",[AVCaptureAudioFileOutput availableOutputFileTypes]);

    [session startRunning];
    [[self audioFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:tempName]
                                           outputFileType:AVFileTypeAppleM4A
                                        recordingDelegate:self];
}

- (IBAction)beginToReplay:(id)sender {
    NSLog(@"beign to replay the record sound...");
    [audioFileOutput stopRecording];
    [session stopRunning];

}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"Did start recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)recordError
{
    NSLog(@"Did finish recording to %@", [outputFileURL description]);

    if (recordError != nil && [[[recordError userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey] boolValue] == NO) {
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        dispatch_async(dispatch_get_main_queue(), ^(void) {

        });
    } else {

        // Move the recorded temporary file to a user-specified location
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:outputFileURL fileTypeHint:AVFileTypeAppleM4A error:nil];
        player.volume = 1.0f;
        [player play];
    }
}


- (void)awakeFromNib {
    NSLog(@"awakeFromNib, init components");

}

@end
