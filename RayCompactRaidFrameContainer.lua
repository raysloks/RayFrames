local frameCreationSpecifiers = {
	raid = { mapping = UnitGUID, setUpFunc = DefaultRayCompactUnitFrameSetup, updateList = "normal"},
	raidFake = { setUpFunc = DefaultRayCompactUnitFrameSetup, updateList = "normal"},
	pet =  { setUpFunc = DefaultRayCompactMiniFrameSetup, updateList = "mini" },
	flagged = { mapping = UnitGUID, setUpFunc = DefaultRayCompactUnitFrameSetup, updateList = "normal"	},
	target = { setUpFunc = DefaultRayCompactMiniFrameSetup, updateList = "mini" },
}

--Widget Handlers
RayCompactRaidFrameContainerMixin = {};

function RayCompactRaidFrameContainerMixin:OnLoad()
	FlowContainer_Initialize(self);	--Congrats! We are now a certified FlowContainer.

	FlowContainer_SetOrientation(self, "vertical");
	FlowContainer_SetHorizontalSpacing(self, 8);
	FlowContainer_SetVerticalSpacing(self, 8);
	
	self:SetClampRectInsets(0, 200 - self:GetWidth(), 10, 0);
	
	self.units = {--[["raid1", "raid2", "raid3", ..., "raid40"]]};
	for i=1, MAX_RAID_MEMBERS do
		tinsert(self.units, "raid"..i);
	end
	
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("UNIT_PET");
	
	local unitFrameReleaseFunc = function(frame) RayCompactUnitFrame_SetUnit(frame, nil); end;
	self.frameReservations = {
		raid     = RayCompactRaidFrameReservation_NewManager(unitFrameReleaseFunc);
		raidFake = RayCompactRaidFrameReservation_NewManager(unitFrameReleaseFunc);
		pet      = RayCompactRaidFrameReservation_NewManager(unitFrameReleaseFunc);
		flagged  = RayCompactRaidFrameReservation_NewManager(unitFrameReleaseFunc); --For Main Tank/Assist units
		target   = RayCompactRaidFrameReservation_NewManager(unitFrameReleaseFunc); --Target of target for Main Tank/Main Assist
	}
	
	self.frameUpdateList = {
		normal = {},	--Groups are also in this normal list.
		mini = {},
		group = {},
	}

	self.unitFrameUnusedFunc = function(frame) frame.inUse = false;	end;
												
	self.displayPets = false;
	self.displayFlaggedMembers = true;

	self.groupMode = "discrete";
	self.groupFilterFunc = function () return true; end

	self:AddGroup("PARTY");
end

function RayCompactRaidFrameContainerMixin:OnEvent(event, ...)
	if event == "GROUP_ROSTER_UPDATE" then
		self:TryUpdate();
	elseif event == "UNIT_PET" then
		if self.displayPets then
			local unit = ...;
			if unit == "player" or strsub(unit, 1, 4) == "raid" or strsub(unit, 1, 5) == "party" then
				self:TryUpdate();
			end
		end
	end
end

function RayCompactRaidFrameContainerMixin:OnSizeChanged()
	self:UpdateBorder();
end

--Externally used functions
function RayCompactRaidFrameContainerMixin:SetGroupMode(groupMode)
	self.groupMode = groupMode;
	self:TryUpdate();
end

function RayCompactRaidFrameContainerMixin:GetGroupMode()
	return self.groupMode;
end

function RayCompactRaidFrameContainerMixin:SetFlowFilterFunction(flowFilterFunc)
	--Usage: flowFilterFunc is called as flowFilterFunc("unittoken") and should return whether this frame should be displayed or not.
	self.flowFilterFunc = flowFilterFunc;
	self:TryUpdate();
end

function RayCompactRaidFrameContainerMixin:SetGroupFilterFunction(groupFilterFunc)
	--Usage: groupFilterFunc is called as groupFilterFunc(groupNum) and should return whether this group should be displayed or not.
	self.groupFilterFunc = groupFilterFunc;
	self:TryUpdate();
end

function RayCompactRaidFrameContainerMixin:SetFlowSortFunction(flowSortFunc)
	--Usage: Takes two tokens, should work as a Lua sort function.
	--The ordering must be well-defined, even across units that will be filtered out
	self.flowSortFunc = flowSortFunc;
	self:TryUpdate();
end

function RayCompactRaidFrameContainerMixin:SetDisplayPets(displayPets)
	if self.displayPets ~= displayPets then
		self.displayPets = displayPets;
		self:TryUpdate();
	end
end

