local debug_text_len= 0
local debug_text_current= 0
local debug_text_time= 0
local debug_time_per_attrib= 0

function debug_text_start_on(self)
	debug_text_len= #self:GetText()
	debug_text_current= 0
	debug_text_time= THEME:GetMetric("ScreenGameplay", "GiveUpSeconds") / debug_text_len
	self:stoptweening():ClearAttributes():diffusealpha(1)
		:playcommand("debug_text_update")
end

function debug_text_update(self)
	debug_text_current= debug_text_current+1
	self:ClearAttributes():AddAttribute(
		0, {Length= debug_text_current, Diffuse= fetch_color("text")})
	:AddAttribute(
		debug_text_current, {Length= debug_text_len, Diffuse= fetch_color("text", .5)})
	if debug_text_current < debug_text_len then
		self:sleep(debug_text_time):queuecommand("debug_text_update")
	end
end
