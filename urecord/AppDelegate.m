//
//  AppDelegate.m
//  urecord
//
//  Created by liangfen on 17/5/2.
//  Copyright © 2017年 Imagination Studio. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()<AVCaptureFileOutputDelegate, AVCaptureFileOutputRecordingDelegate, NSWindowDelegate>


@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *recordButton;
@property (weak) IBOutlet NSButton *replayButton;
@property (weak) IBOutlet NSTextField *timeLabel;

@property (retain) AVCaptureDeviceInput *audioDeviceInput;
@property (retain) AVCaptureAudioFileOutput *audioFileOutput;
@property (retain) AVCaptureSession *session;
@property (retain) AVAudioPlayer *player;
@property BOOL needToPlayAfterStopRecord, needToRecordAfterStopRecord, needToRemoveRecordAfterStopRecord;
@property (retain) NSString *recordTmpFilePath, *recordTmpFolderPath;

- (IBAction)beginToRecord:(id)sender;
- (IBAction)beginToReplay:(id)sender;
- (void)awakeFromNib;

@end

@implementation AppDelegate

@synthesize recordButton, replayButton, timeLabel;
@synthesize audioDeviceInput, audioFileOutput, session, player;
@synthesize needToPlayAfterStopRecord, needToRecordAfterStopRecord, needToRemoveRecordAfterStopRecord;
@synthesize recordTmpFilePath, recordTmpFolderPath;

-(instancetype) init
{
    self = [super init];
    if(self)
    {
        NSLog(@"init the AppDelegate");
        [self initAudioRecord];
        [self initAudioPlayer];
        needToPlayAfterStopRecord = FALSE;
        needToRecordAfterStopRecord = FALSE;
        needToRemoveRecordAfterStopRecord = FALSE;

        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *desktopURL = [NSURL fileURLWithPath:@"/"
                                       isDirectory:YES];
        NSError *error = nil;
        NSURL *temporaryDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
                                                                              inDomain:NSUserDomainMask
                                                                     appropriateForURL:desktopURL
                                                                                create:NO
                                                                                 error:&error];
        recordTmpFolderPath = [temporaryDirectoryURL path];
        if ([fm fileExistsAtPath:recordTmpFolderPath]) {
            [fm removeItemAtPath:recordTmpFolderPath error:nil];
        }
        NSRange range = [recordTmpFolderPath rangeOfString:@"/" options:NSBackwardsSearch];
        NSRange newStringRange;
        newStringRange.location = 0;
        newStringRange.length = range.location;
        recordTmpFolderPath = [recordTmpFolderPath substringWithRange:newStringRange];

        if (![fm fileExistsAtPath:recordTmpFolderPath]) {
            [fm createDirectoryAtPath:recordTmpFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        recordTmpFilePath = [NSString stringWithFormat:@"%@/%@", recordTmpFolderPath, @"test.m4a"] ;
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

- (void)initAudioPlayer {
//    self.player = [AVAudioPlayer alloc];
}

- (void) playTheRecordFile: (NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ( ![fm fileExistsAtPath:path] ) {
        return;
    }

    NSLog(@"play the record file: %@", path);
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] fileTypeHint:AVFileTypeAppleM4A error:nil];
    player.volume = 1.0f;
    [player play];
}

- (void) recordTheFile: (NSString *)path {
    NSLog(@"begin to record sound...");

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        [fm removeItemAtPath:path error:nil];
    }
    [session startRunning];
    [[self audioFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:path]
                                           outputFileType:AVFileTypeAppleM4A
                                        recordingDelegate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)beginToRecord:(id)sender {
    if (player) {
        NSLog(@"stop player");
        if ([player isPlaying]) {
            [player stop];
        }
    }
    if ([session isRunning]) {
        NSLog(@"stop preview record process...");
        needToPlayAfterStopRecord = FALSE;
        needToRecordAfterStopRecord = TRUE;
        [audioFileOutput stopRecording];
        [session stopRunning];
    } else {
        [self recordTheFile:recordTmpFilePath];
    }
}

- (IBAction)beginToReplay:(id)sender {
    NSLog(@"beign to replay the record sound...");
    if ([session isRunning]) {
        needToPlayAfterStopRecord = TRUE;
        needToRecordAfterStopRecord = FALSE;
        [audioFileOutput stopRecording];
        [session stopRunning];
    } else {
        if (player) {
            if([player isPlaying]) {
                [player stop];
            }
        }
        [self playTheRecordFile:recordTmpFilePath];
    }
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
        NSLog(@"stop record and save the recording file");

        if (needToPlayAfterStopRecord) {
            [self playTheRecordFile:[outputFileURL path]];

        } else if (needToRecordAfterStopRecord) {
            [self recordTheFile:[outputFileURL path]];

        } else if (needToRemoveRecordAfterStopRecord) {
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:recordTmpFolderPath]) {
                NSLog(@"remove temp folder");
                [fm removeItemAtPath:recordTmpFolderPath error:nil];
            }
        }

    }
}


- (void)awakeFromNib {
    NSLog(@"awakeFromNib, init components");

}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"window will close, release the resource...");

    if (player) {
        NSLog(@"stop player");
        if ([player isPlaying]) {
            [player stop];
        }
    }

    if ([session isRunning]) {
        NSLog(@"stop record");
        needToPlayAfterStopRecord = FALSE;
        needToRecordAfterStopRecord = FALSE;
        needToRemoveRecordAfterStopRecord = TRUE;
        [audioFileOutput stopRecording];
        [session stopRunning];

    } else {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:recordTmpFolderPath]) {
            NSLog(@"remove temp folder");
            //[fm removeItemAtPath:recordTmpFolderPath error:nil];
        }
    }
}

@end
