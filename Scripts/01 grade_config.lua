local named_configs= {
	default= {
		file= "default_grades",
		1, .9975, .995, .99, .985, .975, .965, .945,
			.925, .885, .845, .765, .685, .525, .365, .045
	},
	itg= {
		file= "default_grades",
		1, .99, .98, .96, .94, .92, .89, .86, .83, .80, .76, .72, .68, .64,
			.60, .55, 0,
	},
	sm5= {
		file= "default_grades",
		1, .93, .8, .65, .45, 0,
	},
}

grade_config_names= {
	"default", "itg", "sm5"
}

grade_config= create_setting("grade_config", "grade_config.lua", named_configs.default, 0)

local function sanity_check_grades()
	local grades= grade_config:get_data()
	for key, grade in pairs(grades) do
		if type(key) == "string" and key ~= "file" then
			grades[key]= nil
		elseif type(key) ~= "number" then
			grades[key]= nil
		end
	end
	if type(grades.file) ~= "string" then
		grades.file= "default_grades"
	end
end

grade_config:load()

sanity_check_grades()

function set_grade_config(name)
	if named_configs[name] then
		grade_config:set_data(nil, DeepCopy(named_configs[name]))
		sanity_check_grades()
	end
end

local gradable_judges= {
	"CheckpointHit",
	"CheckpointMiss",
	"Held",
	"HitMine",
	"MissedHold",
	"LetGo",
	"Miss",
	"W1",
	"W2",
	"W3",
	"W4",
	"W5",
}

local better_judges= {
	CheckpointHit= "CheckpointHit",
	CheckpointMiss= "CheckpointHit",
	Held= "Held",
	MissedHold= "Held",
	LetGo= "Held",
	Miss= "W1",
	W1= "W1",
	W2= "W1",
	W3= "W1",
	W4= "W1",
	W5= "W1",
}

function convert_score_to_grade(judge_counts)
	local weights= {}
	for i, judge in ipairs(gradable_judges) do
		weights[judge]= THEME:GetMetric(
			"ScoreKeeperNormal", "GradeWeight" .. judge)
	end
	local mdp= 0
	local adp= 0
	for judge, count in pairs(judge_counts) do
		local short= ToEnumShortString(judge)
		if better_judges[short] then
			mdp= mdp + ((weights[better_judges[short]] or 0) * count)
		end
		adp= adp + ((weights[short] or 0) * count)
	end
	local score= adp / mdp
	local grades= grade_config:get_data()
	for i= 1, #grades do
		if score >= grades[i] then return i end
	end
	return #grades
end