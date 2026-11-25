# Show a fixed timezone in a space-saving menu bar

Clocker can display a timezone independently of the macOS system timezone. This is useful when your Mac uses one timezone but you want to keep another city's time visible while working.

These instructions describe existing Clocker features, not a new display mode. Setting names and their location may vary by release and interface language.

## Choose which timezone appears

1. Open Clocker from the menu bar and add the city or timezone you want to track.
2. Use an explicitly selected timezone, such as `Asia/Tokyo`, rather than the system/home timezone entry. The system entry follows the Mac's timezone; a fixed entry does not.
3. Open Clocker's preferences and mark the entry as **Favourite** to show it in the menu bar.
4. Unmark other entries as favourites if you only want one menu bar clock. They remain available in Clocker's panel.
5. Optionally give the entry a short custom label to save space.

For regions that observe daylight saving time, select the appropriate named timezone rather than a fixed UTC offset.

## Keep the clock readable without crowding other items

In the menu bar appearance settings:

- Keep the location label enabled so you know which timezone the clock uses.
- Enable **Include Day** if you want the weekday for that timezone.
- Disable **Include Date** if you do not need a date beside every clock.
- Choose a 24-hour time format without seconds for a shorter display.

For example, a single clock might read `Tokyo Wed 17:35`. The actual weekday and time formatting depend on your locale and format settings.

Adding more favourites makes the menu bar item wider. If other status icons disappear, first reduce the number of favourites or shorten the displayed format.

## When Clocker is running but its clock is not visible

A saved favourite does not guarantee that its menu bar item fits on screen. A wide clock can compete with application menus, other status items, or the camera housing on some Mac displays.

1. Switch to an application with fewer menu headings, such as Finder, to check whether the item becomes visible.
2. Once it is visible, hold **Command** and drag the Clocker item toward the right side of the menu bar, where there is room for it.
3. Shorten the label or remove extra favourites if space is still limited.
4. Switch back to your usual application and check that both Clocker and your other status items remain visible.

## The macOS clock is separate

The clock at the far right of the menu bar belongs to macOS, not Clocker. It continues to use the system timezone. Changing a Clocker favourite does not change that clock or the system timezone.

If the second digital clock is distracting, macOS clock options may let you switch it to an analog clock face and reduce its date details. Find those options in System Settings under the menu bar or Control Center settings, depending on your macOS version. This changes the system clock's presentation, not its timezone.

Changing the system timezone is not necessary to use this guide. If you do change it separately, keep automatic date-and-time synchronization enabled; timezone selection and clock synchronization are different settings.
