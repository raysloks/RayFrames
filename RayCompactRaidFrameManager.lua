function RayCompactRaidFrameManager_OnLoad(self)
	self.container = RayCompactRaidFrameContainer;
	self.container:SetParent(self);

	RayCompactRaidFrameManager_SetSetting("IsShown", 1);

	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:RegisterEvent("UI_SCALE_CHANGED");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("UPDATE_ACTIVE_BATTLEFIELD");
	self:RegisterEvent("UNIT_FLAGS");
	self:RegisterEvent("PLAYER_FLAGS_CHANGED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PARTY_LEADER_CHANGED");
	self:RegisterEvent("RAID_TARGET_UPDATE");
	self:RegisterEvent("PLAYER_TARGET_CHANGED");

	self.container:SetFlowFilterFunction(RayCRFFlowFilterFunc);
	self.container:SetGroupFilterFunction(RayCRFGroupFilterFunc);
	RayCompactRaidFrameManager_UpdateContainerBounds();

	RayCompactRaidFrameManager_Collapse();

	--Set up the options flow container
	FlowContainer_Initialize(self.displayFrame.optionsFlowContainer);
end

function RayCompactRaidFrameManager_OnEvent(self, event, ...)
	if ( event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" ) then
		RayCompactRaidFrameManager_UpdateContainerBounds();
	elseif ( event == "GROUP_ROSTER_UPDATE" or event == "UPDATE_ACTIVE_BATTLEFIELD" ) then
		RayCompactRaidFrameManager_UpdateShown();
		RayCompactRaidFrameManager_UpdateDisplayCounts();
		RayCompactRaidFrameManager_UpdateLabel();
	elseif ( event == "UNIT_FLAGS" or event == "PLAYER_FLAGS_CHANGED" ) then
		RayCompactRaidFrameManager_UpdateDisplayCounts();
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		RayCompactRaidFrameManager_UpdateShown();
		RayCompactRaidFrameManager_UpdateDisplayCounts();
		RayCompactRaidFrameManager_UpdateOptionsFlowContainer();
		RayCompactRaidFrameManager_UpdateRaidIcons();
	elseif ( event == "PARTY_LEADER_CHANGED" ) then
		RayCompactRaidFrameManager_UpdateOptionsFlowContainer();
	elseif ( event == "RAID_TARGET_UPDATE" ) then
		RayCompactRaidFrameManager_UpdateRaidIcons();
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		RayCompactRaidFrameManager_UpdateRaidIcons();
	end
end

function RayCompactRaidFrameManager_UpdateShown()
	if ShouldShowRaidFrames() then
		RayCompactRaidFrameManager:Show();
	else
		RayCompactRaidFrameManager:Hide();
	end
	RayCompactRaidFrameManager_UpdateOptionsFlowContainer();
	RayCompactRaidFrameManager_UpdateContainerVisibility();
end

function RayCompactRaidFrameManager_UpdateLabel()
	if ( IsInRaid() ) then
		RayCompactRaidFrameManager.displayFrame.label:SetText(RAID_MEMBERS);
	else
		RayCompactRaidFrameManager.displayFrame.label:SetText(PARTY_MEMBERS);
	end
end

function RayCompactRaidFrameManager_Toggle()
	if ( RayCompactRaidFrameManager.collapsed ) then
		RayCompactRaidFrameManager_Expand();
	else
		RayCompactRaidFrameManager_Collapse();
	end
end

function RayCompactRaidFrameManager_Expand()
	RayCompactRaidFrameManager.collapsed = false;
	RayCompactRaidFrameManager:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -7, -140);
	RayCompactRaidFrameManager.displayFrame:Show();
	RayCompactRaidFrameManager.toggleButton:GetNormalTexture():SetTexCoord(0.5, 1, 0, 1);
end

function RayCompactRaidFrameManager_Collapse()
	RayCompactRaidFrameManager.collapsed = true;
	RayCompactRaidFrameManager:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -182, -140);
	RayCompactRaidFrameManager.displayFrame:Hide();
	RayCompactRaidFrameManager.toggleButton:GetNormalTexture():SetTexCoord(0, 0.5, 0, 1);
