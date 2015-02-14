# Consensual

A theme for stepmania.

Minimalist in graphics, maximalist in functionality.

This theme requires Stepmania 5.0.5.

## Short feature list:
* Deeper music wheel sorting.
* Mark songs as favorites.
* Tag songs.
* No "select style" or "select mode" screens, goes straight to select music.
* Timed sets.  No more getting screwed out of play time by picking a 1 minute
	song or using a rate mod.
* Auto Set Style.
* Patched songs cost their full amount.
* Every mod can be set to any value.
* Customizable pane info.
* Customizable gameplay elements.
* Customizable evaluation info.
* Individual customizations saved to profiles.
* Confetti.
* Customizable color system.
* Unique toasties.

# Profiles:
If you don't normally use a named profile on Stepmania, you should create
one.  All of the individually customizable things in Consensual are saved to
the profile directory, so if you don't have a profile, you're cut off from
many useful things.  
Profiles on USB drives should work too, if Stepmania is configured to use
them.  
Some things like Favor values and Tags can have values set in the machine
profile.  The machine profile's folder is in Save/MachineProfile.

# Cursors:
All cursors have icons on them showing the buttons that can be used to move
the cursor.  
If the Only Dedicated Menu buttons preference is false, Stepmania will
translate some of the buttons on the controller to the menu buttons so that
they can be used.  The cursor will display the controller button instead of
the menu button in this case.  Check the Map Controllers screen to see which
buttons are translated to menu buttons.

# Game Modes:
Dance and Kickbox are the primary supported game modes in Consensual.
Pump and Techno are secondarily supported.  
Other game modes should work, but might have problems that need to be
reported.


# In Depth Guide
If you are already familiar with Stepmania, you will see some things in here
that you already know, but that doesn't mean there's nothing useful to you in
here.  This guide is written to cover every detail so that it fills in gaps
for people who aren't familiar with Stepmania as well as introducing new
things.  
With that said, typical users should be able to play without problems using
the on-screen hints like the icons on the cursors and trial and error.  The
main target of this guide is people looking for an explanation of some part
or details on configuration.

## Special Profile Fields
In Consensual, a profile has an Options Level and a Rating Cap.  
The Options Level is used to hide menu choices that might obstruct
inexperienced players.  
The Rating Cap is used to hide songs on the music wheel that do not have an
easy chart.  
Both of these can be set on the Player Options screen.

## Version Test Screen
This screen is the first screen that appears when you select Consensual.  
It displays the name of the theme with a fancy animation.  
It also checks for version compatibility and shows a message if any problems
are detected.

#### Messages:
* "You should upgrade to Stepmania 5.0.5."  
	If the problem is severe enough (stepmania version too old to support
	easily), Stepmania will be switched to a different theme that is less
	bleeding-edge.  (It checks for Simply Love, then Ultralight, and if neither
	is installed, switches to default).
* "You have the Smooth Lines preference set to false."  
	This mostly only matters for the Initial Menu screen, where the fancy
	animated things are drawn with lines.  I have noticed a substantial frame
	rate improvement from setting the Smooth Lines preference to true on that
	screen, so this message is to take care of people reporting low frame rates
	on that screen.
* "If you see errors, report them."  
	If you have problems, report them.  Otherwise, they never get fixed.
	The best place to report problems with Consensual is on the github page:
	https://github.com/kyzentun/consensual/issues
	Click the New Issue button and fill it out with all the info you can give.



## Initial Menu Screen
This screen shows the number of songs and groups loaded, the current time,
and a menu for starting the game.  
Both players can navigate the menu and select options without inserting
credits.  When one player picks Single or Versus, then credits are deducted
and the credit started.  
The options on the menu can be hidden in the Consensual Service Screen, which
will be discussed later.  This means that if you're using Stepmania at home,
you can have all the menu options visible, or if you're using Stepmania in a
public setting, you can hide everything you don't want public players
accessing.  
Each player has their own cursor that they can use to pick stuff in the menus
independently.  Any play mode or profile choices must be completed before one
of the play options is selected, or the defaults will be used.