function RayCompactRaidFrameContainerMixin:SetDisplayMainTankAndAssist(displayFlaggedMembers)
	if self.displayFlaggedMembers ~= displayFlaggedMembers then
		self.displayFlaggedMembers = displayFlaggedMembers;
		self:TryUpdate();
	end
end

function RayCompactRaidFrameContainerMixin:SetBorderShown(showBorder)
	self.showBorder = showBorder;
	self:UpdateBorder();
end

function RayCompactRaidFrameContainerMixin:ApplyToFrames(updateSpecifier, func, ...)
	for specifier, list in pairs(self.frameUpdateList) do
		if updateSpecifier == "all" or specifier == updateSpecifier then
			for i=1, #list do
				list[i]:applyFunc(updateSpecifier, func, ...);
			end
		end
	end
end

--Internally used functions
function RayCompactRaidFrameContainerMixin:TryUpdate()
	if self:ReadyToUpdate() then
		self:LayoutFrames();
	end
end

function RayCompactRaidFrameContainerMixin:ReadyToUpdate()
	local groupMode = self:GetGroupMode();
	if not groupMode then
		return false;
	end
	if groupMode == "flush" and not (self.flowFilterFunc and self.flowSortFunc) then
		return false;
	end
	if groupMode == "discrete" and not self.groupFilterFunc then
		return false;
	end
	
	return true;
end

function RayCompactRaidFrameContainerMixin:LayoutFrames()
	--First, mark everything we currently use as unused. We'll hide all the ones that are still unused at the end of this function. (On release)
	for i=1, #self.flowFrames do
		if type(self.flowFrames[i]) == "table" and self.flowFrames[i].unusedFunc then
			self.flowFrames[i]:unusedFunc();
		end
	end
	FlowContainer_RemoveAllObjects(self);
	
	FlowContainer_PauseUpdates(self);	--We don't want to update it every time we add an item.
	
	if self.displayFlaggedMembers then
		self:AddFlaggedUnits();
		FlowContainer_AddLineBreak(self);
	end
	
	if self:GetGroupMode() == "discrete" then
		self:AddGroups();
	else
		self:AddPlayers();
	end
	
	if self.displayPets then
		self:AddPets();
	end
	
	self:SetSize(3000, 3000);
	FlowContainer_ResumeUpdates(self);
	self:Layout();
	
	self:UpdateBorder();
	self:ReleaseAllReservedFrames();
end

function RayCompactRaidFrameContainerMixin:UpdateBorder()
	local usedX, usedY = FlowContainer_GetUsedBounds(self);
	if self.showBorder and self:GetGroupMode() ~= "discrete" and usedX > 0 and usedY > 0 then
		self.borderFrame:SetSize(usedX + 11, usedY + 13);
		self.borderFrame:Show();
	else
		self.borderFrame:Hide();
	end
end

local usedGroups = {}; --Enclosure to make sure usedGroups isn't used anywhere else.
function RayCompactRaidFrameContainerMixin:AddGroups()
	RayRaidUtil_GetUsedGroups(usedGroups);
			
	for groupNum, isUsed in ipairs(usedGroups) do
		if isUsed and self.groupFilterFunc(groupNum) then
			self:AddGroup(groupNum);
		end
	end
	FlowContainer_DoLayout(self);
end

function RayCompactRaidFrameContainerMixin:AddGroup(id)
	local groupFrame, didCreation;
	if type(id) == "number" then
		groupFrame, didCreation = RayCompactRaidGroup_GenerateForGroup(id);
	elseif id == "PARTY" then
		groupFrame, didCreation = RayCompactPartyFrame_Generate();
	else
		GMError("Unknown id");
	end
	
	groupFrame.unusedFunc = groupFrame.Hide;
	if didCreation then
		tinsert(self.frameUpdateList.normal, groupFrame);
		tinsert(self.frameUpdateList.group, groupFrame);
	end

	if id == "PARTY" then
		RayCompactPartyFrame_UpdateVisibility();
		RayCompactPartyFrame_RefreshMembers();
	else
		if didCreation then
			groupFrame:SetParent(self);
		end
		groupFrame:Show();
		FlowContainer_AddObject(self, groupFrame);
	end
end

function RayCompactRaidFrameContainerMixin:AddPlayers()
	--First, sort the players we're going to use
	assert(self.flowSortFunc);		--No sort function defined! Call SetFlowSortFunction.
	assert(self.flowFilterFunc);	--No filter function defined! Call SetFlowFilterFunction.
	
	table.sort(self.units, self.flowSortFunc);
	
	local numForcedMembersShown = EditModeManagerFrame:GetNumRaidMembersForcedShown();

	for i=1, #self.units do
		local unit = self.units[i];
		if self.flowFilterFunc(unit) then
			self:AddUnitFrame(unit, "raid");
		elseif i <= numForcedMembersShown then
			local partyToken = "party"..(i - 1);
			local unitToken = UnitExists(partyToken) and partyToken or "player";
			self:AddUnitFrame(unit, "raidFake", unitToken);
		end
	end
