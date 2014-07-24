Some theme elements might overlap with each other if the aspect ratio isn't 16:10.  If they do, report your aspect ratio, resolution, and the elements to Kyzentun so they can be fixed.

This theme is only tested on the tip of the github repository.  It should work on the latest nightly build.  It will not work on SM5 beta 3.

Initial screen:
2 player mode is under Style->Versus.
Double mode doesn't have a specific menu option because this theme supports changing style on SelectMusic.
Course or marathon mode is under Playmode->Nonstop.
Course mode is disabled because it causes problems.
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

Special menu on Select Music:
Press select to bring up the song properties menu.
Alternatively, hold MenuLeft and press Start to bring up the song properties menu.
Current options:
  Machine Favor +1/-1:  Adjusts the machine favor value for the song.
  Player Favor +1/-1:  Adjusts the player's favor value for the song.
  Censor:  Marks the song as censored.
  Edit Pane Settings:  Switches the pane display to edit mode.
Press select a second time to bring up the tags menu.
Holding select will not bring up the menu because of the bindings that use select plus another button to change something else.
Pad codes cannot be used while in the special menu.

Special menu on Evaluation:
The song properties and tags menus can also be accessed on the Evaluation screen, by tapping select, or by holding MenuLeft and tapping Start.
Hold MenuRight and tap Start to take a screenshot on Evaluation if you don't have a Select button.

Pane display on Select Music:
The pane display on Select Music can be customized.
Press select at any time to exit pane edit mode.
Select an item with the cursor and hit start to set what that item should display.  Choices are chart info (bpm, rating, author, radar values), favor (machine/player), score (machine/player and slot), tag (machine/player and slot).
Some settings require a number to be set, move the menu cursor to the number and hit start to edit the number, then left/right to change the number value.
Items can be made wide or narrow.  Wide items take up the full pane width.

The Music Wheel:
A custom music wheel is used.  This music wheel is recursively bucket sorted to make navigating huge song lists easier.  Pad code for changing to select sort is up, down, up, down.
Long explanation:
The music wheel is based around the idea of recursive buckets with no depth limit. Min bucket size is 32, max bucket size is 96. Any bucket smaller than the minimum is combined with an adjacent bucket. Any bucket larger than the maximum is split into smaller buckets. Buckets that are song groups are not combined with other buckets.
Only the currently open bucket is displayed. The wheel works as a sort of stack. Open a bucket to descend and see what is inside it, close it by picking its name to ascend to the previous bucket.
Additionally, in group sort mode, groups that share the same first "word" of their name are put into a combined bucket. The shared first word is clipped off the displayed title when viewing the entries inside the bucket.
From a usability perspective, this means that you no longer have to scroll past hundreds of irrelevant songs or groups to choose the one you want. In title sort, this is especially important, because "The " is a popular choice for the beginning of a song title.
Random:
There is the traditional Random option on the wheel, which picks a random song from the current bucket or any sub-bucket. In addition, there are four per-player random options. 
"Random Easier" - one foot rating easier than the previous chart
"Random Same" - same foot rating as the previous chart
"Random Harder" - one foot rating harder than the previous chart
"Random +n" - n is calculated based on player's score on the previous chart. The range for n is -4 to 4 for 8 footers and below, -3 to 3 for 8-10 footers, -2 to 2 for 10-13 footers, and -1 to 1 for anything above 13. 100% score will make it apply the maximum, and 62.5% score or below will make it apply the minimum.
Sorting:
The following simple sort options are supported: Group, Title, BPM, Artist, Genre, Length.
In addition, there are more complicated sort options:
"Meter" sort folder that allows you to pick a difficulty from Beginner to Edit for sorting by meter.
"Score" sort folder, pick one of "Highest", "Newest", "Open", "Total" and select a difficulty for sorting by score.
"Rival" sort folder, pick a rival name (from the list of all names used on the machine), one of "Rank", "Highest", "Newest", and a difficulty to sort based on that rival's scores.
"Favor" sort folder, pick one of "Machine Favor", "P1 Favor", or "P2 Favor" to sort by how favored the song is.

