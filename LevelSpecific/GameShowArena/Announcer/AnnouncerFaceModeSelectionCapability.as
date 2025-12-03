class UGameShowArenaAnnouncerFaceModeSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);
	default CapabilityTags.Add(n"BlockedByCutscene");
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 90;
	AGameShowArenaAnnouncer Announcer;
	UGameShowArenaAnnouncerFaceComponent AnnouncerFaceComp;

	float TimeWhenNextPossibleStateChange = 0;

	bool bHasAppliedStateOverride;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
		AnnouncerFaceComp = UGameShowArenaAnnouncerFaceComponent::Get(Announcer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Announcer.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Announcer.bIsControlledByCutscene)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AnnouncerFaceComp.FaceStateOverrideQueue.Num() > 0)
		{
			bHasAppliedStateOverride = true;
			Announcer.FaceState.Apply(AnnouncerFaceComp.FaceStateOverrideQueue[0].State, n"Override", EInstigatePriority::Override);
			float OverrideDuration = AnnouncerFaceComp.FaceStateOverrideQueue[0].RemainingDuration;
			OverrideDuration -= DeltaTime;
			if (OverrideDuration <= KINDA_SMALL_NUMBER)
				AnnouncerFaceComp.FaceStateOverrideQueue.RemoveAt(0);
			else
				AnnouncerFaceComp.FaceStateOverrideQueue[0].RemainingDuration = OverrideDuration;
		}
		else if (bHasAppliedStateOverride)
		{
			Announcer.FaceState.Clear(n"Override");
			bHasAppliedStateOverride = false;
			TimeWhenNextPossibleStateChange = 0;
		}

		float Time = Time::PredictedGlobalCrumbTrailTime;
		if (Time < TimeWhenNextPossibleStateChange)
			return;

		if (Announcer.State.Get() == EGameShowArenaAnnouncerState::PermanentGlitching)
			return;

		auto StateData = Announcer.GetCurrentStateData();

		if (Announcer.RandStream.RandRange(0.0, 1.0) <= StateData.GlitchLikelihood)
		{
			Announcer.FaceState.Apply(EGameShowArenaAnnouncerFaceState::Glitching, this, EInstigatePriority::Normal);
			TimeWhenNextPossibleStateChange = Time + Announcer.RandStream.RandRange(StateData.TimeInGlitchStateRange.X, StateData.TimeInGlitchStateRange.Y);
		}
		else
		{
			Announcer.FaceState.Apply(EGameShowArenaAnnouncerFaceState::Normal, this, EInstigatePriority::Normal);
			TimeWhenNextPossibleStateChange = Time + Announcer.RandStream.RandRange(StateData.TimeInNormalStateRange.X, StateData.TimeInNormalStateRange.Y);
		}
	}
};