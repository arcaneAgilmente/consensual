# Consensual

A theme for stepmania. 5.3 Edition

This is a WIP upd8 for Consensual that (hopefully) will allow for proper functionality with the Pro Timing system introduced in 5.3

Minimalist in graphics, maximalist in functionality.

## Renderer
You must use the opengl renderer for things to render correctly.  
If you're not on Windows, you're using the opengl renderer already.  
If you are on Windows, find %APPDATA%/Save/Preferences.ini and edit the
VideoRenderers line to match this: ```VideoRenderers=opengl```

## Minimum StepMania version: 5.0.9
5.0.9 has several bug fixes that affect the logo, crash on d3d from blendmode
subtract, the speed of the bubbles, and the image centering prefs.  
NPS calculation uses the Notes radar category that was added in 5.0.8.  
The screen filter is in the notefield board, which puts it above the judgment
in 5.0.7 and under the judgment in 5.0.8 because the TapJudgmentsUnderField
metric is true.  This is why the render order of the notefield board was
changed in 5.0.8.  
Transitions and the colored background might have problems in 5.0.6.
(untested)

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
* Every mod can be set to persist between sessions.
* Customizable pane info.
* Customizable gameplay elements.
* Customizable evaluation info.
* Customizable grading system.
* Customizable scoring values.
* Customizable life values.
* Menu for picking global offset from a list of choices.
* Individual customizations saved to profiles.
* Confetti.
* Customizable color system.
* Unique toasties.
* Random menu music system (if you supply the music and bpm and length data)

# Acknowledgments and Thanks
* shakesoda let me walk in and shape Stepmania however I wanted, even giving
	me direct commit access when he didn't have time to review my pull requests
	anymore.  The only limitation was that backwards compatibility with theme
	code written for SM5 beta 2 had to be maintained.
* freem still hangs out in the IRC channel to give occasional advice and
	moral support.
* dbk2 occasionally finds problems and tests stuff for me when he has time
	away from his thesis.  Also big on the moral support.
* Caitlyn designed the reskin and will hopefully pick colors.
* hellrazor funded the kickbox game mode.  Now if only he would try it
	out... ;)
* Midiman polished the SM5 default theme so that I didn't have to.
* roothorick handles lower-level Stepmania problems like versioning and
	fullscreen on Linux.
* Mad Matt was the other loose cannon adding features to Stepmania's theme
	engine, until he split off to work on his own fork without the hindrance
	of maitaining compatibility.
* Vospi read all of the very long release notes I wrote for SM5 beta 4 and
	Stepmania 5.0.5.  This guide is longer than both of those put together, so
	be warned before you start reading.
* milistisia made various feature suggestions.

# Problems/Editing:
Do not try to edit Consensual yourself, its complicated.  If you instead
submit issues on github, then everybody can have the improved version.  
The best place to report problems with Consensual is on the github page:
https://github.com/kyzentun/consensual/issues
Click the New Issue button and fill it out with all the info you can give.


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

# Menu Music:
The music system in Consensual takes the bpm of the previous song and finds
an entry in the menu music list with a similar bpm and plays that entry.
Scripts/02 music.lua has a comment explaining how to add menu music entries
at the end of the file.


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
* "You should upgrade to Stepmania 5.0.9."  
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
* #### Word In Title *
	This splits the titles of the songs into words, then sorts songs into
	buckets based on those words.  Think of it as giving you the ability to
	find a song when you only know one word in its title.
* BPM
* Artist
* Genre
* Length
* #### Step Artist *
	Charts for songs are made by step artists, who usually put their name in a
	field in the file.  This allows you to search for charts made by a
	particular step artist.
* #### Note Count *
	This adds up the number of taps, jumps, and hands in a chart and sorts by
	the resulting total.
* #### NPS *
	This uses the Note Count total divided by the length of the song as the
	notes per second to sort the songs.
* Meter  
	This is a bucket of 7 sort options.  "Any Meter" is special and sorts by
	all the charts.  The other options only sort by the charts in their
	difficulty slot.
* #### Favor  
	The choices in this bucket sort the songs by the Favor value recorded in
	the selected profile.
* #### Tag *
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
	to the song.  Create "consensual_ridiculous_settings/usable_tags.lua" in your profile
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
	Pad Code: Disabled because I hit U, U, D, D, L, R, L, R, on accident when
	changing difficulty and then picking a song.  
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