end

function RayCompactRaidFrameManager_UpdateOptionsFlowContainer()
	local container = RayCompactRaidFrameManager.displayFrame.optionsFlowContainer;

	FlowContainer_RemoveAllObjects(container);
	FlowContainer_PauseUpdates(container);

	if ( IsInRaid() ) then
		FlowContainer_AddObject(container, RayCompactRaidFrameManager.displayFrame.filterOptions);
		RayCompactRaidFrameManager.displayFrame.filterOptions:Show();
	else
		RayCompactRaidFrameManager.displayFrame.filterOptions:Hide();
	end

	if ( not IsInRaid() or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") ) then
		FlowContainer_AddObject(container, RayCompactRaidFrameManager.displayFrame.raidMarkers);
		RayCompactRaidFrameManager.displayFrame.raidMarkers:Show();
	else
		RayCompactRaidFrameManager.displayFrame.raidMarkers:Hide();
	end

	if ( not IsInRaid() or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") ) then
		FlowContainer_AddObject(container, RayCompactRaidFrameManager.displayFrame.leaderOptions);
		RayCompactRaidFrameManager.displayFrame.leaderOptions:Show();
	else
		RayCompactRaidFrameManager.displayFrame.leaderOptions:Hide();
	end

	if ( not IsInRaid() and UnitIsGroupLeader("player") and not HasLFGRestrictions() ) then
		FlowContainer_AddLineBreak(container);
		FlowContainer_AddSpacer(container, 20);
		FlowContainer_AddObject(container, RayCompactRaidFrameManager.displayFrame.convertToRaid);
		RayCompactRaidFrameManager.displayFrame.convertToRaid:Show();
	else
		RayCompactRaidFrameManager.displayFrame.convertToRaid:Hide();
	end

	if ShouldShowRaidFrames() then
		FlowContainer_AddLineBreak(container);
		FlowContainer_AddSpacer(container, 20);
		FlowContainer_AddObject(container, RayCompactRaidFrameManager.displayFrame.editMode);
		FlowContainer_AddObject(container, RayCompactRaidFrameManager.displayFrame.hiddenModeToggle);
		RayCompactRaidFrameManager.displayFrame.editMode:Show();
		RayCompactRaidFrameManager.displayFrame.hiddenModeToggle:Show();
	else
		FlowContainer_AddLineBreak(container);
		FlowContainer_AddSpacer(container, 20);
		FlowContainer_AddObject(container, RayCompactRaidFrameManager.displayFrame.editMode);
		RayCompactRaidFrameManager.displayFrame.editMode:Show();
		RayCompactRaidFrameManager.displayFrame.hiddenModeToggle:Hide();
	end

	if ( IsInRaid() and UnitIsGroupLeader("player") ) then
		FlowContainer_AddLineBreak(container);
		FlowContainer_AddSpacer(container, 20);
		FlowContainer_AddObject(container, RayCompactRaidFrameManager.displayFrame.everyoneIsAssistButton);
		RayCompactRaidFrameManager.displayFrame.everyoneIsAssistButton:Show();
	else
		RayCompactRaidFrameManager.displayFrame.everyoneIsAssistButton:Hide();
	end

	FlowContainer_ResumeUpdates(container);

	local usedX, usedY = FlowContainer_GetUsedBounds(container);
	RayCompactRaidFrameManager:SetHeight(usedY + 40);

	--Then, we update which specific buttons are enabled.

	--Raid leaders and assistants and leaders of non-dungeon finder parties may initiate a role poll.
	if ( IsInGroup() and not HasLFGRestrictions() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) ) then
		RayCompactRaidFrameManager.displayFrame.leaderOptions.rolePollButton:Enable();
		RayCompactRaidFrameManager.displayFrame.leaderOptions.rolePollButton:SetAlpha(1);
	else
		RayCompactRaidFrameManager.displayFrame.leaderOptions.rolePollButton:Disable();
		RayCompactRaidFrameManager.displayFrame.leaderOptions.rolePollButton:SetAlpha(0.5);
	end

	--Any sort of leader may initiate a ready check.
	if ( IsInGroup() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) ) then
		RayCompactRaidFrameManager.displayFrame.leaderOptions.readyCheckButton:Enable();
		RayCompactRaidFrameManager.displayFrame.leaderOptions.readyCheckButton:SetAlpha(1);
		RayCompactRaidFrameManager.displayFrame.leaderOptions.countdownButton:Enable();
		RayCompactRaidFrameManager.displayFrame.leaderOptions.countdownButton:SetAlpha(1);
	else
		RayCompactRaidFrameManager.displayFrame.leaderOptions.readyCheckButton:Disable();
		RayCompactRaidFrameManager.displayFrame.leaderOptions.readyCheckButton:SetAlpha(0.5);
		RayCompactRaidFrameManager.displayFrame.leaderOptions.countdownButton:Disable();
		RayCompactRaidFrameManager.displayFrame.leaderOptions.countdownButton:SetAlpha(0.5);
	end
