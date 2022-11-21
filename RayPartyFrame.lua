RayPartyFrameMixin={};

function RayPartyFrameMixin:OnLoad()
	self.PartyMemberFramePool = CreateFramePool("BUTTON", self, "PartyMemberFrameTemplate");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
end

function RayPartyFrameMixin:OnShow()
	--self:InitializePartyMemberFrames();
	self:UpdatePartyFrames();
end

function RayPartyFrameMixin:OnEvent(event, ...)
	self:Layout();
end

function RayPartyFrameMixin:InitializePartyMemberFrames()
	local memberFramesToSetup = {};
	
	self.PartyMemberFramePool:ReleaseAll();
	for i = 1, MAX_PARTY_MEMBERS do 	
		 local memberFrame = self.PartyMemberFramePool:Acquire();
		 memberFrame:SetPoint("TOPLEFT");
		 memberFrame.layoutIndex = i;
		 memberFramesToSetup[i] = memberFrame;
		 memberFrame:Show();
	end
	self:Layout();
	for _, frame in ipairs(memberFramesToSetup) do 
		frame:Setup();
	end
end

function RayPartyFrameMixin:UpdateMemberFrames()
	for memberFrame in self.PartyMemberFramePool:EnumerateActive() do
		memberFrame:UpdateMember();
	end

	self:Layout();
end

function RayPartyFrameMixin:UpdatePartyMemberBackground()
	if not self.Background then
		return;
	end

	if not ShouldShowPartyFrames() or not EditModeManagerFrame:ShouldShowPartyFrameBackground() then
		self.Background:Hide();
		return;
	end

	local numMembers = EditModeManagerFrame:ArePartyFramesForcedShown() and MAX_PARTY_MEMBERS or GetNumSubgroupMembers();
	if numMembers > 0 then
		for memberFrame in self.PartyMemberFramePool:EnumerateActive() do 
			if memberFrame.layoutIndex == numMembers then
				if memberFrame.PetFrame:IsShown() then
					self.Background:SetPoint("BOTTOMLEFT", memberFrame, "BOTTOMLEFT", -5, -21);
				else
					self.Background:SetPoint("BOTTOMLEFT", memberFrame, "BOTTOMLEFT", -5, -5);
				end
			end
		end
		self.Background:Show();
	else
		self.Background:Hide();
	end
end

function RayPartyFrameMixin:HidePartyFrames()
	for memberFrame in self.PartyMemberFramePool:EnumerateActive() do
		memberFrame:Hide();
	end
end

function RayPartyFrameMixin:UpdatePaddingAndLayout()
	local showPartyFrames = ShouldShowPartyFrames();
	if showPartyFrames then
		self.leftPadding = nil;
		self.rightPadding = nil;
	else
		--local useHorizontalGroups = EditModeManagerFrame:ShouldRaidFrameUseHorizontalRaidGroups(true);
		local useHorizontalGroups = true;

		if useHorizontalGroups then
			if CompactPartyFrame.borderFrame:IsShown() then
				self.leftPadding = 6;
				self.rightPadding = nil;
			else
				self.leftPadding = 2;
				self.rightPadding = 2;
			end
		else
			self.leftPadding = 2;
			self.rightPadding = 2;
		end
	end

	self:Layout();
end

function RayPartyFrameMixin:UpdatePartyFrames()
	local showPartyFrames = ShouldShowPartyFrames();
	for memberFrame in self.PartyMemberFramePool:EnumerateActive() do
		if showPartyFrames then
			memberFrame:Show();
			memberFrame:UpdateMember();
		else
			memberFrame:Hide();
		end
	end

	self:UpdatePartyMemberBackground();
	self:UpdatePaddingAndLayout();
end
