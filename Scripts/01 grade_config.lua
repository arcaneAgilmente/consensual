local grade_configs= {
	default= {},
	itg= {
		{"****", 1},
		{"***", .99},
		{"**", .98},
		{"*", .96},
		{"S+", .94},
		{"S", .92},
		{"S-", .89},
		{"A+", .86},
		{"A", .83},
		{"A-", .80},
		{"B+", .76},
		{"B", .72},
		{"B-", .68},
		{"C+", .64},
		{"C", .60},
		{"C-", .55},
		{"D", 0},
	},
	sm5= {
		{"AAA", 1},
		{"AA", .93},
		{"A", .8},
		{"B", .65},
		{"C", .45},
		{"D", 0},
	},
}
do
	local grades= "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local w1_value= THEME:GetMetric("ScoreKeeperNormal", "GradeWeightW1")
	local miss_value= THEME:GetMetric("ScoreKeeperNormal", "GradeWeightMiss")
	local min_score= miss_value / w1_value
	local diff= (min_score - 1) / (#grades-1)
	local cur_score= 1
	for i= 1, #grades do
		grade_configs.default[i]= {grades:sub(i, i), cur_score}
		cur_score= cur_score + diff
	end
end

grade_config_names= {
	"default", "itg", "sm5"
}

grade_config= create_setting("grade_config", "grade_config.lua", grade_configs.default, 0)

local function sanity_check_grades()
	local grades= grade_config:get_data()
	for key, grade in pairs(grades) do
		if type(key) ~= "number" or type(grade) ~= "table"
		or type(grade[1]) ~= "string" or type(grade[2]) ~= "number" then
			grades[key]= nil
		end
	end
end

grade_config:load()

sanity_check_grades()

function set_grade_config(name)
	if grade_configs[name] then
		grade_config:set_data(nil, DeepCopy(grade_configs[name]))
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
		if score >= grades[i][2] then return grades[i][1] end
	end
	return grades[#grades][1]
end