### Special Days
On certain days, you may see a message above the time telling you that it is
a special day.  This means that some easter egg has been activated, and if
you don't like the effects of the easter egg, you can turn easter eggs off
in the service menu.  Turning easter eggs off does not disable toasties in
Consensual, toasties are a profile option instead, so one player can have
toasties off while another has toasties on.

### Demonstration Screen
If no input occurs for 60 seconds, the screen will transition to the demo
screen, where an AI plays a song for a short time before returning to the
menu.  The demo screen can also be ended by pressing start.

### Event Mode
The length of one credit can be set to as to anything, and it is possible to
end a credit in the middle, so event mode isn't necessary for home play.  
If you encounter any problems while using Event Mode, report them so they can
be fixed.

### Menu Options:
* Single  
	This starts a credit for one player.  The cursors for both players must be
	on this option to use it.  The player that pressed start is joined and the
	profile they selected from the profile menu is loaded.
* Versus  
	This starts a credit for both players.  The cursors for both players must
	be on this option to use it.  The profiles selected from the profile menu
	are loaded for both players.
* Playmode  
	The Playmode choice opens the Playmode menu.  This has the choices for
	regular play and nonstop play (also known as course mode).
* Profile  
	Each player can pick which profile on the machine will be loaded for them
	from the Profile menu.  Profiles on attached USB drives should also appear
	in the menu.
* SM Conf  
	This opens the standard Stepmania Service menu.  The Stepmania Service menu
	is left uncustomized to ensure that it is the same as in the default
	stepmania theme.
* Theme Conf  
	Theme Conf takes you to the Consensual Service menu, which contains the
	configuration choices that affect everybody.  This screen will be discussed
	near the end of this guide.
* Color Config  
	The colors used in Consensual can be individually configured to any color
	value.  If you don't like the color scheme, configure it.
* Edit Mode  
	Stepmania's standard Edit Mode.  The "Practice Songs" and "Edit Courses"
	options are not shown because they have problems.  If you need to practice
	a song, I recommend setting Fail Off and using the music rate options.
* Exit  
	Exits stepmania.

### Special Keys:
If you have a keyboard connected, there are some special keys that can be
used to access hidden menu options on this screen.  
Z takes you to the Consensual Service menu.  
B takes you to the Color Config menu.  
Both of these can be configured in the Consensual Service menu.


## Select Music Screen

### Help layer:
After 10 seconds of inactivity, an overlay explaining some basic controls
will appear.  The time can be configured, and the layer disabled in the
Consensual Service menu.

### Minor Elements:
* Song Info  
	The banner, title, and length of the current song are displayed in the
	upper left corner.
* Remaining Time  
	The time remaining in the current credit is shown below the song length.
* Difficulty Selector  
	The difficulty selector has a 1 or 2 letter code for the style of the chart
	and a number for the meter, and is color coded by difficulty.
	Codes for moving to the harder difficulty:
	* All:  Hold Select and tap Menu Right
	* Dance:  Down, Down
	* Kickbox:  Down Left Foot
	* Pump:  Up Right, Up Right
	Codes for moving to the easier difficulty:
	* All:  Hold Select and tap Menu Left
	* Dance:  Up, Up
	* Kickbox:  Up Left Foot
	* Pump:  Up Left, Up Left
* Sort Info  
	The currently selected sort type and the name of the current bucket is
	displayed between the song banner and the music wheel.

### Music Wheel:
Consensual's music wheel is 100% custom written and not the music wheel you
see in any other Stepmania theme.  Only the song titles are displayed on it
because that's what I consider most important.  
Technomotion game mode uses the pad codes from dance and pump game modes.

