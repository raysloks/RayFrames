

function RayCompactRaidFrameReservation_NewManager(releaseFunc)
	return { unusedFrames = {}, reservations = {}, releaseFunc = releaseFunc };
end

function RayCompactRaidFrameReservation_GetFrame(self, key)
	assert(key);
	local frame = self.reservations[key];
	if ( not frame and #self.unusedFrames > 0 ) then
		frame = tremove(self.unusedFrames, #self.unusedFrames);
		RayCompactRaidFrameReservation_RegisterReservation(self, frame, key);
	end
	return frame;
end

function RayCompactRaidFrameReservation_RegisterReservation(self, frame, key)
	assert(key);
	assert(not self.reservations[key] or self.reservations[key] == frame);
	self.reservations[key] = frame;
end

function RayCompactRaidFrameReservation_ReleaseUnusedReservations(self)
	for key, frame in pairs(self.reservations) do
		if ( frame and not frame.inUse ) then
			if ( self.releaseFunc ) then
				self.releaseFunc(frame);
			end
			self.reservations[key] = false;
			tinsert(self.unusedFrames, frame);
		end
	end
end

function RayCompactRaidFrameReservation_GetReservation(self, key)
	assert(key);
	return self.reservations[key];
end