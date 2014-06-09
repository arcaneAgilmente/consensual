default_credit_time= 60 * 6 -- The default starting amount of play time for one credit.
song_length_grace= 0 -- This grace amount is added to time remaining when filtering which songs are on the song wheel.  Only applies when not in event mode.
menu_grace_time= 0 -- The amount of time the player can spend on a menu screen before time starts being deducted from their play time.
menu_time_multiplier= 0 -- Time spent on a menu screen is multiplied by this amount before being deducted from the play time.  0 means menu time is free, .5 means that 2 seconds on a menu takes 1 second off of play time.
min_score_for_reward= .75 -- The minimum score to be rewarded with some more time.  At this score, the player will get the min reward.  At a score of 1 (100%), the player will get the max reward.  The reward changes linearly in between.
-- Two modes for the time rewarding system:
-- Reward by percent, rewards the player with an amount of time based on the length of the song time.  Song length is multiplied by the reward value and the result is added to the time remaining.
reward_time_by_pct= true
min_reward_pct= 0
max_reward_pct= .25
-- Reward by time, rewards the player with a fixed amount of time, ignoring song length.  The reward value is added to the remaining time.
min_reward_time= 0
max_reward_time= 30
