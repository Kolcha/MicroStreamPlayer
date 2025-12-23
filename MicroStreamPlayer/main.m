//
//  main.m
//  MicroStreamPlayer
//
//  Created by Nick Korotysh on 5/16/19.
//  Copyright © 2019 Nick Korotysh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@interface AppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) AVPlayer *player;
@end

@implementation AppDelegate

static NSString *const kLastURL = @"last_url";
static void *PlayerItemStatusContext = &PlayerItemStatusContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"StatusBarButtonImage"];

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    [menu addItemWithTitle:@"Open" action:@selector(openNewUrl) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
    self.statusItem.menu = menu;

    self.player = [AVPlayer playerWithPlayerItem:nil];
    NSString *lastURLString = [[NSUserDefaults standardUserDefaults] stringForKey:kLastURL];
    NSURL *lastURL = lastURLString ? [NSURL URLWithString:lastURLString] : [[NSUserDefaults standardUserDefaults] URLForKey:kLastURL];
    [self startPlayer:lastURL];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if (self.player.currentItem) {
        [self.player.currentItem removeObserver:self forKeyPath:@"status" context:PlayerItemStatusContext];
    }

    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}


- (void)openNewUrl {
    NSString *lastURLString = [[NSUserDefaults standardUserDefaults] stringForKey:kLastURL] ?: @"";
    NSString *strurl = [AppDelegate getString:@"Stream URL to play:" :lastURLString];

    if ([strurl length] == 0) {
        return;
    }

    if ([strurl isEqualToString:lastURLString]) {
        return;
    }

    NSURL *url = [NSURL URLWithString:strurl];
    if (!url || (!url.scheme || (![url.scheme isEqualToString:@"http"] && ![url.scheme isEqualToString:@"https"]))) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Invalid URL"];
        [alert setInformativeText:@"Please enter a valid HTTP or HTTPS URL for the stream."];
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:strurl forKey:kLastURL];
    [self startPlayer:url];
}


- (void)startPlayer:(nullable NSURL *)url {
    [self.player pause];

    // Remove observer from previous item if exists
    if (self.player.currentItem) {
        [self.player.currentItem removeObserver:self forKeyPath:@"status" context:PlayerItemStatusContext];
    }

    if (url) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];

        // Add observer for player item status
        [playerItem addObserver:self
                     forKeyPath:@"status"
                        options:NSKeyValueObservingOptionNew
                        context:PlayerItemStatusContext];

        // Register for failed notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemFailedToPlayToEnd:)
                                                     name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                   object:playerItem];

        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        [self.player setVolume:0.75];
        [self.statusItem.button setToolTip:@"Loading..."];
    } else {
        [self.player replaceCurrentItemWithPlayerItem:nil];
        [self.statusItem.button setToolTip:@"No stream loaded"];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == PlayerItemStatusContext) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;

        if ([keyPath isEqualToString:@"status"]) {
            switch (playerItem.status) {
                case AVPlayerItemStatusReadyToPlay:
                    NSLog(@"Player ready to play");
                    [self.player play];
                    [self.statusItem.button setToolTip:((AVURLAsset *)playerItem.asset).URL.absoluteString];
                    break;

                case AVPlayerItemStatusFailed:
                    [self handlePlayerError:playerItem.error];
                    break;

                case AVPlayerItemStatusUnknown:
                    NSLog(@"Player status unknown");
                    break;
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)handlePlayerError:(nullable NSError *)error {
    NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
    NSLog(@"Player error: %@", errorMessage);

    [self.player pause];
    [self.statusItem.button setToolTip:@"Error: Failed to play stream"];
}


- (void)playerItemFailedToPlayToEnd:(NSNotification *)notification {
    NSError *error = notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    [self handlePlayerError:error];
}


+ (NSString *)getString:(nonnull NSString *)message :(nonnull NSString *)defaultString {
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 22)];
    [input setStringValue:defaultString];
    [input setMaximumNumberOfLines:1];

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
    [alert addButtonWithTitle:@"Ok"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAccessoryView:input];
    [[alert window] setInitialFirstResponder: input];

    NSInteger button = [alert runModal];
    return button == NSAlertFirstButtonReturn ? [input stringValue] : defaultString;
}


@end


int main(int argc, const char *argv[]) {
    return NSApplicationMain(argc, argv);
}
