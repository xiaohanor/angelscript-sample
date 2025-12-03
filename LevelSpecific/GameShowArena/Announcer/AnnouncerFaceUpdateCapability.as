class UGameShowArenaAnnouncerFaceUpdateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 200;
	AGameShowArenaAnnouncer Announcer;
	UGameShowArenaAnnouncerFaceComponent AnnouncerFaceComp;
	bool bHasAppliedFaceOverride;
	int PreviousFace;

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
		ShowGameplayFace(DeltaTime);
	}

	void ShowGameplayFace(float DeltaTime)
	{
		if (AnnouncerFaceComp.FaceOverrideQueue.Num() > 0)
		{
			bHasAppliedFaceOverride = true;
			AnnouncerFaceComp.InstigatedFace.Apply(AnnouncerFaceComp.FaceOverrideQueue[0].FaceNr, n"Override", EInstigatePriority::Override);
			float OverrideDuration = AnnouncerFaceComp.FaceOverrideQueue[0].RemainingDuration;
			OverrideDuration -= DeltaTime;
			if (OverrideDuration <= KINDA_SMALL_NUMBER)
				AnnouncerFaceComp.FaceOverrideQueue.RemoveAt(0);
			else
				AnnouncerFaceComp.FaceOverrideQueue[0].RemainingDuration = OverrideDuration;
		}
		else if (bHasAppliedFaceOverride)
		{
			AnnouncerFaceComp.InstigatedFace.Clear(n"Override");
			bHasAppliedFaceOverride = false;
		}
	}
};