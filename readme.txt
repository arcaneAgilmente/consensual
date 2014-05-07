Some theme elements might overlap with each other if the aspect ratio isn't 16:10.  If they do, report your aspect ratio, resolution, and the elements to Kyzentun so they can be fixed.

This theme is only tested on the tip of the github repository.  If you're not building from up to date source, some things that rely on recently added features might not work.

Make sure you set SongsPerPlay in Preferences.ini to something high so that my replacement for the stage system will work.  (I set it to 128)
This doesn't matter if event mode is on or the coin mode isn't set to pay.
Don't set coin mode to pay.

Initial screen:
2 player mode is under Style->Versus.
Double mode doesn't have a specific menu option because this theme supports changing style on SelectMusic.
Course or marathon mode is under Playmode->Nonstop.
Course mode is under half-hearted support.
Each player that is joined must select a profile if enough profiles exist.
Some per-player theme specific settings are stored in the profile, so making one is useful.
Use some other theme to make a profile if you don't already have a local profile.  Loading profiles from USB is supported but not forced.


SelectMusic:
The amount of info shown in the pane display is controlled by pad codes.
simple is currently the default.
Pad codes:
none:  left, left, left, right, right, right, up, up, up, down, down, down
simple:  left, down, right, left, down, right
all:  right, down, left, right, down, left
excessive:  left, up, right, up, left, down, right, down, left


The Music Wheel:
A custom music wheel is used.  This music wheel is recursively bucket sorted to make navigating huge song lists easier.  Pad code for changing to select sort is up, down, up, down.  If people say it's hard to understand, I'll add more explanation.


Options screen:
Navigate the menu with up, down, and start.
The "<--" at the top level options menu is exit.  Both players must be on exit if two players are joined.
Any option that can be set with a floating point value is controlled by a menu of numbers that change its current value.
Most of them are buried at the deepest level, "Too Many".

Unsupported options:
no mines, attackmines

Special options:
Speed:
	I have my own custom way of handling speed mods, so if you use CustomSpeedMods.txt, it's irrelevant.
	The currently selected speed mod is displayed at the top.
  The menu options are four numbers, and then the different modes.
	The numbers increase or decrease the speed as expected.
	"Xmod" changes the mode to the old x based system.
	"Cmod" is the cmod system of speed mods.
	"Mmod" is the mmod system, which just calculates an xmod for you based on the scroll speed you choose.
	"CXmod" is Jousway's idea.  It works similarly to Mmod, calculating an xmod to use, but it recalculates the xmod every time the bpm changes.
	"Driven" is the mmod system, with the "Driven" style, where the targets move instead of the arrows.  Overhead perspective is recommended when in use.
	"Alt Driven" is the mmod system, with the "Driven" style, where the targets move instead of the arrows.  The targets reverse direction at the edges instead of resetting.
	The chosen speed setting is saved to the profile.
Feedback:
  Sigil:  Enables a sigil feedback during gameplay.  It is a combined life bar and score meter.  The complexity of it comes from the score out of the current possible (based only on steps that have gone by).
  Judgement:  A list of all TapNoteScores gathered so far.
  Offset: A rectangle between the combo and the judgment showing how far off your timing is.
	Score meter:  A meter adjacent to the life bar that fills non-linearly with the percent of dance points earned.
  Dance Points: Display of current dance points out of maximum dance points.
  Chart Info: Display of who made the chart, the difficulty, and foot rating.
  BPM Meter: Displays the current bpm during the song, adjusted for any rate or haste mod that is active.
	Song/pct/session/sum column:  Flags for enabling columns on the score screen.
	Best scores:  Whether to show the best scores on the score screen.
	Allow toasty:  Whether to allow the toasty.
  Straight Floats: Whether the float mods are in the old % style or just the raw numbers.
	The flags set in the Feedback menu are saved to the profile.
Sigil Detail:  The maximum detail of the sigil feedback.
Sigil Size:  The size of the sigil feedback.
Driven Min:  Configuration for the Driven speed mod.
Driven Max:  Configuration for the Driven speed mod.
Mine Effects:
	Mod changes occur when a mine is hit.  This menu selects which effect occurs.
	Suggestions for new effects or tuning existing effects are welcome.
	The chosen mine effect is saved to the profile.
Distortion:
	Toggle text distortion.

Gameplay screen:
The bar inward from the life meter is a score meter that fills based on your current dance point percentage.  It is colored by the worst judgement picked up yet.
Dance point total out of maximum is at the top of the screen, colored by worst judgement.
Chart author and foot rating are below that.

Score screen:
Self explanatory.
Press Up to see profile stats.