end

local function RaidWorldMarker_OnClick(self, arg1, arg2, checked)
	if ( checked ) then
		ClearRaidMarker(arg1);
	else
		PlaceRaidMarker(arg1);
	end
end

local function ClearRaidWorldMarker_OnClick(self, arg1, arg2, checked)
	ClearRaidMarker();
end

function RayCRFManager_RaidWorldMarkerDropDown_Update()
	local info = UIDropDownMenu_CreateInfo();

	info.isNotRadio = true;

	for i=1, NUM_WORLD_RAID_MARKERS do
		local index = WORLD_RAID_MARKER_ORDER[i];
		info.text = _G["WORLD_MARKER"..index];
		info.func = RaidWorldMarker_OnClick;
		info.checked = IsRaidMarkerActive(index);
		info.arg1 = index;
		UIDropDownMenu_AddButton(info);
	end


	info.notCheckable = 1;
	info.text = REMOVE_WORLD_MARKERS;
	info.func = ClearRaidWorldMarker_OnClick;
	info.arg1 = nil;	--Remove everything
	UIDropDownMenu_AddButton(info);
end

function RayCompactRaidFrameManager_UpdateDisplayCounts()
	RayCRF_CountStuff();
	RayCompactRaidFrameManager_UpdateHeaderInfo();
	RayCompactRaidFrameManager_UpdateFilterInfo()
end

function RayCompactRaidFrameManager_UpdateHeaderInfo()
	RayCompactRaidFrameManager.displayFrame.memberCountLabel:SetFormattedText("%d/%d", RayRaidInfoCounts.totalAlive, RayRaidInfoCounts.totalCount);
end

local usedGroups = {};
function RayCompactRaidFrameManager_UpdateFilterInfo()
	RayCompactRaidFrameManager_UpdateRoleFilterButton(RayCompactRaidFrameManager.displayFrame.filterOptions.filterRoleTank);
	RayCompactRaidFrameManager_UpdateRoleFilterButton(RayCompactRaidFrameManager.displayFrame.filterOptions.filterRoleHealer);
	RayCompactRaidFrameManager_UpdateRoleFilterButton(RayCompactRaidFrameManager.displayFrame.filterOptions.filterRoleDamager);

	RayRaidUtil_GetUsedGroups(usedGroups);
	for i=1, MAX_RAID_GROUPS do
		RayCompactRaidFrameManager_UpdateGroupFilterButton(RayCompactRaidFrameManager.displayFrame.filterOptions["filterGroup"..i], usedGroups);
	end
end