## Player Options Screen
Consensual's options screen is organized around nested menus.

The profile's Options Level changes which menus are visible on this screen.
At OL 1, Speed, Perspective, Noteskin, Options Level, Rating Cap, and Profile
Options are the only choices.  Above OL 1, Noteskin moves into Decorations,
and Options Level and Rating Cap move into Special.

In general, the choices that are hidden at lower OL are expected to be used
by fewer people, or need some experimentation to understand.  OL 4 shows
everything.

Each player uses half the screen for their menus, no shared cursor or shared
screen problems.  Each player has two menu displays, one for the menu they
are currently on, and one for the menu it is inside.  To solve the problem of
new players accidentally going into the Player Options Screen and getting
confused, the players' cursors start on the "Play Song" option, which makes
it very clear how to leave the screen without doing anything.

Every menu on the Options Screen has a header and a status field.  The header
is usually the name of the menu or the name of the modifier that is being
set.  The status field is usually the current value of the modifer.  
Every menu also has a "back" element at the top of the list that confirms the
current setting and goes back to the previous menu.

### Menu Types

#### Set Peristent
Every modifier has a Set Persistent choice on the menu.  When Set Persistent
is chosen, the current value of the modifier is saved to the profile and it
will be set to that value every session.  
Song modifiers like Music Rate and Haste must be set to persistent to not be
reset after every song.  
Most settings that do not have the Set Persistent choice were already
persistent.  The things in the Decorations->Effects and Spline Demos menus
don't have the Set Persistent choice because they're abnormal and probably
not something that anyone wants to persist.  
If there's anything that doesn't persist that needs to, send in a suggestion.

#### Adjustable Float  
Most themes limit modifiers to simple on/off toggles, or a few choices
between 0% and 100%.  Consensual is written to allow setting any modifier
to any value, unless the internal code in Stepmania forces it to be an
on/off switch.  
Choices:
* "+n" increases the value
* "-n" decreases the value
* "scale*10" multiplies the n used to change the value by 10.
* "scale/10" divides the n used to change the value by 10.
* "*pi" is a special choice that only appears for the spin modifiers.  It
	toggles whether the value is a multiple of pi.
* "Round" rounds the value to the nearest whole number.
* "Reset" resets the value to 0.

#### Special Modifiers
Most of the modifiers are more fun to learn about through experimenting, but
some are worth mentioning here.

* BG Brightness  
	Instead of a screen filter, the BG Brightness preference is in the Special
	menu.
* Perspective  
	The Perspective has the old style choices of Incoming, Space, Hallway, and
	Distant, but also has Skew and Tilt.  Internally, Incoming and Space apply
	both Skew and Tilt, and Hallway and Distant only apply Tilt.  Having Skew
	and Tilt separated allows trying out different values for them.
* Profile Options  
	This allows you to set the data that is stored in the profile without using
	Stepmania's normal profile managing screen or editing the Editable.ini
	file.
* Playback Options  
	This contains the Rate modifier and the Haste modifier.  Haste can be
	negative.
* Floaty Mods  
	Practically every mod in Stepmania is a number, so they're all in here,
	organized by type.
* Judgment Y/Combo Y  
	The position of the judgment and combo can be set like any other modifier.
	A negative value moves the judgment up.  The combo position is relative to
	the judgment.  The screen is 480 units tall, so -240 moves the judgment to
	the top.
* Chart Mods  
	The various mods for modifying the chart are in here.
* Song Tags  
	The same tags menu that was discussed on the Select Music Screen.
* Decorations  
	Many things that appear on the Gameplay and Evaluation screens can be
	toggled on or off with flags.  Evaluation Flags and Gameplay Flags will be
	listed on their screens.  
	Interface Flags:  
	The ones with Random in the name toggle per-player Random items on the music
	wheel.  Some use the meter of the last chart played, and allow picking a
	random song with an easier, harder, or same meter chart.  Score Random uses
	the score to decide whether its songs should be easier or harder.  
	Unplayed Random picks a random song that has not been played on the current
	difficulty.  
	Low Score Random picks a random song where the player has scored below the
	percent set in Low Score Random Threshold.
	Straight Floats toggles whether to show modifiers as numbers from 0 to 1 or
	percents from 0% to 100%.  
	Verbose BPM toggles whether the speed modifier is shown next to the bpm.