end

function RayCompactRaidFrameContainerMixin:AddPets()
	if IsInRaid() then
		for i=1, MAX_RAID_MEMBERS do
			local unit = "raidpet"..i;
			if UnitExists(unit) then
				self:AddUnitFrame(unit, "pet");
			end
		end
	else
		--Add the player's pet.
		if UnitExists("pet") then
			self:AddUnitFrame("pet", "pet");
		end
		for i=1, GetNumSubgroupMembers() do
			local unit = "partypet"..i;
			if UnitExists(unit) then
				self:AddUnitFrame(unit, "pet");
			end
		end
	end
end

local flaggedRoles = { "MAINTANK", "MAINASSIST" };
function RayCompactRaidFrameContainerMixin:AddFlaggedUnits()
	if not IsInRaid() then
		return;
	end
	for roleIndex = 1, #flaggedRoles do
		local desiredRole = flaggedRoles[roleIndex]
		for i=1, MAX_RAID_MEMBERS do
			local unit = "raid"..i;
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			if role == desiredRole then
				FlowContainer_BeginAtomicAdd(self);	--We want each unit to be right next to its target and target of target.
				
				self:AddUnitFrame(unit, "flagged");
				
				--If we want to display the tank/assist target...
				local targetFrame = self:AddUnitFrame(unit.."target", "target");
				RayCompactUnitFrame_SetUpdateAllOnUpdate(targetFrame, true);
				
				--Target of target?
				local targetOfTargetFrame = self:AddUnitFrame(unit.."targettarget", "target");
				RayCompactUnitFrame_SetUpdateAllOnUpdate(targetOfTargetFrame, true);
				
				FlowContainer_EndAtomicAdd(self);
			end
		end
	end		
end

--Utility Functions
function RayCompactRaidFrameContainerMixin:AddUnitFrame(unit, frameType, overrideUnit)
	local frame = self:GetUnitFrame(unit, frameType);
	RayCompactUnitFrame_SetUnit(frame, overrideUnit or unit);
	FlowContainer_AddObject(self, frame);
	return frame;
end

local function applyFunc(unitFrame, updateSpecifier, func, ...)
	func(unitFrame, ...);
end

local unitFramesCreated = 0;
function RayCompactRaidFrameContainerMixin:GetUnitFrame(unit, frameType)
	local info = frameCreationSpecifiers[frameType];
	assert(info);
	assert(info.setUpFunc);
	
	--Get the mapping for re-using frames
	local mapping;
	if ( info.mapping ) then
		mapping = info.mapping(unit);
	else
		mapping = unit;
	end
	
	local frame = RayCompactRaidFrameReservation_GetFrame(self.frameReservations[frameType], mapping);
	if ( not frame ) then
		unitFramesCreated = unitFramesCreated + 1;
		frame = CreateFrame("Button", "RayCompactRaidFrame"..unitFramesCreated, self, "RayCompactUnitFrameTemplate");
		frame.applyFunc = applyFunc;
		RayCompactUnitFrame_SetUpFrame(frame, info.setUpFunc);
		RayCompactUnitFrame_SetUpdateAllEvent(frame, "GROUP_ROSTER_UPDATE");
		frame.unusedFunc = self.unitFrameUnusedFunc;
		tinsert(self.frameUpdateList[info.updateList], frame);
		RayCompactRaidFrameReservation_RegisterReservation(self.frameReservations[frameType], frame, mapping);
	end
	frame.inUse = true;
	return frame;
end

function RayCompactRaidFrameContainerMixin:ReleaseAllReservedFrames()
	for key, reservations in pairs(self.frameReservations) do
		RayCompactRaidFrameReservation_ReleaseUnusedReservations(reservations);
	end
end

function RayRaidUtil_GetUsedGroups(tab)	--Fills out the table with which groups have people.
	for i=1, MAX_RAID_GROUPS do
		tab[i] = false;
	end
	if ShouldShowRaidFrames() then
		for i=1, GetNumGroupMembers() do
			local name, rank, subgroup = GetRaidRosterInfo(i);
			tab[subgroup] = true;
		end

		local numForcedGroupsShown = EditModeManagerFrame:GetNumRaidGroupsForcedShown();
		for i=1, numForcedGroupsShown do
			tab[i] = true;
		end
	end
	return tab;
end