function RayCompactRaidFrameManager_UpdateRoleFilterButton(button)
	local totalAlive, totalCount = RayRaidInfoCounts["aliveRole"..button.role], RayRaidInfoCounts["totalRole"..button.role]
	button:SetFormattedText("%s %d/%d", button.roleTexture, totalAlive, totalCount);
	local showSeparateGroups = EditModeManagerFrame:ShouldRaidFrameShowSeparateGroups();
	if ( totalCount == 0 or showSeparateGroups ) then
		button.selectedHighlight:Hide();
		button:Disable();
		button:SetAlpha(0.5);
	else
		button:Enable();
		button:SetAlpha(1);
		local isFiltered = RayCRF_GetFilterRole(button.role)
		if ( isFiltered ) then
			button.selectedHighlight:Show();
		else
			button.selectedHighlight:Hide();
		end
	end
end

function RayCompactRaidFrameManager_ToggleRoleFilter(role)
	RayCRF_SetFilterRole(role, not RayCRF_GetFilterRole(role));
	RayCompactRaidFrameManager_UpdateFilterInfo();
	RayCompactRaidFrameContainer:TryUpdate();
end

function RayCompactRaidFrameManager_UpdateGroupFilterButton(button, usedGroups)
	local group = button:GetID();
	if ( usedGroups[group] ) then
		button:Enable();
		button:SetAlpha(1);
		local isFiltered = RayCRF_GetFilterGroup(group);
		if ( isFiltered ) then
			button.selectedHighlight:Show();
		else
			button.selectedHighlight:Hide();
		end
	else
		button.selectedHighlight:Hide();
		button:Disable();
		button:SetAlpha(0.5);
	end
end

function RayCompactRaidFrameManager_ToggleGroupFilter(group)
	RayCRF_SetFilterGroup(group, not RayCRF_GetFilterGroup(group));
	RayCompactRaidFrameManager_UpdateFilterInfo();
	RayCompactRaidFrameContainer:TryUpdate();
end

function RayCompactRaidFrameManager_UpdateRaidIcons()
	local unit = "target";
	local disableAll = not CanBeRaidTarget(unit);
	for i=1, NUM_RAID_ICONS do
		local button = _G["RayCompactRaidFrameManagerDisplayFrameRaidMarkersRaidMarker"..i];	--.... /cry
		if ( disableAll or button:GetID() == GetRaidTargetIndex(unit) ) then
			button:GetNormalTexture():SetDesaturated(true);
			button:SetAlpha(0.7);
			button:Disable();
		else
			button:GetNormalTexture():SetDesaturated(false);
			button:SetAlpha(1);
			button:Enable();
		end
	end

	local removeButton = RayCompactRaidFrameManagerDisplayFrameRaidMarkersRaidMarkerRemove;
	if ( not GetRaidTargetIndex(unit) ) then
		removeButton:GetNormalTexture():SetDesaturated(true);
		removeButton:Disable();
	else
		removeButton:GetNormalTexture():SetDesaturated(false);
		removeButton:Enable();
	end
end


--Settings stuff
local cachedSettings = {};
local isSettingCached = {};
function RayCompactRaidFrameManager_GetSetting(settingName)
	if ( not isSettingCached[settingName] ) then
		cachedSettings[settingName] = RayCompactRaidFrameManager_GetSettingBeforeLoad(settingName);
		isSettingCached[settingName] = true;
	end
	return cachedSettings[settingName];
end

function RayCompactRaidFrameManager_GetSettingBeforeLoad(settingName)
	if ( settingName == "Managed" ) then
		return true;
	elseif ( settingName == "Locked" ) then
		return true;
	elseif ( settingName == "DisplayPets" ) then
		return false;
	elseif ( settingName == "DisplayMainTankAndAssist" ) then
		return true;
	elseif ( settingName == "IsShown" ) then
		return true;
	else
		GMError("Unknown setting "..tostring(settingName));
	end
end