Song favoriting system:
Each song has an adjustable "favor" value.  The default is 0 and it can be adjusted up or down to any integer value.  The favor value can be displayed in the pane display, and used for sorting songs.  Each profile has a separate favor value for each song, so one profile's favorites do not affect the machine favorites or the favorites of another profile.
Favorites are saved in PROFILEDIR/favorites.lua.

Song censoring system:
Songs that are marked as censored are filtered out of the song list.
The list of censored songs is saved in Save/censor_list.lua

Song tagging system:
Songs can have tags applied to them, and be sorted by tag.  Each profile has separate tag settings.
The menu has the "Reload tags" option, "Edit Machine Tags", and a list of usable tags.  Hit start on a tag to toggle its value for the current song.
"Reload tags" reloads the usable tags file, use it when adding new tags to be able to use them immediately.
"Edit Machine Tags" switches the menu to editing the machine profile's tags for the song.  When in machine tag editing mode, the "Edit Machine Tags" option becomes "Edit Player Tags", which switches back to player tag editing mode.
The list of tags that can be used is loaded from PROFILEDIR/usable_tags.lua.  It's a simple lua table of strings.  Other/usable_tags_example.lua is an example.
Tag settings are saved in PROFILEDIR/song_tags.lua.


Options screen:
Navigate the menu with up, down, and start.
The "<--" at the top level options menu is exit.  Both players must be on exit if two players are joined.
Options are semi-organized by category.
Floaty Mods:
	Any modifier that accepts a floating point value (besides special cases for
		rate and speed) is set through a common interface.
	The actions are increment, decrement, increase scale, decrease scale,
		round, and reset.
	The current value for the modifier is displayed at the top.
	If the "straight_floats" option is true, the current value is a number,
		where 1.0 is equivalent to 100%.
	The increment/decrement options increase or decrease the current value.
	The increase/decrease scale options change the size of the increment.
	Round rounds the current value to the nearest integer or n00%.
	Reset sets the current value to the default (usually 0).
	Some modifiers are angles and have a special toggleable option for setting
		whether the current value should be treated as a multiple of pi.  The pi
		setting is not stored, so if the menu is closed and reopened, it is lost.

Unsupported options:
Clear

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
	Score early/late:  Whether to split up the stats on the score screen into early/late.
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

Profile options:
	Some of the editable profile options can be edited through the options screen in the Profile Options menu.  Consensual has support for calculating calories burned from heart rate, song duration, and profile data.

Gameplay screen:
The bar inward from the life meter is a score meter that fills based on your current dance point percentage.  It is colored by the worst judgement picked up yet.
Dance point total out of maximum is at the top of the screen, colored by worst judgement.
Chart author and foot rating are below that.

Score screen:
Self explanatory if you have the flags for special stuff at defaults.
Profile data is shown on the other player's side if in single player.
Use left/right on the pad or the menu buttons to change which column stats are shown for.  The dance pad highlights the current column if an individual column is being viewed.
If two players are joined, the profile data is accessed the same way the columns are.
Machine best and player best are shown with the current score's rank above the player's stats if the best_scores flag is set.
The dance pad diagram indicates the play style and which column the stats are for.
Offset stats are shown if the offset flag is set.  The average is how far off the steps were on average (by totaling absolute values).  The total is the accumulated total (by absolute values).
The percent column shows what percent each judgment was out of the total.
The song column shows how many of each judgment occurred in the song.
The session column shows how many of each judgment occurred in the session.
The sum column is a total of the session column values with the same or better judgment.
The combo graph is at the edge of the screen and colored by the step judgments that affect the combo.
The life graph is inward from the combo graph and colored to indicate where the first judgment of each type occurred.
The color coding on the graphs is the same as in the stats.
