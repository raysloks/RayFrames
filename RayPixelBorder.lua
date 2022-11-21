RayPixelBorderMixin={};

function RayPixelBorderMixin:OnLoad()
	local borderWidth = self.width;
	local borderOffset = self.offset;
	local borderOuter = borderWidth + borderOffset;

	self.horizTopBorder:ClearAllPoints();
	self.horizTopBorder:SetPoint("TOPLEFT", self, "TOPLEFT", -borderOffset, borderOuter);
	self.horizTopBorder:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", borderOffset, borderOffset);
	self.horizTopBorder:SetColorTexture(self.r, self.g, self.b, self.a);
	self.horizTopBorder:Show();

	self.horizBottomBorder:ClearAllPoints();
	self.horizBottomBorder:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -borderOffset, -borderOffset);
	self.horizBottomBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", borderOffset, -borderOuter);
	self.horizBottomBorder:SetColorTexture(self.r, self.g, self.b, self.a);
	self.horizBottomBorder:Show();

	self.vertLeftBorder:ClearAllPoints();
	self.vertLeftBorder:SetPoint("TOPLEFT", self, "TOPLEFT", -borderOuter, borderOuter);
	self.vertLeftBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -borderOffset, -borderOuter);
	self.vertLeftBorder:SetColorTexture(self.r, self.g, self.b, self.a);
	self.vertLeftBorder:Show();

	self.vertRightBorder:ClearAllPoints();
	self.vertRightBorder:SetPoint("TOPLEFT", self, "TOPRIGHT", borderOffset, borderOuter);
	self.vertRightBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", borderOuter, -borderOuter);
	self.vertRightBorder:SetColorTexture(self.r, self.g, self.b, self.a);
	self.vertRightBorder:Show();
end

function RayPixelBorderMixin:SetVertexColor(r, g, b, a)
	if ( r ~= nil ) then
		self.r = r;
	end
	if ( g ~= nil ) then
		self.g = g;
	end
	if ( b ~= nil ) then
		self.b = b;
	end
	if ( a ~= nil ) then
		self.a = a;
	end

	self.horizTopBorder:SetColorTexture(self.r, self.g, self.b, self.a);
	self.horizBottomBorder:SetColorTexture(self.r, self.g, self.b, self.a);
	self.vertLeftBorder:SetColorTexture(self.r, self.g, self.b, self.a);
	self.vertRightBorder:SetColorTexture(self.r, self.g, self.b, self.a);
end