* Unacceptable Score  
	Sometimes, a score is too bad to accept finishing the song with.  This
	allows you to set a threshold for automatically resetting to the beginning
	of the song if you can't get the score you want.  It can be set to either a
	maximum number of dance points missed, or a minimum score percentage.  The
	number of times to reset is also configurable.
* Kick Recover Time  
	If you're not in kickbox mode, this shouldn't even be visible.  In kickbox
	mode, this sets the amount of time that must be before and after a kick in
	a chart made by the autogen system.
* Next Screen  
	Hit Start on the Select Music option in this menu to immediately go there.


## Gameplay Screen
The song progress bar at the bottom of the screen cycles through several
colors to indicate progress through color coding, and has the current time
and the song length.

This is a list of the flags in the Gameplay Flags section of Decorations on
the Player Options Screen.
* allow_toasty  
	This toggles whether the player should have toasties appear.  Toasties are
	still recorded in the profile, this only toggles the feedback for them.
	You'll have to discover what the toasty effects are yourself.
* bpm_meter  
	Toggles the BPM display.
* chart_info  
	Toggles the chart info that lists the step artist, difficulty, and meter.
* combo_confetti  
	If this is off, the player will not get confetti for reaching 1000 combo.
* dance_points / pct_score  
	The score display can show the percent score, the dance points, or both, or
	neither.
* score_splash  
	At the end of the screen, a score over 96.875% earns a score splash,
	colored by how close to 100% it is.
* Combo Splash Threshold  
	Use this to set the minimum full combo quality for a combo splash.  The
	combo splash is always colored by the worst judgment earned, if it appears.
* judge  
	A list of every judgment earned is placed behind the notefield.
* error_bar  
	The judgment contains a colored rectangle showing how far early/late a note
	was hit.  If the rectangle is left of center, the note was hit early.
* score_confetti  
	A score above 99.5% earns confetti, unless you don't want it.
* score_meter  
	Next to the life bar is a meter showing the current score as a rectangle.
	It grows according to a formula chosen to make the difference between 98%
	and 99% much bigger than the difference between 50% and 51%, to reflect the
	relative difficulty of improving higher scores.  For the curious, this is
	the formula:  score^((score+1)^((score*e)))
* sigil  
	The sigil is a piece of art that tracks your current score out of what is
	currently possible.
* still_judge  
	The judgment will not move or change size with every tap if this is true.


## Heart Rate Entry Screen
If one of the profiles in use has heart rate based calorie calculation
enabled, the Heart Rate Entry Screen will appear between Gameplay and
Evaluation.  Simply use the timer to take your pulse and enter it with the
numpad.


## Evaluation Screen
In single player, score data is on the player's side, and profile data is on
the opposite side.  In versus, profile data can be accessed by pressing left
or right.

If Select is held longer than .3 seconds, a screenshot is taken and named
with the current song and saved to the player's profile.

If that profile's Options Level is 2 or higher, the menu can be brought up by
tapping Select.  This has options for changing the Favor level, tagging the
song, toggling the flags for this screen, or ending the credit.

Each of the flags toggles a different element on the screen.  Turn them all
off, and you're left with just the song background.  The banner, judge_list,
and reward elements are shared, so if either player has them on, they are
shown.

Flag list:
* chart_info
* pct_score
* dance_points
* offset
* score_early_late
* lock_per_arrow  
	Per-arrow scores can be accessed by turning this flag off and using left or
	right.
* color_combo
* color_life_by_value
* color_life_by_combo
* pct_column
* song_column
* session_column
* sum_column  
	The sum column shows a total of the judgment it is next to, plus the number
	of better judgments.
* best_scores
* profile_data
* combo_graph
* life_graph
* style_pad
* banner
* judge_list
* reward


## Name Entry Screen
The name entry screen has rows with the alphanumerics and some symbols.  The
down and up arrows at the beginning and end of each row are for moving the
cursor between rows if there aren't Menu Up and Menu Down buttons.

There are also choices on the bottom row for scrolling the score lists, if
more than 3 songs were played, and for taking a screenshot.


## Consensual Service Menu
Everything in the Consensual Service Menu has a help popup to explain it, so
this section is going to be about the inner workings of some systems.  
The default time for the help popup is 10 seconds of idle, but this can be
configured in the Help Config section, and the change is applied without
reloading the service menu.

