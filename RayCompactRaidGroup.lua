function RayCompactRaidGroup_OnLoad(self)
	--self.title:Disable();
	
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self.applyFunc = RayCompactRaidGroup_ApplyFunctionToAllFrames;
end

function RayCompactRaidGroup_OnEvent(self, event, ...)
	if ( event == "GROUP_ROSTER_UPDATE" ) then
		RayCompactRaidGroup_UpdateUnits(self);
	end
end

function RayCompactRaidGroup_ApplyFunctionToAllFrames(frame, updateSpecifier, func, ...)
	if ( updateSpecifier == "normal" or updateSpecifier == "all" ) then
		for i=1, MEMBERS_PER_RAID_GROUP do
			local unitFrame = _G[frame:GetName().."Member"..i];
			func(unitFrame, ...);
		end
	elseif ( updateSpecifier == "group" ) then
		func(frame, ...);
	end
end

function RayCompactRaidGroup_GenerateForGroup(groupIndex)
	local didCreate = false;
	local frame = _G["RayCompactRaidGroup"..groupIndex]
	if ( not frame ) then
		frame = CreateFrame("Frame", "RayCompactRaidGroup"..groupIndex, RayCompactRaidFrameContainer, "RayCompactRaidGroupTemplate");
		RayCompactRaidGroup_InitializeForGroup(frame, groupIndex);
		RayCompactRaidGroup_UpdateBorder(frame);
		didCreate = true;
	end
	return frame, didCreate;
end

function RayCompactRaidGroup_InitializeForGroup(frame, groupIndex)
	frame:SetID(groupIndex);
	for i=1, MEMBERS_PER_RAID_GROUP do
		local unitFrame = _G[frame:GetName().."Member"..i];
		local setupOptions = {
			width = 120,
			height = 50
		}
		local frameOptions = {
			displayPowerBar = function (frame)
				return UnitGroupRolesAssigned(frame.unit) ~= "DAMAGER";
			end
		}
		RayCompactUnitFrame_SetUpFrame(unitFrame, DefaultRayCompactUnitFrameSetup, setupOptions, frameOptions);
		RayCompactUnitFrame_SetUpdateAllEvent(unitFrame, "GROUP_ROSTER_UPDATE");
	end
	RayCompactRaidGroup_UpdateUnits(frame);
	--frame.title:SetFormattedText(GROUP_NUMBER, groupIndex);
end

function RayCompactRaidGroup_UpdateUnits(frame)
	if not frame.isParty and ShouldShowRaidFrames() then
		local groupIndex = frame:GetID();
		local frameIndex = 1;

		for i=1, GetNumGroupMembers() do
			local name, rank, subgroup = GetRaidRosterInfo(i);
			if ( subgroup == groupIndex and frameIndex <= MEMBERS_PER_RAID_GROUP ) then
				local unitToken;
				if IsInRaid() then
					unitToken = "raid"..i;
				else
					if i == 1 then
						unitToken = "player";
					else
						unitToken = "party"..(i - 1);
					end
				end

				RayCompactUnitFrame_SetUnit(_G[frame:GetName().."Member"..frameIndex], unitToken);
				frameIndex = frameIndex + 1;
			end
		end
		
		local forcedShown = EditModeManagerFrame:AreRaidFramesForcedShown();

		for i=frameIndex, MEMBERS_PER_RAID_GROUP do
			local unitToken = forcedShown and "player" or nil;
			local unitFrame = _G[frame:GetName().."Member"..i];
			RayCompactUnitFrame_SetUnit(unitFrame, unitToken);
		end
	end
end

function RayCompactRaidGroup_UpdateLayout(frame)
	--local totalHeight = frame.title:GetHeight();
	local totalHeight = 0;
	local totalWidth = 0;
	local paddingX = 4;

	-- local useHorizontalGroups = EditModeManagerFrame:ShouldRaidFrameUseHorizontalRaidGroups(frame.isParty);
	local useHorizontalGroups = true;
	if useHorizontalGroups then
		--frame.title:ClearAllPoints();
		--frame.title:SetPoint("TOPLEFT");
		
		local frame1 = _G[frame:GetName().."Member1"];
		frame1:ClearAllPoints();
		frame1:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -totalHeight);
		
		for i=2, MEMBERS_PER_RAID_GROUP do
			local unitFrame = _G[frame:GetName().."Member"..i];
			unitFrame:ClearAllPoints();
			unitFrame:SetPoint("LEFT", _G[frame:GetName().."Member"..(i-1)], "RIGHT", paddingX, 0);
		end
		totalHeight = totalHeight + _G[frame:GetName().."Member1"]:GetHeight();
		-- totalWidth = totalWidth + _G[frame:GetName().."Member1"]:GetWidth() * MEMBERS_PER_RAID_GROUP;

		for i=1, MEMBERS_PER_RAID_GROUP do
			local unitFrame = _G[frame:GetName().."Member"..i];
			if ( unitFrame:IsShown() ) then
				totalWidth = totalWidth + unitFrame:GetWidth() + paddingX;
			end
		end
		totalWidth = totalWidth - paddingX;

		if frame.borderFrame:IsShown() then
			totalWidth = totalWidth + 4;
		end
	else
		--frame.title:ClearAllPoints();
		--frame.title:SetPoint("TOP");
		
		local frame1 = _G[frame:GetName().."Member1"];
		frame1:ClearAllPoints();
		frame1:SetPoint("TOP", frame, "TOP", 0, -totalHeight);
		
		for i=2, MEMBERS_PER_RAID_GROUP do
			local unitFrame = _G[frame:GetName().."Member"..i];
			unitFrame:ClearAllPoints();
			unitFrame:SetPoint("TOP", _G[frame:GetName().."Member"..(i-1)], "BOTTOM", 0, 0);
		end
		totalHeight = totalHeight + _G[frame:GetName().."Member1"]:GetHeight() * MEMBERS_PER_RAID_GROUP;
		totalWidth = totalWidth + _G[frame:GetName().."Member1"]:GetWidth();

		if frame.borderFrame:IsShown() then
			totalWidth = totalWidth + 12;
			totalHeight = totalHeight + 2;
		end
	end
	
	frame:SetSize(totalWidth, totalHeight);
end

function RayCompactRaidGroup_UpdateBorder(frame)	
	local displayBorder = EditModeManagerFrame:ShouldRaidFrameDisplayBorder(frame.isParty);
	frame.borderFrame:SetShown(displayBorder);
	RayCompactRaidGroup_UpdateLayout(frame);
end
