class UDesertGrappleFishPlayerDeadCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UPlayerHealthSettings HealthSettings;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthSettings = Owner.GetSettings(UPlayerHealthSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return;
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, EHazeViewPointBlendSpeed::AcceleratedNormal, Priority = EHazeViewPointPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return;
		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::AcceleratedFast);
	}
};