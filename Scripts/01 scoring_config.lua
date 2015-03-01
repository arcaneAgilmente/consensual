local default_config= {
	PercentScoreWeightCheckpointHit= 5,
	PercentScoreWeightCheckpointMiss= 0,
	PercentScoreWeightHeld= 5,
	PercentScoreWeightHitMine= 0,
	PercentScoreWeightAvoidMine= 0,
	PercentScoreWeightLetGo= 0,
	PercentScoreWeightMiss= -12,
	PercentScoreWeightW1= 5,
	PercentScoreWeightW2= 4,
	PercentScoreWeightW3= 2,
	PercentScoreWeightW4= 0,
	PercentScoreWeightW5= -6,
	GradeWeightCheckpointHit= 5,
	GradeWeightCheckpointMiss= 0,
	GradeWeightHeld= 5,
	GradeWeightHitMine= 0,
	GradeWeightLetGo= 0,
	GradeWeightMiss= -12,
	GradeWeightW1= 5,
	GradeWeightW2= 4,
	GradeWeightW3= 2,
	GradeWeightW4= 0,
	GradeWeightW5= -6,
}

scoring_config= create_setting("scoring_config", "scoring_config.lua", default_config, -1)
scoring_config:load()

function get_score_weight(score_name)
	return scoring_config:get_data()[score_name] or 0
end
