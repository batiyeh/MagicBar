

<img src="https://github.com/batiyeh/MagicBar/blob/master/MagicBar/Assets.xcassets/AppIcon.appiconset/MagicBarAppIcon-256.png" width="64px"> 

# MagicBar
A MacOS (10.10 and up) menu bar app for connecting to your Magic Mouse via keyboard shortcut

[Download](https://github.com/batiyeh/MagicBar/releases)

<a href="https://www.buymeacoffee.com/batiyeh" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" width="150"></a>

## Why?
Unfortunately switching your Magic Mouse between devices isn't easy. 
- The connection consistently fails or unpairs when you try to connect to another Macbook after previously being connected to a different machine. 
- Its even worse if you happen to have a vertical mount setup so you have no access to your trackpad without a mouse. 
- Its also free (unlike an app like Tooth Fairy)


## How does it work?
Simple - MagicBar is able to find your Magic Mouse without you having to select it from a list (but only if you have it paired initially). 

Once you run the app with a paired Magic Mouse then MagicBar will be able to connect and even re-pair the device in the future (no more dropping the connection when switching between machines! :clap:) 

All you need is a keyboard shortcut.

`cmd + shift + m`: Connect to your Magic Mouse

`cmd + shift + option + m`: Disconnect from your Magic Mouse

*Option to change keyboard shortcuts coming soon.*


## Building Locally

3rd party libraries were installed using cocoapods:

1. Install cocoapods if not already installed using `brew install cocoapods` 

2. Then run `pod install` in the project's root directory.