#### Color Coding:
Items on the music wheel are color coded according to their type.  These
colors have their own group on the Color Config screen,
"music_select.music_wheel", and default to using other colors.  The string
in parentheses is the name of the color that is used by default.  
Normal songs use the dimmer text color ("text_other").  
The special "Previous Song" item uses the normal text color ("text").  
Groups are violet ("accent.violet").  
The special item for the current group is cyan ("accent.cyan").  
Special Random items are red ("accent.red").  
Censored songs are orange ("accent.orange").  
Sort items are yellow ("accent.yellow").

#### Controls:
* Menu Left and Menu Right (or controller equivalents) move the wheel.
* Start can do one of 4 things:  
	1.  Select the current song for play, ending the screen.
	2.  Open the bucket the cursor is on, displaying its contents.
	3.  Close the bucket the cursor is on, if it's the current bucket.
	4.  Select the sort item to sort the music wheel.
* Hold Menu Left and Menu Right and press Start to close the current group.  
	This also works with Left and Right on the dance pad.
	If you play a game mode other than dance and want a pad code for this, send
	in your suggestion.
* Press Menu Left and Menu Right at the same time to open the sort menu.  
	The pad code for opening the sort menu is Up, Down, Up, Down in dance, or
	Up Left, Up Right, Up Left, Up Right in pump.
	Send in suggestions for pad codes for other game modes.

#### Sorting:
Songs on the wheel are sorted into buckets.  If there are more than 64 songs
in a bucket, the songs are split into smaller buckets inside the first one.
There is no depth limit here, and buckets are used no matter how you sort the
wheel.  
This matters particularly to people who have large song collections and want
to be able to navigate by title without scrolling past hundreds of other
songs.  
The sort options available are more numerous than those available in other
themes, offering new ways to find the song you want to play.  
When a bucket contains other buckets, or a range of songs, the bucket will
be named to show the range it contains.  For example, in Title Sort, the
bucket named "a...d" contains all the songs that start with the letters a
through d.  
Some sorting options will place a song into multiple buckets.  For example,
using Word In Title sort, "Extreme Dishwasher Race" is placed into the
"extreme", "dishwasher", and "race" buckets because those are the words in
its title.  Other sorting options give different results for each chart in
the song, so each chart is another bucket the song belongs in.  Sorting
options that do this are marked with a *.  
When a sort option is selected, you might see a brief progress message,
sorting takes a bit of time when there are thousands of songs to sort.  
On the sort menu, some of the sorting options are collected into buckets
because there are so many sorting options.  


##### List of all sort options:
Special options are marked in bold.  Sort options that can be explained by
"sorts by <name of sort option>" are only listed by name.
* Group
* Title
* #### * Word In Title  
	This splits the titles of the songs into words, then sorts songs into
	buckets based on those words.  Think of it as giving you the ability to
	find a song when you only know one word in its title.
* BPM
* Artist
* Genre
* Length
* #### * Step Artist  
	Charts for songs are made by step artists, who usually put their name in a
	field in the file.  This allows you to search for charts made by a
	particular step artist.
* #### * Note Count  
	This adds up the number of taps, jumps, and hands in a chart and sorts by
	the resulting total.
* #### * NPS  
	This uses the Note Count total divided by the length of the song as the
	notes per second to sort the songs.
* Meter  
	This is a bucket of 7 sort options.  "Any Meter" is special and sorts by
	all the charts.  The other options only sort by the charts in their
	difficulty slot.
* #### Favor  
	The choices in this bucket sort the songs by the Favor value recorded in
	the selected profile.
* #### * Tag  
	The choices in this bucket sort the songs by the Tags applied to them in
	the selected profile.
* #### Score
	This bucket contains other buckets full of other sort options.  Inside
	each bucket is an option for each difficulty slot, allowing sorting by
	the score in that slot.  
	* Highest is for sorting by the highest score.
	* Newest is for sorting by the newest score.
	* Open is for sorting by how many open score slots are left.
	* Total is for sorting by the number of scores entered.
* #### Rival  
	Every high score name used on the machine is put into a list, and that list
	is sorted so that you can search for scores by a certain high score name.  
	As with the Score bucket, you pick a property and a difficulty slot.  
	* Rank sorts by their position on the high score list.
	* Highest sorts by highest score on that difficulty.
	* Newest sorts by which scores are most recent.


