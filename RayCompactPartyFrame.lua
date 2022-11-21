function RayCompactPartyFrame_OnLoad(self)
	self.applyFunc = RayCompactRaidGroup_ApplyFunctionToAllFrames;
	self.isParty = true;

	for i=1, MEMBERS_PER_RAID_GROUP do
		local unitFrame = _G["RayCompactPartyFrameMember"..i];
		unitFrame.isParty = true;
	end
	
	RayCompactPartyFrame_RefreshMembers();
	
	--self.title:SetText(PARTY);
	--self.title:Disable();
end

function RayCompactPartyFrame_UpdateVisibility()
	if not RayCompactPartyFrame then
		return;
	end
	
	local isInArena = IsActiveBattlefieldArena();
	local groupFramesShown = (IsInGroup() and (isInArena or not IsInRaid())) or EditModeManagerFrame:ArePartyFramesForcedShown();
	local showRayCompactPartyFrame = groupFramesShown and true;
	RayCompactPartyFrame:SetShown(showRayCompactPartyFrame);
	RayPartyFrame:UpdatePaddingAndLayout();
end

function RayCompactPartyFrame_RefreshMembers()
	if not RayCompactPartyFrame then
		return;
	end

	local units = {};

	if IsInRaid() then
		for i=1, MEMBERS_PER_RAID_GROUP do
			table.insert(units, "raid"..i);
		end
	else
		-- table.insert(units, "player");

		for i=2, MEMBERS_PER_RAID_GROUP do
			table.insert(units, "party"..(i-1));
		end
	end

	table.sort(units, RayCompactPartyFrame.flowSortFunc);

	for index, realPartyMemberToken in ipairs(units) do
		local unitFrame = _G["RayCompactPartyFrameMember"..index];

		-- local usePlayerOverride = EditModeManagerFrame:ArePartyFramesForcedShown() and not UnitExists(realPartyMemberToken);
		local usePlayerOverride = false;
		--local unitToken = usePlayerOverride and "player" or realPartyMemberToken;
		local unitToken = realPartyMemberToken;

		RayCompactUnitFrame_SetUnit(unitFrame, unitToken);
		local setupOptions = {
			width = 200,
			height = 60
		}
		local frameOptions = {
			displayPowerBar = function (frame)
				return UnitGroupRolesAssigned(frame.unit) ~= "DAMAGER";
			end
		}
		RayCompactUnitFrame_SetUpFrame(unitFrame, DefaultRayCompactUnitFrameSetup, setupOptions, frameOptions);
		RayCompactUnitFrame_SetUpdateAllEvent(unitFrame, "GROUP_ROSTER_UPDATE");
	end

	RayCompactRaidGroup_UpdateBorder(RayCompactPartyFrame);
	RayPartyFrame:UpdatePaddingAndLayout();
end

function RayCompactPartyFrame_SetFlowSortFunction(flowSortFunc)
	if not RayCompactPartyFrame then
		return;
	end
	RayCompactPartyFrame.flowSortFunc = flowSortFunc;
	RayCompactPartyFrame_RefreshMembers();
end

function RayCompactPartyFrame_Generate()
	local frame = RayCompactPartyFrame;
	local didCreate = false;
	if not frame then
		frame = CreateFrame("Frame", "RayCompactPartyFrame", RayPartyFrame, "RayCompactPartyFrameTemplate");
		frame.flowSortFunc = CRFSort_Role;
		RayCompactRaidGroup_UpdateBorder(frame);
		RayPartyFrame:UpdatePaddingAndLayout();
		frame:RegisterEvent("GROUP_ROSTER_UPDATE");
		didCreate = true;
	end
	return frame, didCreate;
end
