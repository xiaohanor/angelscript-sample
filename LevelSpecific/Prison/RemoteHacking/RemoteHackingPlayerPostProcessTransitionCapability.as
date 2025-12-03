class URemoteHackingPlayerPostProcessCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 150;

	URemoteHackingPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = URemoteHackingPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerComp.bTriggerPostProcessTransition)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= 0.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.bTriggerPostProcessTransition = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveCustomPostProcessSettings(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FPostProcessSettings PostProcessSettings;
		PostProcessSettings.bOverride_FilmGrainIntensity = true;
		PostProcessSettings.FilmGrainIntensity = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.5), FVector2D(100.0, 0.0), ActiveDuration);
		Player.AddCustomPostProcessSettings(PostProcessSettings, 1.0, this);
	}
}