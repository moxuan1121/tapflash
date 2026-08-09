#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <notify.h>

typedef BOOL (*MediaRemoteSendCommand)(int command, id userInfo);

static void ToggleFlashlight(void) {
    @autoreleasepool {
        AVCaptureDevice *device =
            [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if (!device || !device.hasTorch) {
            return;
        }

        NSError *error = nil;
        if (![device lockForConfiguration:&error]) {
            return;
        }

        AVCaptureTorchMode mode = device.torchMode == AVCaptureTorchModeOn
            ? AVCaptureTorchModeOff
            : AVCaptureTorchModeOn;
        [device setTorchMode:mode];
        [device unlockForConfiguration];
    }
}

static void TogglePlayback(void) {
    @autoreleasepool {
        void *framework = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_LAZY | RTLD_LOCAL);
        if (!framework) {
            return;
        }

        MediaRemoteSendCommand sendCommand =
            (MediaRemoteSendCommand)dlsym(framework, "MRMediaRemoteSendCommand");

        // kMRTogglePlayPause is MediaRemote command 2.
        if (sendCommand) {
            sendCommand(2, nil);
        }
    }
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
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
