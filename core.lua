local print = function(str) return ChatFrame1:AddMessage("Clayman: " .. tostring(str)) end
local addon = CreateFrame("Frame")
local parent, castBar

local GetTime = GetTime
local PlayerName = UnitName("player")
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local floor = math.floor

local texture = "Interface\\AddOns\\Clayman\\HalG.tga"

local UnitReactionColor = {
	{ 1.0, 0.0, 0.0 },
	{ 1.0, 0.0, 0.0 },
	{ 1.0, 0.5, 0.0 },
	{ 1.0, 1.0, 0.0 },
	{ 0.0, 1.0, 0.0 },
	{ 0.0, 1.0, 0.0 },
	{ 0.0, 1.0, 0.0 },
	{ 0.0, 1.0, 0.0 },
}

local round = function(float)
	return floor(float*10)/10
end

local OnUpdate = function(self)
	local time = GetTime()
	local startTime = self.startTime
	local endTime = self.endTime
	local duration = self.duration
	if self.casting then
		if time > endTime then
			self.casting = false
			castBar:SetValue(1)
		end
		local elapsed = (time - startTime)
		local per = elapsed / duration
		castBar:SetValue(per)
		castBar.time:SetText(round(elapsed))
		castBar.spark:ClearAllPoints()
		castBar.spark:SetPoint("CENTER", castBar, "LEFT", per * 280, 0)
	--	castBar.spark:SetPoint("RIGHT", castBar, "RIGHT")
	else
		castBar:Hide()
	end

end

function addon:OnEnable()
	parent = CreateFrame("Frame", "ClaymanParent", UIParent)
	parent:SetClampedToScreen(true)
	parent:RegisterForDrag("LeftButton")
	parent:SetFrameStrata("MEDIUM")
	parent:SetMovable(true)

	castBar = CreateFrame("StatusBar", nil, parent)
	castBar:SetHeight(18)
	castBar:SetWidth(280)
	castBar:SetPoint("CENTER", UIParent, "CENTER")
	castBar:SetStatusBarTexture(texture)
	castBar:SetMinMaxValues(0, 1)
	castBar:SetStatusBarColor(1, 1, 1)

	local name = castBar:CreateFontString(nil, "OVERLAY")
	name:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
	name:SetPoint("CENTER")
	name:SetPoint("TOP")
	name:SetPoint("BOTTOM")
	name:SetJustifyH("CENTER")

	local time = castBar:CreateFontString(nil, "OVERLAY")
	time:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
	time:SetPoint("LEFT")
	time:SetPoint("TOP")
	time:SetPoint("BOTTOM")
	time:SetJustifyH("LEFT")

	local bg = castBar:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(texture)
	bg:SetVertexColor(0, 0, 0, 0.4)
	bg:SetAllPoints(castBar)

	local spark = castBar:CreateTexture(nil, "OVERLAY")
	spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	spark:SetVertexColor(1,1,1)
	spark:SetWidth(20)
	spark:SetHeight(36)
	spark:SetBlendMode("ADD")

	castBar.name = name
	castBar.time = time
	castBar.bg = bg
	castBar.spark = spark
	--parent:Hide()

	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

	self:SetScript("OnUpdate", OnUpdate)
end

function addon:UNIT_SPELLCAST_SENT(unit, spellName, spellRank, spellTarget)
	if unit ~= "player" then return end

	if not spellTarget then spellTarget = PlayerName end
	self.target = spellTarget

	local col
	local targetName = UnitName("target")
	if targetName == spellTarget then
		col = UnitReaction("player", "target")
	else
		col = UnitReaction("player", "player")
	end
	self.reactColor = UnitReactionColor[col]
end

function addon:UNIT_SPELLCAST_START(unit, spellName, spellRank)
	if unit ~= "player" then return end

	local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
	startTime = startTime/1000
	endTime = endTime/1000
	self.casting = true
	self.channeling = false
	self.startTime = startTime
	self.endTime = endTime
	local length = (endTime - startTime)
	self.duration = length

	castBar:SetValue(0)

	castBar.name:SetFormattedText("%s --> %s", displayName, self.target)

	castBar:SetStatusBarColor(unpack(self.reactColor))
	castBar:Show()
end

function addon:UNIT_SPELLCAST_DELAYED(unit, spellName, spellRank)
	if unit ~= "player" then return end

	local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
	startTime = startTime/1000
	endTime = endTime/1000
	self.casting = true
	self.channeling = false
	self.startTime = startTime
	self.endTime = endTime

--	castBar:SetValue(0)

	castBar.name:SetFormattedText("%s --> %s", displayName, self.target)

	castBar:SetStatusBarColor(unpack(self.reactColor))
	castBar:Show()

end

function addon:UNIT_SPELLCAST_STOP(unit, spellName, spellRank)
	if unit ~= "player" then return end

	castBar:SetStatusBarColor(1, 0, 0)
	if self.casting then
		self.casting = false
		self.target = nil
		castBar:SetValue(1)
	end
end

addon.UNIT_SPELLCAST_FAIED = addon.UNIT_SPELLCAST_STOP
addon.UNIT_SPELLCAST_INTERUPTED = addon.UNIT_SPELLCAST_STOP

function addon:ADDON_LOADED(arg1)
	if arg1 == "Clayman" then
		self:OnEnable()
	end
end

addon:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)

addon:RegisterEvent("ADDON_LOADED")
