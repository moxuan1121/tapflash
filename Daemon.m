#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <notify.h>

typedef BOOL (*MediaRemoteSendCommand)(int command, id userInfo);

static NSString *const kStatusPath =
    @"/var/mobile/Library/Preferences/tapflashd-status.txt";

static void WriteStatus(NSString *message) {
    NSString *line = [NSString stringWithFormat:@"%@\n%@\n",
        [NSDate date], message ?: @"unknown"];
    [line writeToFile:kStatusPath
           atomically:YES
             encoding:NSUTF8StringEncoding
                error:nil];
}

static void ToggleFlashlight(void) {
    @autoreleasepool {
        WriteStatus(@"received flashlight notification");

        AVCaptureDevice *device =
            [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if (!device || !device.hasTorch) {
            WriteStatus(@"flashlight failed: no torch device");
            return;
        }

        NSError *error = nil;
        if (![device lockForConfiguration:&error]) {
            WriteStatus([NSString stringWithFormat:@"flashlight lock failed: %@",
                                                    error.localizedDescription]);
            return;
        }

        AVCaptureTorchMode mode = device.torchMode == AVCaptureTorchModeOn
            ? AVCaptureTorchModeOff
            : AVCaptureTorchModeOn;
        [device setTorchMode:mode];
        [device unlockForConfiguration];

        WriteStatus(mode == AVCaptureTorchModeOn
            ? @"flashlight command completed: on"
            : @"flashlight command completed: off");
    }
}

static void TogglePlayback(void) {
    @autoreleasepool {
        WriteStatus(@"received playback notification");

        void *framework = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_LAZY | RTLD_LOCAL);
        if (!framework) {
            WriteStatus(@"playback failed: MediaRemote did not load");
            return;
        }

        MediaRemoteSendCommand sendCommand =
            (MediaRemoteSendCommand)dlsym(framework, "MRMediaRemoteSendCommand");

        if (!sendCommand) {
            WriteStatus(@"playback failed: command symbol missing");
            return;
        }

        BOOL sent = sendCommand(2, nil);
        WriteStatus(sent
            ? @"playback command accepted"
            : @"playback command rejected");
    }
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        WriteStatus(@"tapflashd started");

        dispatch_queue_t queue =
            dispatch_queue_create("com.chr1s.tapflashd", DISPATCH_QUEUE_SERIAL);

        int flashlightToken = 0;
        int playbackToken = 0;

        notify_register_dispatch("com.chr1s.tapflash.toggle-flashlight",
                                 &flashlightToken, queue, ^(int token) {
            ToggleFlashlight();
        });
        notify_register_dispatch("com.chr1s.tapflash.toggle-playback",
                                 &playbackToken, queue, ^(int token) {
            TogglePlayback();
        });

        dispatch_main();
    }
}
