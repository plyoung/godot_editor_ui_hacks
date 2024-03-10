# Godot Editor UI Hacks

Godot editor addon which adds new editor settings to change options related to the editor interface.

## Install

Copy folder in addons to the addons folder in your Godot project's folder.

Note: it makes assumptions about node locations so might not work in all Godot version. Tested in:
- 4.2.1

## Hide/Show parts of UI

The new options can be found by going menu: `Editor > Editor Settings` and scrolling down to `Addons > Editor UI Hacks`.

There are options to hide/show the toolbars of the Scene Tree and File System Docks. Usefull when you need some more space on a low resolution screen and do not use these toolbars.

![sample](/img/000.gif)

## Scenes Menu

A new scenes menu popup will be added in the scenes editor tab bar, next to the "Distraction Free Mode" button to the right-hand side, when you enable it in settings. It gives a quick way to open frequently used scenes.

Use "Setup" option to point to scenes or paths containing scenes and the menu will be updated with these.

![sample](/img/scenes_menu.png)
