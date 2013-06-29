Conform
=======

**[Get Conform on the App Store.](https://itunes.apple.com/fi/app/conform/id664574539?mt=8)**

**[Watch a demonstration video on YouTube.](http://www.youtube.com/watch?v=nBg02GLqwgs)**

## App Store description

Conform is an interactive composition for iPad, where complexity leads to less control.

You are presented with a normal 8-channel 16-step sequencer. But once you select a step, triggering it will move it to a new position. Additional function buttons modify the step grid further, enabling new creative processes.

Credits:

Programming and sound design by Johan Halin.

Clicks and pops by Otto Hassinen. (http://soundcloud.com/trisector)

Created by Aero Deko.

## Notes

Conform uses The Amazing Audio Engine, which is installed via CocoaPods. After cloning the repository, remember to do the following:

    pod install
    
The project was initially created in 2010, and has been developed very sporadically since then. The sequencer was originally based on NSTimer, which was not very useful. (I bet this comes as a huge surprise) After discovering The Amazing Audio Engine in 2013, I decided to get off my ass and actually finish the app. My personal deadline was set at the end of my summer vacation, which means that the code is a bit messy since it's quite rushed in parts. Constructive criticism and pull requests (especially around the audio stuff) is very welcome.

If you do contribute code (or anything else) to the project, I'd be happy to credit you in the app and elsewhere.

The sample sequencer and synth will probably be separated into something else at some point in the future, since I'll be using them in other projects.