do	--Enclosure to make sure people go through SetSetting
	local function RayCompactRaidFrameManager_SetManaged(value)
		local container = RayCompactRaidFrameManager.container;
	end

	local function RayCompactRaidFrameManager_SetDisplayPets(value)
		local container = RayCompactRaidFrameManager.container;
		local displayPets;
		if ( value and value ~= "0" ) then
			displayPets = true;
		end

		container:SetDisplayPets(displayPets);
	end

	local function RayCompactRaidFrameManager_SetDisplayMainTankAndAssist(value)
		local container = RayCompactRaidFrameManager.container;
		local displayFlaggedMembers;
		if value and value ~= "0" then
			displayFlaggedMembers = true;
		end

		container:SetDisplayMainTankAndAssist(displayFlaggedMembers);
	end

	local function RayCompactRaidFrameManager_SetIsShown(value)
		if value and value ~= "0" then
			RayCompactRaidFrameManager.container.enabled = true;
			RayCompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetText(HIDE);
			RayCompactRaidFrameManagerDisplayFrameHiddenModeToggle.shownMode = false;
		else
			RayCompactRaidFrameManager.container.enabled = false;
			RayCompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetText(SHOW);
			RayCompactRaidFrameManagerDisplayFrameHiddenModeToggle.shownMode = true;
		end
		RayCompactRaidFrameManager_UpdateContainerVisibility();
	end

	function RayCompactRaidFrameManager_SetSetting(settingName, value)
		cachedSettings[settingName] = value;
		isSettingCached[settingName] = true;

		--Perform the actual functions
		if ( settingName == "Managed" ) then
			RayCompactRaidFrameManager_SetManaged(value);
		elseif ( settingName == "DisplayPets" ) then
			RayCompactRaidFrameManager_SetDisplayPets(value);
		elseif ( settingName == "DisplayMainTankAndAssist" ) then
			RayCompactRaidFrameManager_SetDisplayMainTankAndAssist(value);
		elseif ( settingName == "IsShown" ) then
			RayCompactRaidFrameManager_SetIsShown(value);
		else
			GMError("Unknown setting "..tostring(settingName));
		end
	end
end

function RayCompactRaidFrameManager_UpdateContainerVisibility()
	if ShouldShowRaidFrames() and RayCompactRaidFrameManager.container.enabled then
		RayCompactRaidFrameManager.container:Show();
	else
		RayCompactRaidFrameManager.container:Hide();
	end

	RayCompactPartyFrame_UpdateVisibility();
end

function RayCompactRaidFrameManager_UpdateContainerBounds()
	RayCompactRaidFrameManager.container:Layout();
end

-------------Utility functions-------------
--Functions used for sorting and such
function RayCRFSort_Group(token1, token2)
	if ( IsInRaid() ) then
		local id1 = tonumber(string.sub(token1, 5));
		local id2 = tonumber(string.sub(token2, 5));

		if ( not id1 or not id2 ) then
			return id1;
		end

		local _, _, subgroup1 = GetRaidRosterInfo(id1);
		local _, _, subgroup2 = GetRaidRosterInfo(id2);

		if ( subgroup1 and subgroup2 and subgroup1 ~= subgroup2 ) then
			return subgroup1 < subgroup2;
		end

		--Fallthrough: Sort by order in Raid window.
		return id1 < id2;
	else
		if ( token1 == "player" ) then
			return true;
		elseif ( token2 == "player" ) then
			return false;
		else
			return token1 < token2;	--String compare is OK since we don't go above 1 digit for party.
		end
	end
end

local roleValues = { MAINTANK = 1, MAINASSIST = 2, TANK = 3, HEALER = 4, DAMAGER = 5, NONE = 6 };
function RayCRFSort_Role(token1, token2)
	local id1, id2 = UnitInRaid(token1), UnitInRaid(token2);
	local role1, role2;
	if ( id1 ) then
		role1 = select(10, GetRaidRosterInfo(id1));
	end
	if ( id2 ) then
		role2 = select(10, GetRaidRosterInfo(id2));
	end

	role1 = role1 or UnitGroupRolesAssigned(token1);
	role2 = role2 or UnitGroupRolesAssigned(token2);

	local value1, value2 = roleValues[role1], roleValues[role2];
	if ( value1 ~= value2 ) then
		return value1 < value2;
	end

	--Fallthrough: Sort alphabetically.
	return RayCRFSort_Alphabetical(token1, token2);
end

