//
//  AppDelegate.m
//  MicroStreamPlayer
//
//  Created by Nick Korotysh on 5/16/19.
//  Copyright © 2019 Nick Korotysh. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@property (nonatomic, readonly) NSStatusItem *statusItem;
@property (nonatomic, readonly) AVPlayer *player;
@end

@implementation AppDelegate

NSString * const kLastURL = @"last_url";

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.button.image = [NSImage imageNamed:@"StatusBarButtonImage"];

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    [menu addItemWithTitle:@"Open" action:@selector(openNewUrl) keyEquivalent:@""];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
    _statusItem.menu = menu;

    _player = [AVPlayer playerWithPlayerItem:nil];
    [_player addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:nil];
    [self startPlayer:[[NSUserDefaults standardUserDefaults] URLForKey:kLastURL]];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_player pause];
    [_player replaceCurrentItemWithPlayerItem:nil];
    [_player removeObserver:self forKeyPath:@"status"];
}


-(void)openNewUrl {
    NSString *strurl = [AppDelegate getString:@"Stream URL to play:" :@""];
    if ([strurl length] != 0) {
        NSURL *url = [NSURL URLWithString:strurl];
        [[NSUserDefaults standardUserDefaults] setURL:url forKey:kLastURL];
        [self startPlayer:url];
    }
}


-(void)startPlayer:(nullable NSURL *)url {
    [_player pause];

    if (_player.currentItem)
        [_player.currentItem removeObserver:self forKeyPath:@"status"];

    if (url) {
        [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:url]];
        [_player setVolume:0.75];
        [_player play];
    } else {
        [_player replaceCurrentItemWithPlayerItem:nil];
    }

    if (_player.currentItem)
        [_player.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (object != _player && object != _player.currentItem) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@"status"]) {
        NSError* error;

        if (object == _player && _player.status == AVPlayerStatusFailed)
            error = _player.error;
        if (object == _player.currentItem && _player.currentItem.status == AVPlayerItemStatusFailed)
            error = _player.currentItem.error;

        if (error) {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Error";
            notification.informativeText = error.localizedDescription;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            [self startPlayer:[[NSUserDefaults standardUserDefaults] URLForKey:kLastURL]];
        }
    }
}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}


+(NSString*)getString:(nonnull NSString *)message :(nonnull NSString *)defaultString {
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
