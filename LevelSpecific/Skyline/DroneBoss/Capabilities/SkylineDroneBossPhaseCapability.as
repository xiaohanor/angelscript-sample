struct FSkylineDroneBossPhaseActivationParams
{
	int PhaseIndex;
}

class USkylineDroneBossPhaseCapability : USkylineDroneBossChildCapability
{
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBossPhase);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineDroneBossPhaseActivationParams& Params) const
	{
		float TimeSincePhaseEnd = Time::GetGameTimeSince(Boss.PhaseEndTimestamp);
		if (TimeSincePhaseEnd < Settings.PhaseInterval)
			return false;

		auto NextPhase = Boss.GetNextPhase();
		if (NextPhase == nullptr)
			return false;

		Params.PhaseIndex = Boss.PhaseIndex + 1;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Dealt enough damage to change phase
		if (Boss.PhaseIndex < Boss.GetPhaseIndexForHealthSegment())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FSkylineDroneBossPhaseActivationParams& Params)
	{
		Boss.PhaseIndex = Params.PhaseIndex;
		Boss.CurrentPhase = Boss.Phases[Params.PhaseIndex];
		Boss.PhaseLeftAttachmentsSpawned = 0;
		Boss.PhaseRightAttachmentsSpawned = 0;
		Boss.PhaseStartTimestamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Boss.LeftAttachment.IsValid())
			Boss.LeftAttachment.Actor.DestroyAttachment();
		if (Boss.RightAttachment.IsValid())
			Boss.RightAttachment.Actor.DestroyAttachment();

		Boss.CurrentPhase = nullptr;
		Boss.PhaseEndTimestamp = Time::GameTimeSeconds;
	}
}