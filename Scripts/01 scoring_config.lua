local default_config= {
	PercentScoreWeightCheckpointHit= 5,
	PercentScoreWeightCheckpointMiss= 0,
	PercentScoreWeightHeld= 5,
	PercentScoreWeightHitMine= 0,
	PercentScoreWeightAvoidMine= 0,
	PercentScoreWeightLetGo= 0,
	PercentScoreWeightMiss= -12,
	PercentScoreWeightW1= 5,
	PercentScoreWeightW2= 5,
	PercentScoreWeightW3= 4,
	PercentScoreWeightW4= 2,
	PercentScoreWeightW5= 0,
	GradeWeightCheckpointHit= 5,
	GradeWeightCheckpointMiss= 0,
	GradeWeightHeld= 5,
	GradeWeightHitMine= 0,
	GradeWeightLetGo= 0,
	GradeWeightMiss= -12,
	GradeWeightW1= 5,
	GradeWeightW2= 5,
	GradeWeightW3= 4,
	GradeWeightW4= 2,
	GradeWeightW5= 0,
}

scoring_config= create_setting("scoring_config", "scoring_config.lua", default_config, -1)
scoring_config:load()

function get_score_weight(score_name)
	return scoring_config:get_data()[score_name] or 0
end
