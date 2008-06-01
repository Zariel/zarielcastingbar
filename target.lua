local print = function(str) return ChatFrame1:AddMessage("ZarielCastingBar: " .. tostring(str)) end
local addon = CreateFrame("Frame")
local parent, castBar

local GetTime = GetTime
local UnitName = UnitName
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local floor = math.floor
local format = string.format

local texture = "Interface\\AddOns\\ZarielCastingBar\\HalG.tga"

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
	return format("%0.1f", floor(float*10)/10)
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
			castBar.stopTime = time
			return
		end
		local elapsed = (time - startTime)
		local per = elapsed / duration
		castBar:SetValue(per)
		castBar.time:SetText(round(elapsed))
		castBar.spark:ClearAllPoints()
		castBar.spark:SetPoint("CENTER", castBar, "LEFT", per * 300, 0)
	elseif self.channeling then
		if time > endTime then
			self.channeling = false
			castBar:SetValue(0)
			castBar.stopTime = time
			return
		end
		local elapsed = (time - startTime)
		local per = elapsed / duration
		castBar:SetValue(1 - per)
		castBar.time:SetText(round(duration - elapsed))
		castBar.spark:ClearAllPoints()
		castBar.spark:SetPoint("CENTER", castBar, "RIGHT", -per * 300, 0)
	elseif self.fade then
		-- lol quartz copy pasta
		local alpha
		local stopTime = self.stopTime
		if stopTime then
			alpha = stopTime - time + 1
		else
			alpha = 0
		end
		if alpha >= 1 then
			alpha = 1
		end
		if alpha <= 0 then
			self.stopTime = nil
			castBar:Hide()
		else
			castBar:SetAlpha(alpha)
		end
	else
		castBar:Hide()
	end
end

local KillBliz = function()
	local dummy = function() end
	local cb = TargetFrameSpellBar
	cb:Hide()
	cb:UnregisterAllEvents()
	cb:SetScript("OnUpdate", dummy)
	cb.Show = dummy
	cb.RegisterEvent = dummy
end

function addon:OnEnable()
	parent = CreateFrame("Frame", "ClaymanParent_Target", UIParent)
	parent:SetClampedToScreen(true)
	parent:RegisterForDrag("LeftButton")
	parent:SetFrameStrata("MEDIUM")
	parent:SetMovable(true)

	castBar = CreateFrame("StatusBar", nil, parent)
	castBar:SetHeight(18)
	castBar:SetWidth(300)
	castBar:SetPoint("BOTTOM", oUF.units.target, "TOP", 0, 25)
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
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")

	self:SetScript("OnUpdate", OnUpdate)

	KillBliz()
end

function addon:PLAYER_TARGET_CHANGED()
	if UnitCastingInfo("target") then
		self:UNIT_SPELLCAST_START("target")
	end
end

function addon:UNIT_SPELLCAST_SENT(unit, spellName, spellRank, spellTarget)
	if UnitName("target") ~= UnitName(unit) then return end

	if not spellTarget then spellTarget = UnitName("target") end
	self.target = spellTarget

	local col
	local targetName = UnitName("targettarget")
	if targetName == spellTarget then
		col = UnitReaction("target", "targettarget")
	else
		col = UnitReaction("target", "target")
	end

	self.reactColor = UnitReactionColor[col] or { 1, 0, 0}
end


function addon:UNIT_SPELLCAST_START(unit, spellName, spellRank)
	if UnitName("target") ~= UnitName(unit) then return end

	local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
	startTime = startTime/1000
	endTime = endTime/1000
	self.casting = true
	self.channeling = false
	self.startTime = startTime
	self.endTime = endTime
	self.fade = true
	local length = (endTime - startTime)
	self.duration = length

	castBar:SetAlpha(1)
	castBar:SetValue(0)

	if not self.target then
		self.target = UnitName("target")
	end

	castBar.name:SetFormattedText("%s --> %s", displayName, self.target)

	--castBar:SetStatusBarColor(unpack(self.reactColor))
	castBar:SetStatusBarColor(1, 0, 0)
	castBar:Show()
end

function addon:UNIT_SPELLCAST_DELAYED(unit, spellName, spellRank)
	if UnitName("target") ~= UnitName(unit) then return end

	local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
	startTime = startTime/1000
	endTime = endTime/1000
	self.startTime = startTime
	self.endTime = endTime
end

function addon:UNIT_SPELLCAST_SUCCEEDED(unit)
	if UnitName("target") ~= UnitName(unit) then return end
	castBar:SetStatusBarColor(0, 1, 0)
	self.casting = false
	self.target = nil
	self.stopTime = GetTime()
	castBar:SetValue(1)
end

function addon:UNIT_SPELLCAST_STOP(unit, spellName, spellRank)
	if UnitName("target") ~= UnitName(unit) then return end

	if self.casting then
		castBar:SetStatusBarColor(1, 0, 0)
		self.casting = false
		self.target = nil
		self.stopTime = GetTime()
		castBar:SetValue(1)
	end
end

function addon:UNIT_SPELLCAST_CHANNEL_START(unit, spellName, spellRank)
	if UnitName("target") ~= UnitName(unit) then return end

	local spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
	startTime = startTime/1000
	endTime = endTime/1000
	self.casting = false
	self.channeling = true
	self.startTime = startTime
	self.endTime = endTime
	local length = (endTime - startTime)
	self.duration = length
	self.fade = true

	castBar:SetAlpha(1)
	castBar:SetValue(1)

	if not self.target or self.target == "" then
		castBar.name:SetFormattedText("%s", spell)
	else
		castBar.name:SetFormattedText("%s --> %s", spell, self.target)
	end

	castBar:Show()
end

function addon:UNIT_SPELLCAST_CHANNEL_STOP(unit, spellname, spellRank)
	if UnitName("target") ~= UnitName(unit) then return end

	if self.channeling then
		self.channeling = false
		self.target = nil
		self.stopTime = GetTime()
		castBar:SetValue(0)
	end
end

function addon:UNIT_SPELLCAST_CHANNEL_UPDATE(unit, spellName, spellRank)
	if UnitName("target") ~= UnitName(unit) then return end

	local spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
	startTime = startTime/1000
	endTime = endTime/1000
	self.channeling = true
	self.startTime = startTime
	self.endTime = endTime
end

function addon:UNIT_SPELLCAST_FAIED(unit)
	if UnitName("target") ~= UnitName(unit) then return end
	self:UNIT_SPELLCAST_STOP(unit)
	castBar:SetStatusBarColor(1, 0, 0)
end

function addon:UNIT_SPELLCAST_INTERUPTED(unit)
	if UnitName("target") ~= UnitName(unit) then return end
	self:UNIT_SPELLCAST_STOP(unit)
	castBar:SetStatusBarColor(1, 0, 0)
end

function addon:ADDON_LOADED(arg1)
	if arg1 == "ZarielCastingBar" then
		self:UnregisterEvent("ADDON_LOADED")
		return self:OnEnable()
	end
end

addon:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, ...)
	end
end)

addon:RegisterEvent("ADDON_LOADED")

