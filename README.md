# EzV
Simple Video Processor Based on ffmpeg 


## Pre Release Version 1.0

### This is the first release of EZV, for macOS 15.6+ only (ARM | M-series).

### Design and Intention
When building this software, the intention was to make an easy to use video compressor built around FFMPEG.
Additionally it allows a UI based access to FFMPEG, to compress videos.

####  Not everyone is technologically inclined, or has access to skills or even video editors. Some can be lazy like myself.

I personally use it to reduce massive screen recordings to manageable sizes.
Whilst I used a script earlier, I found sometimes I just didn't want to touch the terminal. So comes about EzV aka Easy Video.

Definitely helpful if you want to batch process a bunch of stuff and maintain the video quality.

### UI
A little basic but just enough to do the intended processing.

### Testing
Users are encouraged to test and see what breaks, and leave comments on what is good and isn't.
I'll get around to breaking the app myself and then releasing the next version on my next iteration.



## Third-party software
EzV bundles a static build of [FFmpeg](https://ffmpeg.org) 9.0.1
(from https://evermeet.cx/ffmpeg/), licensed under the
[GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html).
Source: https://ffmpeg.org/releases/ffmpeg-9.0.1.tar.xz
FFmpeg's license text is in `LICENSE.ffmpeg`.

EzV's own source code is MIT-licensed. FFmpeg is invoked as a
separate executable and is not covered by EzV's MIT license.