### Special Menu
There is a special menu that can be accessed by pressing Select.  If you
don't have a Select button, it can be opened by holding Menu Left and
tapping Start, or holding Menu right and tapping Start.  
Opening the menu requires the player to set their Options Level to 2 or
higher.  
Some menu options only appear at a higher Options Level, these are marked
with L and the level they appear at.  
Choices:
* Exit Menu
* Profile Favorite+/-  
	Adjust the Favor value for the current song in your profile.  A song's
	Favor value can be any integer.  This allows you to have different levels
	of how much a song is your favorite.
* Machine Favorite+/- (L3)  
	Adjust the Favor value for the current song in the machine profile.
* Edit Tags (L3)  
	Brings up the tags menu, which can be used to toggle which tags are applied
	to the song.  Create "consensual_settings/usable_tags.lua" in your profile
	folder and put the tags you want to use in it.  There is an example file
	in consensual/Other/usable_tags_example.lua to show you the format.  
	The machine profile has its own set of tags and tag settings.
* Edit Pane (L4)  
	This switches the pane info window into a special editing mode that can be
	used to configure the info that is shown.
* Edit Visible Styles  
	This brings up a menu that can be used to toggle which available styles are
	shown.  You must have at least one style visible.  After you close the
	menu, the songs will be filtered to remove songs that do not have any
	playable visible styles and sorted.
* End Credit (L4)  
	This ends the current credit, taking the players to the Name Entry screen.
	Don't hit it by accident.

### Pane Info
Below the difficulty selector, each player has a pane detailing some info
about the chart they have selected.  By default, it just shows basic info
like the number of taps, the top score, the bpm, and the difficulty.  
Every element in the pane can be configured, and the configuration is stored
in the profile.  
Select Edit Pane from the special menu, and the pane goes into edit mode.  
Pick a slot in the pane with the cursor and hit Start to change its value.
This brings up a menu with a list of what you can change the value to.  
Choices:
* done
* make wide  
	A wide slot is spread across the whole pane instead of using only half.
* clear  
	Clear a slot if you want it to be blank.  Blank slots at the bottom of the
	pane are hidden.  If you clear all the slots, the pane is just shown as a
	tiny rectangle.
* chart info  
	Opens a submenu with these choices:
	bpm, meter, author, nps, stream, voltage, air, freeze, chaos, taps, jumps,
	holds, mines, hands, rolls, lifts, fakes.
* favor  
	Pick whether to show the profile or the machine Favor value.
* score  
	Pick whether to show a machine score or a player score and which score slot
	to show.
* tag  
	Pick whether to show a machine tag or a player tag and which tag slot to
	show.
On the score and tag options, pick "Make Machine"/"Make Player" first, then
press Start on the slot number to switch to setting the slot number.

### Special Pad Codes
There are 4 pre-set configurations that can be applied by entering a pad code
on Select Music.  These pad codes set the Rating Cap, Options Level, Pane
Info, and Interface Flags for the player's profile.  Pad codes only exist for
dance game mode because nobody has made suggestions for the other game
modes.  
The Interface Flags and Pane Info settings for each configuration can be set
in the Consensual Service menu.  
* Config Slot 1:  
	Pad Code: Disabled because I hit U, U, D, D, L, R, L, R, on accident.  
	Rating Cap 5, Options Level 1  
* Config Slot 2:  
	Pad Code: L, D, R, L, D, R  
	Rating Cap 10, Options Level 2  
* Config Slot 3:  
	Pad Code: R, D, L, R, D, L  
	Rating Cap 15, Options Level 3  
* Config Slot 4:  
	Pad Code: L, U, R, U, L, D, R, D, L  
	Rating Cap -1 (no cap), Options Level 4  





This guide is getting way too long.  Come back later for the Player Options
Screen, Gameplay Screen, Evaluation Screen, Name Entry Screen, Consensual
Service Menu, and Color Config menu.