### Censoring System
Consensual has a censoring system that allows a machine operator to mark
songs as censored.  When a song is marked, it is removed from the music wheel
and is not selected by any Random item.  The list of censored songs is saved
to Save/consensual_ridiculous_settings/censor_list.lua so that the machine operator can
look at it later to decide whether to delete the song.

To use the censoring system, you must either be on Select Music, or
Evaluation.  Press the Censor Privilege Key on a keyboard (default is 'c',
this can be configured), and the censoring options will be added to the menu
for that screen, and the menu will be accessible even if the player's Options
Level is too low.

Censor and Uncensor mark or unmark the current song.  If a bucket is
currently selected on the music wheel, then all songs inside the bucket are
marked or unmarked.  This includes all songs inside buckets inside the
bucket, and so on.

Toggle Censoring temporarily puts censored songs back on the music wheel.
They are marked with a special color so they can be easily seen.  The next
time the credit ends, censoring will be turned back on.  This allows the
machine operator to undo an accidental censoring.

Songs that are marked as censored are not deleted because it is not as easy
to reverse a deletion as it is to remove an entry in the censor list.  The
filenames in the censor list are relative to Stepmania's internal view of the
filesystem, because Stepmania doesn't (and shouldn't) tell the theme where
songs really are.  If the filename starts with "/AdditionalSongs/", then it
is inside one of the folders loaded from the AdditionalSongFolders
preference.


### Points of interest:
* #### Help Config
	Set the Service Help Time to a convenient value like 1 and read the info.

* #### Consensual Config Key
* #### Color Config Key
	The initial menu recognizes two special keys, outside the normal mapping.
	These are intended to be used by the machine operator to access the
	Consensual Service Menu or the Color Config when those menu options are
	hidden.

* #### Censor Privilege Key
	Set this to the key you wish to use to enable the censor menu options on
	Select Music and Evaluation.

* #### Initial Menu Choices
	Allows you to turn off each choice on the initial menu.  Use it when
	preparing for an event or configuring for arcade use to hide things like
	Edit Mode and Exit.

* #### Idle to Demo Time and Demo Show Time
	Can be used to turn off demo mode.

* #### Set Star Points
	Used to reduce the detail level of the stars on the initial menu if turning
	on SmoothLines doesn't bring the frame rate up enough.

