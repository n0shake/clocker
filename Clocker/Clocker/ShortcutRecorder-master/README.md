ShortcutRecorder 2
====================
![pre-Yosemite ShortcutRecorder Preview](Demo/example.png)
![Yosemite ShortcutRecorder Preview](Demo/example-yosemite.png)

The only user interface control to record shortcuts. For Mac OS X 10.6+, 64bit.

- :microscope: Support for Xcode 6 Quick Help
- :microscope: Support for Xcode 6 Interface Builder integration
- Fresh Look & Feel (brought to you by [Wireload](http://wireload.net) and [John Wells](https://github.com/jwells89))
- With Retina support
- Auto Layout ready
- Correct drawing on Layer-backed and Layer-hosted views
- Accessibility for people with disabilities
- Revised codebase with Automatic Reference Counting support
- Translated into 24 languages

Includes framework to set global shortcuts (PTHotKey).

Get Sources
-----------
The preferred way to add the ShortcutRecorder to your project is to use git submodules:
`git submodule add git://github.com/Kentzo/ShortcutRecorder.git`
You can download sources from the site as well.

Integrate into your project
---------------------------
First, add ShortcutRecorder.xcodeproj to your workspace via Xcode ([Apple docs](https://developer.apple.com/library/mac/recipes/xcode_help-structure_navigator/articles/Adding_an_Existing_Project_to_a_Workspace.html)). Don't have a workspace? No problem, just add ShortcutRecorder.xcodeproj via the "Add Files to" dialog.

Next step is to ensure your target is linked against the ShortcutRecorder or/and PTHotKey frameworks ([Apple docs](http://developer.apple.com/library/ios/#recipes/xcode_help-project_editor/Articles/AddingaLibrarytoaTarget.html#//apple_ref/doc/uid/TP40010155-CH17)). Desired frameworks will be listed under *Workspace*.

Now it's time to make frameworks part of your app. To do this, you need to add custom Build Phase ([Apple docs](http://developer.apple.com/library/ios/#recipes/xcode_help-project_editor/Articles/CreatingaCopyFilesBuildPhase.html)). Remember to set *Destination* to *Frameworks* and clean up *Subpath*.

Finally, ensure your app will find frameworks upon start. Open Build Settings of your target, look up *Runtime Search Paths*. Add `@executable_path/../Frameworks` to the list of paths.

Add control in Interface Builder
--------------------------------
Since Xcode 4 Apple removed Interface Builder Plugins. You can only use it to add and position/resize ShortcutRecorder control. To do this, add Custom View and set its class to SRRecorderControl.

SRRecorderControl has fixed height of 25 points so ensure you do not use autoresizing masks/layout rules which allows vertical resizing. I recommend you to pin height in case you're using Auto Layout.

Usage
-----
First, we want to keep value of the control across relaunches of the app. We can simply achieve this by using NSUserDefaultsController and bindings:

    [self.pingShortcutRecorder bind:NSValueBinding
                           toObject:[NSUserDefaultsController sharedUserDefaultsController]
                        withKeyPath:@"values.ping"
                            options:nil];

The value can be used to set key equivalent of NSMenuItem or NSButton. It can also be used to register a global shortcut.

Setting key equivalent of NSMenuItem using bindings:

    [self.pingItem bind:@"keyEquivalent"
               toObject:defaults
            withKeyPath:@"values.ping"
                options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
    [self.pingItem bind:@"keyEquivalentModifierMask"
               toObject:defaults
            withKeyPath:@"values.ping"
                options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];

Setting key equivalent of NSButton using bindings:

    [self.pingButton bind:@"keyEquivalent"
                 toObject:defaults
              withKeyPath:@"values.ping"
                  options:@{NSValueTransformerBindingOption: [SRKeyEquivalentTransformer new]}];
    [self.pingButton bind:@"keyEquivalentModifierMask"
                 toObject:defaults
              withKeyPath:@"values.ping"
                  options:@{NSValueTransformerBindingOption: [SRKeyEquivalentModifierMaskTransformer new]}];

Setting global shortcut using PTHotKeyCenter:

    PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
    PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:aKeyPath];
    [hotKeyCenter unregisterHotKey:oldHotKey];

    PTHotKey *newHotKey = [PTHotKey hotKeyWithIdentifier:aKeyPath
                                                keyCombo:newShortcut
                                                  target:self
                                                  action:@selector(ping:)];
    [hotKeyCenter registerHotKey:newHotKey];

Key Equivalents and Keyboard Layout
----------------------------------------------------
While ShortcutRecorder keeps your shortcuts as combination of *key code* and modifier masks, key equivalents are expressed using *key character* and modifier mask. The difference is that position of key code on keyboard does not depend on current keyboard layout while position of key character does.

ShortcutRecorder includes two special transformers to simplify binding to the key equivalents of NSMenuItem and NSButton:

- SRKeyEquivalentTransformer
- SRKeyEquivalentModifierMaskTransformer

SRKeyEquivalentTransformer uses ASCII keyboard layout to convert key code into character, therefore resulting character does not depend on keyboard layout.
The drawback is that position of the character on keyboard may change depending on layout and used modifier keys (primarly Option and Shift).

NSButton
--------
If you're going to bind ShortcutRecorder to key equivalent of NSButton, I encourage you to require `NSCommandKeyMask`.
This is because NSButton handles key equivalents very strange. Rather than investigating full information of the keyboard event, it just asks for `charactersIgnoringModifiers`
and compares returned value with its `keyEquivalent`. Unfortunately, Cocoa returns layout-independent (ASCII) representation of characters only when NSCommandKeyMask is set.
If it's not set, assigned shortcut likely won't work with other layouts.

Questions
---------
Still have questions? [Create an issue](https://github.com/Kentzo/ShortcutRecorder/issues/new) immediately and feel free to ping me.

Paid Support
------------
If functional you need is missing but you're ready to pay for it, feel free to contact me. If not, create an issue anyway, I'll take a look as soon as I can.