function RayCRFSort_Alphabetical(token1, token2)
	local name1, name2 = UnitName(token1), UnitName(token2);
	if ( name1 and name2 ) then
		return name1 < name2;
	elseif ( name1 or name2 ) then
		return name1;
	end

	--Fallthrough: Alphabetic order of tokens (just here to make comparisons well-ordered)
	return token1 < token2;
end

--Functions used for filtering
local filterOptions = {
	[1] = true,
	[2] = true,
	[3] = true,
	[4] = true,
	[5] = true,
	[6] = true,
	[7] = true,
	[8] = true,
	displayRoleNONE = true;
	displayRoleTANK = true;
	displayRoleHEALER = true;
	displayRoleDAMAGER = true;

}
function RayCRF_SetFilterRole(role, show)
	filterOptions["displayRole"..role] = show;
end

function RayCRF_GetFilterRole(role)
	return filterOptions["displayRole"..role];
end

function RayCRF_SetFilterGroup(group, show)
	assert(type(group) == "number");
	filterOptions[group] = show;
end

function RayCRF_GetFilterGroup(group)
	assert(type(group) == "number");
	return filterOptions[group];
end

function RayCRFFlowFilterFunc(token)
	if ( not UnitExists(token) ) then
		return false;
	end

	if ( not IsInRaid() ) then	--We don't filter unless we're in a raid.
		return true;
	end

	local role = UnitGroupRolesAssigned(token);
	if ( not filterOptions["displayRole"..role] ) then
		return false;
	end

	local raidID = UnitInRaid(token);
	if ( raidID ) then
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, raidRole, isML = GetRaidRosterInfo(raidID);
		if ( not filterOptions[subgroup] ) then
			return false;
		end

		local showingMTandMA = RayCompactRaidFrameManager_GetSetting("DisplayMainTankAndAssist");
		if ( raidRole and (showingMTandMA and showingMTandMA ~= "0") ) then	--If this character is already displayed as a Main Tank/Main Assist, we don't want to show them a second time
			return false;
		end
	end

	return true;
end

function RayCRFGroupFilterFunc(groupNum)
	return filterOptions[groupNum];
end

--Counting functions
RayRaidInfoCounts = {
	aliveRoleTANK    = 0,
	totalRoleTANK    = 0,
	aliveRoleHEALER  = 0,
	totalRoleHEALER	 = 0,
	aliveRoleDAMAGER = 0,
	totalRoleDAMAGER = 0,
	aliveRoleNONE    = 0,
	totalRoleNONE    = 0,
	totalCount       = 0,
	totalAlive       = 0,
}

local function RayCRF_ResetCountedStuff()
	for key, val in pairs(RayRaidInfoCounts) do
		RayRaidInfoCounts[key] = 0;
	end
end

function RayCRF_CountStuff()
	RayCRF_ResetCountedStuff();
	if ( IsInRaid() ) then
		for i=1, GetNumGroupMembers() do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, assignedRole = GetRaidRosterInfo(i);	--Weird that we have 2 role return values, but... oh well
			if ( rank ) then
				RayCRF_AddToCount(isDead, assignedRole);
			end
		end
	else
		RayCRF_AddToCount(UnitIsDeadOrGhost("player") , UnitGroupRolesAssigned("player"));
		for i=1, GetNumSubgroupMembers() do
			local unit = "party"..i;
			RayCRF_AddToCount(UnitIsDeadOrGhost(unit), UnitGroupRolesAssigned(unit));
		end
	end
end

function RayCRF_AddToCount(isDead, assignedRole)
	RayRaidInfoCounts.totalCount = RayRaidInfoCounts.totalCount + 1;
	RayRaidInfoCounts["totalRole"..assignedRole] = RayRaidInfoCounts["totalRole"..assignedRole] + 1;
	if ( not isDead ) then
		RayRaidInfoCounts.totalAlive = RayRaidInfoCounts.totalAlive + 1;
		RayRaidInfoCounts["aliveRole"..assignedRole] = RayRaidInfoCounts["aliveRole"..assignedRole] + 1;
	end
end