* #### MenuUp/Down and Select
	If you have a Select button on your cabinet, you should make sure you use
	the Set Have Select Button option to let Consensual know.  This enables
	various things that require a select button on Select Music, such as
	changing difficulty by holding Select and tapping MenuLeft/Right.  If this
	option is not set to Yes, the things that rely on having Select use
	alternatives instead, and using the Select button won't work.

	If you have MenuUp and MenuDown buttons, or are using a dance pad for
	navigation (which translates the pad's up/down into MenuUp/Down), or
	similar change Set Menus Have Up/Down to Yes to allow menus to be navigated
	with the up/down instead of only left/right.

* #### Timed Sets
	Consensual uses a timed sets for credits.  Instead of allowing players to
	pick 3 songs, players get 6 minutes of song time.  Playing a song uses up
	time, scoring high gives a small reward, and when the time runs out, the
	credit is over.

	The current remaining time is added to the Grace Time, and all songs
	shorter than that total are filtered out.  When the current remaining time
	is below Min Remaining Time, or no songs are left after filtering, the
	credit is over.

	The player can be rewarded with either a percentage of the song's length,
	or a flat amount of time.  Be careful when configuring the reward time to
	not configure it to allow playing forever.

	The reward for a good score is applied regardless of the song's difficulty
	or meter, so it's not restricted to only experienced players.

* #### Grading Config
	The grading system can be configured to have any number of tiers, and use
	any image you feel like adding, as long as it's a sprite sheet.  The help
	tooltips should explain it well enough.  Make sure to pick the
	"Save Grading Config" option after configuring it to what you want.

* #### Scoring Config
	After changing any of the values in the scoring config, you must hit
	Shift+F2 to reload metrics or restart Stepmania for the changes to take
	effect.

* #### Offset Choices
	The offset choices menu allows you to create a list of different global
	offsets to choose from before starting a credit.  This is useful if you
	play on pad and keyboard and need different offsets for each.

* #### Flags Config/Pane Config
	These two options are used to configure the preset flag/pane config slots
	discussed on Select Music.



## Color Config Screen
Every color used by Consensual can be configured here.  Except this screen.
This screen uses hardcoded colors to keep someone from accidentally making
it unreadable.

Colors can be set to specific hex code value, or set to reference another
color by name.  When setting a color to reference another color, you must
supply the full path to the color like this: "accent.violet".  This example
tells Consensual to look inside the group named "accent" for a color named
"violet" and use that.

Most elements use the basic colors at the top level, such as "text" and
"stroke".  More important elements have their own named groups for the colors
they use.

Set Alpha is provided as a separate menu option so that the same alpha can
be applied to all colors in a group.

bg is used to color the background layers of things.  It should be a color
that text will stand out well from.

bg_shadow is an alternate background color.

rev_bg and rev_bg_shadow color frames around elements that aren't associated
with a player.

text and text_other are used to color text.

stroke is used for the stroke layer on text to make it stand out when it's
not on something colored with a bg color (like the text on Gameplay.

accent is a group of colors used to have names for common colors.  Mostly,
these are referenced by credits, player, judgment, difficulty, percent, and
so on.

credits is the color used by the credit display on the initial menu.

player contains the colors used to color things associated with one or both
players, like the cursors or the frames around pane info, or results on
Evaluation.

judgment contains the colors used to color the judgment text on Gameplay and
to color code results on Evaluation.

difficulty contains the colors used to color the difficulty selector on \
Select Music.

percent is used by various elements that need to show some progress from a
low value to a high value.  You can add more numbered elements to this group
to show progress with a finer granularity, or remove elements to make the
granularity larger.

number is used to color ascending numbers that don't have a fixed range.  Add
more entries to make the colors extend higher.  (actually this is only used
to color chart meter ratings above 12 right now)

score is used to color scores above 96.875%.  More entries means more colors
in that range.  Since this references percent by default, changes to percent
will affect this too.

bpm is used color bpms that are above 200 or below 100.

speed is used to color reading speeds above 400.

hours is used to color the clock on the initial menu.  It cycles through the
colors in this group.

help is used to color the help layer and text.

music_select has the colors for the elements on Music Select.  
music_select.remaining_time is used to color the text for the remaining time
in the credit.  
music_select.sort_head is the color of the word "Sort", which is the header
for the sort info.  
music_select.sort_type is the color for the name of the current sort.  
music_select.curr_group is the color for the name of the current group.  
music_select.music_wheel is the songs used by the music wheel.  They are used
to color the quads behind the text of the music wheel items, at 0.25 luma.
(luma is reduced using a gamma corrected method)  
music_select.music_select.current_group is for the current group  
music_select.music_select.group is for other groups  
music_select.music_select.random is for a random entry  
music_select.music_select.censored_song is for censored songs  
music_select.music_select.prev_song is for the previous song  
music_select.music_select.song is for a song  
music_select.music_select.sort is for a sort  
music_select.steps_selector has the colors used by the steps menu.  
music_select.steps_selector.pick_steps_type is the color of the circle for
the "Pick Steps Type" choice.  
music_select.steps_selector.pick_song is the color of the circle for the
"Pick Song" choice.  
music_select.steps_selector.number_stroke is the stroke color for the numbers
on the choices.  
music_select.steps_selector.number_color is the main color for the numbers
on the choices.  
music_select.steps_selector.name_stroke is the stroke color for the names
on the choices.  
music_select.steps_selector.name_color is the main color for the names on the
choices.  

common_background is the set of colors used for coloring the background.  
common_background.center_color is the color of the center of the circle.  
common_background.inner_colors is a set of colors that will be equally spaced
around the circle's inner edge.  
common_background.outer_colors is a set of colors that will be equally spaced
around the circle's outer edge.  The first entry in outer_colors will be used
to color the fullscreen quad behind the circle.  
This allows the circle to have one color in the center, then fade to other
colors halfway to its edge, then fade to an edge color.  
The bg_start_angle value in the bubble config controls the angle the first
color is placed at.

gameplay.failed, gameplay.normal_exit, and gameplay.cancel are used to color
the circular wipe that is used when gameplay ends without a combo or score
splash.  
gameplay.lifemeter.battery has the colors used for the sections on the
battery life bar.

prompt is used for coloring text entry prompts.

score_list is used for coloring the high score lists shown on Name Entry.


## Congratulations
You scrolled to the end of the guide.  If you actually read it all, even
bigger congratulations.
