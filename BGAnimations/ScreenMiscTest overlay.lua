local bm_list= {
	'BlendMode_Normal',
	'BlendMode_Add',
	'BlendMode_Subtract',
	'BlendMode_Modulate',
	'BlendMode_CopySrc',
	'BlendMode_AlphaMask',
	'BlendMode_AlphaKnockOut',
	'BlendMode_AlphaMultiply',
	'BlendMode_WeightedMultiply',
	'BlendMode_InvertDest',
	'BlendMode_NoEffect'	
}

local function make_bm_test_pair(name, bma, bmb, x, y)
	return Def.ActorFrame{
		Name= name,
		InitCommand=
			function(self)
				self:xy(x, y)
			end,
--		Def.Quad{
--			Name= "a",
--			InitCommand=
--				function(self)
--					self:xy(-10, -10)
--					self:setsize(15, 15)
--					self:zwrite(true)
--					self:blend('BlendMode_NoEffect')
--				end
--		},
		Def.ActorFrame{
			Name= "a",
			InitCommand=
				function(self)
				end,
			Def.ActorMultiVertex{
				Name= "aa",
				InitCommand=
					function(self)
					self:zwrite(true)
					--self:clearzbuffer(true)
					self:blend('BlendMode_NoEffect')
						local verts= {
							{{0, 0, 0}},
							{{-20, 0, 0}},
							{{-15, -15, 0}},
							{{0, -20, 0}},
							{{15, -15, 0}},
							{{20, 0, 0}},
							{{15, 15, 0}},
							{{0, 20, 0}},
							{{-15, 15, 0}},
							{{-20, 0, 0}},
						}
						for i, v in ipairs(verts) do
							v[2]= solar_colors.blue(.5)
						end
						self:SetDrawState{Mode="DrawMode_Fan"}
						self:SetVertices(verts)
						self:spin()
						self:effectmagnitude(0, 0, 12)
					end
			},
			Def.ActorMultiVertex{
				Name= "ab",
				InitCommand=
					function(self)
					self:zwrite(true)
					self:blend('BlendMode_NoEffect')
						local verts= {
							{{0, 0, 0}},
							{{-15, 0, 0}},
							{{-10, -10, 0}},
							{{0, -15, 0}},
							{{10, -10, 0}},
							{{15, 0, 0}},
							{{10, 10, 0}},
							{{0, 15, 0}},
							{{-10, 10, 0}},
							{{-15, 0, 0}},
						}
						for i, v in ipairs(verts) do
							v[2]= solar_colors.red(.5)
						end
						self:SetDrawState{Mode="DrawMode_Fan"}
						self:SetVertices(verts)
						self:spin()
						self:effectmagnitude(0, 0, 2)
					end
			},
		},
		Def.Quad{
			Name= "b",
			InitCommand=
				function(self)
					self:xy(0, 0)
					self:setsize(60, 60)
					self:diffuse(solar_colors.bg())
					self:diffusebottomedge(solar_colors.red())
					self:ztestmode("ZTestMode_WriteOnFail")
					self:blend('BlendMode_Normal')
				end
		},
	}
end

local xsep= SCREEN_WIDTH / #bm_list
local ysep= SCREEN_HEIGHT / #bm_list

--for ai= 1, #bm_list do
--	for bi= 1, #bm_list do
--		args[#args+1]= make_bm_test_pair(
--			"bm_test" .. ai .. bi, bm_list[ai], bm_list[bi],
--			(ai-1) * xsep, (bi-1) * ysep)
--	end
--end

--args[#args+1]= make_bm_test_pair(
--	"bm_test", bm_list[0], bm_list[0],
--	SCREEN_CENTER_X, SCREEN_CENTER_Y)

