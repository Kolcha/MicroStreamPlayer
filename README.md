Micro Stream Player
===================

This is very lightweight (under 300 KB in size) and simple media player for macOS, created only for one purpose - just to play audio streams. It has no UI, it doesn't show app icon in Dock, it just has tray icon which is used to control it. Tray icon menu is also minimalistic - it has only 2 menu items: "Open" and "Quit". "Open" item is used to open URL for playback, last opened URL is saved, so when player is started next time it opens last played URL automatically.

Key features:

* very lightweight (less than 300 KB, most of its size is app icon, it is too heavy on macOS)
* no UI, no Dock icon, no playlist and other unnecessary stuff, just stream playback
* no annoying notifications
* very easy to use - just open desired URL once and it will be open automatically next time

Player has no any external dependencies, just system libraries. It uses high level APIs from "AVFoundation" media framework for stream playback, so it can play only anything that can be played with iTunes or Quick Time. But this is not a problem, most media streams use mp3 codec, and it can be played. Moreover, macOS has pretty good set of supported media codecs out of the box.
